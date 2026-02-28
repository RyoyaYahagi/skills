#!/usr/bin/env bash
# codex-test-delegate: Codex CLI にバグチェック・テスト作成・テスト実行を委譲するヘルパースクリプト
set -euo pipefail

# ==============================================================================
# 定数
# ==============================================================================
TIMEOUT_REVIEW=300      # Phase 1 タイムアウト(秒)
TIMEOUT_TEST_GEN=300    # Phase 2 タイムアウト(秒)
TIMEOUT_TEST_RUN=600    # Phase 3 タイムアウト(秒)
MAX_RETRY=2             # テスト生成リトライ回数
REPORT_FILE=""          # レポート出力先 (空なら stdout)

# ==============================================================================
# カラー定義
# ==============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ==============================================================================
# ヘルプ
# ==============================================================================
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Codex CLI にバグチェック・テストケース作成・テスト実行を委譲するスクリプト。

Options:
  --base <branch>     ブランチ差分をレビュー (デフォルト: uncommitted)
  --commit <sha>      特定コミットをレビュー
  --review-only       Phase 1 (レビュー) のみ実行
  --test-only         Phase 2-3 (テスト作成・実行) のみ実行
  --files <files>     テスト対象ファイルを指定 (スペース区切り)
  --model <model>     Codex で使用するモデル (デフォルト: 未指定=Codex デフォルト)
  --report <path>     レポート出力先ファイルパス
  --timeout <secs>    Phase 3 タイムアウト秒数 (デフォルト: 600)
  -h, --help          このヘルプを表示

Examples:
  $(basename "$0")                       # コミット前の変更を全フェーズ実行
  $(basename "$0") --base main           # main ブランチとの差分
  $(basename "$0") --review-only         # レビューだけ
  $(basename "$0") --test-only           # テスト作成・実行だけ
  $(basename "$0") --files "src/a.ts"    # 特定ファイルだけ
EOF
  exit 0
}

# ==============================================================================
# ログ
# ==============================================================================
info()    { echo -e "${BLUE}ℹ️  $*${NC}"; }
success() { echo -e "${GREEN}✅ $*${NC}"; }
warn()    { echo -e "${YELLOW}⚠️  $*${NC}"; }
error()   { echo -e "${RED}❌ $*${NC}" >&2; }

# ==============================================================================
# 前提チェック (Phase 0)
# ==============================================================================
preflight_check() {
  info "Phase 0: 前提チェック"

  # codex コマンドの存在
  if ! command -v codex &>/dev/null; then
    error "codex CLI が見つかりません"
    error "インストール: npm install -g @openai/codex"
    exit 1
  fi

  # Git リポジトリ内か
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    error "Git リポジトリ内で実行してください"
    exit 1
  fi

  PROJECT_ROOT=$(git rev-parse --show-toplevel)
  info "プロジェクトルート: $PROJECT_ROOT"

  success "前提チェック完了"
}

# ==============================================================================
# Phase 1: バグチェック & コードレビュー
# ==============================================================================
run_review() {
  info "Phase 1: バグチェック & コードレビュー"

  local review_args=()
  local review_prompt="以下の観点でコードレビューを行い、日本語で報告してください:
1. バグ・ロジックエラー（致命的なものを最優先）
2. エッジケースの未処理
3. パフォーマンス問題
4. セキュリティリスク
5. 命名・可読性の改善点

各問題には重大度（🔴 Critical / 🟠 High / 🟡 Medium / 🔵 Low）を付与すること。
問題がなければ「問題なし」と報告すること。"

  if [[ -n "${BASE_BRANCH:-}" ]]; then
    review_args+=(--base "$BASE_BRANCH")
  elif [[ -n "${REVIEW_COMMIT:-}" ]]; then
    review_args+=(--commit "$REVIEW_COMMIT")
  else
    review_args+=(--uncommitted)
  fi

  if [[ -n "${MODEL:-}" ]]; then
    review_args+=(-m "$MODEL")
  fi

  local output_file
  output_file=$(mktemp /tmp/codex-review-XXXXXX.txt)

  info "実行: codex review ${review_args[*]} ..."

  if timeout "$TIMEOUT_REVIEW" codex review "${review_args[@]}" "$review_prompt" > "$output_file" 2>&1; then
    success "レビュー完了"
  else
    local exit_code=$?
    if [[ $exit_code -eq 124 ]]; then
      warn "レビューがタイムアウトしました (${TIMEOUT_REVIEW}秒)"
    else
      warn "レビューが非ゼロ終了しました (exit=$exit_code)"
    fi
  fi

  REVIEW_OUTPUT=$(cat "$output_file")
  rm -f "$output_file"

  echo ""
  echo "--- レビュー結果 ---"
  echo "$REVIEW_OUTPUT"
  echo "--- レビュー結果ここまで ---"
  echo ""

  # Critical チェック
  if echo "$REVIEW_OUTPUT" | grep -qi "critical\|🔴"; then
    warn "🔴 Critical な問題が検出されました。Phase 2 に進む前に確認してください。"
    REVIEW_HAS_CRITICAL=true
  else
    REVIEW_HAS_CRITICAL=false
  fi
}

# ==============================================================================
# Phase 2: テストケース作成
# ==============================================================================
run_test_gen() {
  info "Phase 2: テストケース作成"

  # 変更ファイル一覧を取得
  local changed_files
  if [[ -n "${TARGET_FILES:-}" ]]; then
    changed_files="$TARGET_FILES"
  elif [[ -n "${BASE_BRANCH:-}" ]]; then
    changed_files=$(git diff --name-only "$BASE_BRANCH" 2>/dev/null || echo "")
  else
    changed_files=$(git diff --name-only HEAD 2>/dev/null || git diff --name-only --cached 2>/dev/null || echo "")
  fi

  if [[ -z "$changed_files" ]]; then
    warn "変更ファイルが見つかりません。テストケース作成をスキップします。"
    return 1
  fi

  info "変更ファイル:"
  echo "$changed_files" | sed 's/^/  - /'

  local exec_args=(exec --full-auto -C "$PROJECT_ROOT")
  if [[ -n "${MODEL:-}" ]]; then
    exec_args+=(-m "$MODEL")
  fi

  local gen_prompt="以下のファイルに対するユニットテストを作成してください。

変更ファイル:
$changed_files

要件:
- プロジェクトで使用中のテストフレームワークに合わせること（既存テストがあればそれに倣う）
- 正常系・異常系・境界値のテストケースを含めること
- テストファイルはプロジェクトの慣習に従った場所に配置すること
- 各テストケースには日本語でテスト意図をコメントすること
- 既存テストがある場合は壊さないこと

テストファイルを作成したら、作成したファイルパスを報告してください。"

  local output_file
  output_file=$(mktemp /tmp/codex-testgen-XXXXXX.txt)
  local attempt=0

  while [[ $attempt -lt $MAX_RETRY ]]; do
    attempt=$((attempt + 1))
    info "テスト生成 試行 $attempt/$MAX_RETRY ..."

    if timeout "$TIMEOUT_TEST_GEN" codex "${exec_args[@]}" "$gen_prompt" > "$output_file" 2>&1; then
      success "テスト生成完了 (試行 $attempt)"
      break
    else
      local exit_code=$?
      if [[ $exit_code -eq 124 ]]; then
        warn "テスト生成がタイムアウトしました (${TIMEOUT_TEST_GEN}秒)"
      fi
      if [[ $attempt -lt $MAX_RETRY ]]; then
        warn "リトライします..."
      fi
    fi
  done

  TEST_GEN_OUTPUT=$(cat "$output_file")
  rm -f "$output_file"

  echo ""
  echo "--- テスト生成結果 ---"
  echo "$TEST_GEN_OUTPUT"
  echo "--- テスト生成結果ここまで ---"
  echo ""
}

# ==============================================================================
# Phase 3: テスト実行 & 修正ループ
# ==============================================================================
run_test_exec() {
  info "Phase 3: テスト実行 & 修正ループ"

  local exec_args=(exec --full-auto -C "$PROJECT_ROOT")
  if [[ -n "${MODEL:-}" ]]; then
    exec_args+=(-m "$MODEL")
  fi

  local run_prompt="テストを実行してください。

手順:
1. プロジェクトのテストコマンドを特定する（package.json, Makefile, pytest.ini, build.gradle, Xcode プロジェクト等を確認）
2. テストを実行する
3. 失敗したテストがあれば、テストコード OR 実装コードを修正する
   - テストの期待値が間違っている場合 → テストを修正
   - 実装にバグがある場合 → 実装を修正
4. 全テストがPASSするまで繰り返す（最大5回）
5. 最終的なテスト結果を以下のフォーマットで報告する

報告フォーマット:
- 実行したテストコマンド
- テスト結果サマリ（PASS数 / FAIL数 / SKIP数）
- 修正した箇所の一覧（修正した場合）
- 全テストPASSしたかどうか"

  local output_file
  output_file=$(mktemp /tmp/codex-testrun-XXXXXX.txt)

  info "テスト実行中 (最大 ${TIMEOUT_TEST_RUN}秒) ..."

  if timeout "$TIMEOUT_TEST_RUN" codex "${exec_args[@]}" "$run_prompt" > "$output_file" 2>&1; then
    success "テスト実行完了"
  else
    local exit_code=$?
    if [[ $exit_code -eq 124 ]]; then
      warn "テスト実行がタイムアウトしました (${TIMEOUT_TEST_RUN}秒)"
    else
      warn "テスト実行が非ゼロ終了しました (exit=$exit_code)"
    fi
  fi

  TEST_RUN_OUTPUT=$(cat "$output_file")
  rm -f "$output_file"

  echo ""
  echo "--- テスト実行結果 ---"
  echo "$TEST_RUN_OUTPUT"
  echo "--- テスト実行結果ここまで ---"
  echo ""
}

# ==============================================================================
# Phase 4: レポート生成
# ==============================================================================
generate_report() {
  info "Phase 4: レポート生成"

  local project_name
  project_name=$(basename "$PROJECT_ROOT")
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  local report="# 🧪 Codex テスト委譲レポート

## 実行概要
- **対象プロジェクト**: $project_name
- **実行日時**: $timestamp
- **プロジェクトルート**: $PROJECT_ROOT
"

  if [[ "${RUN_REVIEW:-true}" == "true" ]]; then
    report+="
## Phase 1: コードレビュー結果
\`\`\`
${REVIEW_OUTPUT:-実行されませんでした}
\`\`\`
"
  fi

  if [[ "${RUN_TEST:-true}" == "true" ]]; then
    report+="
## Phase 2: テストケース作成
\`\`\`
${TEST_GEN_OUTPUT:-実行されませんでした}
\`\`\`

## Phase 3: テスト実行結果
\`\`\`
${TEST_RUN_OUTPUT:-実行されませんでした}
\`\`\`
"
  fi

  report+="
## Codex による変更差分
\`\`\`
$(cd "$PROJECT_ROOT" && git diff --stat 2>/dev/null || echo "差分なし")
\`\`\`

## 次のアクション
- [ ] レビュー指摘の対応
- [ ] Codex が修正したコードの差分確認
- [ ] テストのコミット
"

  if [[ -n "$REPORT_FILE" ]]; then
    echo "$report" > "$REPORT_FILE"
    success "レポートを $REPORT_FILE に保存しました"
  else
    echo ""
    echo "$report"
  fi
}

# ==============================================================================
# メイン
# ==============================================================================
main() {
  # デフォルト値
  BASE_BRANCH=""
  REVIEW_COMMIT=""
  TARGET_FILES=""
  MODEL=""
  RUN_REVIEW="true"
  RUN_TEST="true"
  REVIEW_OUTPUT=""
  TEST_GEN_OUTPUT=""
  TEST_RUN_OUTPUT=""
  REVIEW_HAS_CRITICAL=false

  # 引数パース
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --base)       BASE_BRANCH="$2"; shift 2 ;;
      --commit)     REVIEW_COMMIT="$2"; shift 2 ;;
      --review-only) RUN_TEST="false"; shift ;;
      --test-only)  RUN_REVIEW="false"; shift ;;
      --files)      TARGET_FILES="$2"; shift 2 ;;
      --model)      MODEL="$2"; shift 2 ;;
      --report)     REPORT_FILE="$2"; shift 2 ;;
      --timeout)    TIMEOUT_TEST_RUN="$2"; shift 2 ;;
      -h|--help)    usage ;;
      *)            error "不明なオプション: $1"; usage ;;
    esac
  done

  echo ""
  echo "======================================"
  echo "  🧪 Codex テスト委譲スクリプト"
  echo "======================================"
  echo ""

  # Phase 0
  preflight_check

  # Phase 1
  if [[ "$RUN_REVIEW" == "true" ]]; then
    run_review
    if [[ "$REVIEW_HAS_CRITICAL" == "true" && "$RUN_TEST" == "true" ]]; then
      warn "Critical な問題がありますが、テストフェーズも続行します。"
    fi
  fi

  # Phase 2-3
  if [[ "$RUN_TEST" == "true" ]]; then
    run_test_gen
    run_test_exec
  fi

  # Phase 4
  generate_report

  echo ""
  success "全フェーズ完了"
}

main "$@"
