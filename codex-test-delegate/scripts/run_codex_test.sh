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
PR レビュー・品質チェック後には GitHub Issue を自動作成する機能も備える。

Options:
  --base <branch>     ブランチ差分をレビュー (デフォルト: uncommitted)
  --commit <sha>      特定コミットをレビュー
  --pr <number>       PR 番号を指定して PR レビューを実行 (Phase 1b)
  --review-only       Phase 1a のレビューのみ実行
  --test-only         Phase 2-3 (テスト作成・実行) のみ実行
  --files <files>     テスト対象ファイルを指定 (スペース区切り)
  --model <model>     Codex で使用するモデル (デフォルト: 未指定=Codex デフォルト)
  --report <path>     レポート出力先ファイルパス
  --timeout <secs>    Phase 3 タイムアウト秒数 (デフォルト: 600)
  --create-issues     Critical/High な問題を GitHub Issue に自動登録
  --create-medium     Medium な問題も GitHub Issue に登録 (--create-issues と併用)
  -h, --help          このヘルプを表示

Examples:
  $(basename "$0")                          # コミット前の変更を全フェーズ実行
  $(basename "$0") --base main              # main ブランチとの差分
  $(basename "$0") --pr 42                  # PR #42 をレビューして Issue 化
  $(basename "$0") --pr 42 --create-issues  # PR レビュー + 自動 Issue 作成
  $(basename "$0") --review-only            # レビューだけ
  $(basename "$0") --test-only              # テスト作成・実行だけ
  $(basename "$0") --files "src/a.ts"       # 特定ファイルだけ
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
# Phase 1a: バグチェック & コードレビュー
# ==============================================================================
run_review() {
  info "Phase 1a: バグチェック & コードレビュー"

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
    warn "🔴 Critical な問題が検出されました。"
    REVIEW_HAS_CRITICAL=true
  else
    REVIEW_HAS_CRITICAL=false
  fi
}

# ==============================================================================
# Phase 1b: PR レビュー
# ==============================================================================
run_pr_review() {
  local pr_num="$1"
  info "Phase 1b: PR #$pr_num レビュー"

  # gh CLI チェック
  if ! command -v gh &>/dev/null; then
    error "gh CLI が見つかりません。brew install gh でインストールしてください"
    return 1
  fi

  # ベースブランチを取得
  local base_branch
  base_branch=$(gh pr view "$pr_num" --json baseRefName -q .baseRefName 2>/dev/null)
  if [[ -z "$base_branch" ]]; then
    error "PR #$pr_num の情報を取得できませんでした"
    return 1
  fi

  info "PR #$pr_num のベースブランチ: $base_branch"

  # PR 情報を取得して表示
  local pr_info
  pr_info=$(gh pr view "$pr_num" --json title,author,additions,deletions,labels 2>/dev/null)
  echo "PR 情報: $pr_info"

  local review_args=(--base "$base_branch")
  if [[ -n "${MODEL:-}" ]]; then
    review_args+=(-m "$MODEL")
  fi

  local pr_review_prompt="このPR（#$pr_num）を以下の観点でレビューしてください:
1. バグ・ロジックエラー
2. セキュリティリスク（SQL injection, XSS, auth bypass 等）
3. パフォーマンス問題
4. テスト網羅性（ハッピーパスのみでないか）
5. 破壊的変更（APIの後方互換性など）
6. コードスタイル・可読性

各問題には以下を含めること:
- 重大度: 🔴 Critical / 🟠 High / 🟡 Medium / 🔵 Low
- 該当ファイル・行番号
- 具体的な修正提案

問題がなければ 'LGTM' と報告してください。"

  local output_file
  output_file=$(mktemp /tmp/codex-pr-review-XXXXXX.txt)

  info "PR #$pr_num をレビュー中 ..."

  if timeout "$TIMEOUT_REVIEW" codex review "${review_args[@]}" "$pr_review_prompt" > "$output_file" 2>&1; then
    success "PR レビュー完了"
  else
    local exit_code=$?
    [[ $exit_code -eq 124 ]] && warn "PR レビューがタイムアウトしました" || warn "PR レビューが非ゼロ終了 (exit=$exit_code)"
  fi

  PR_REVIEW_OUTPUT=$(cat "$output_file")
  rm -f "$output_file"

  echo ""
  echo "--- PR レビュー結果 ---"
  echo "$PR_REVIEW_OUTPUT"
  echo "--- PR レビュー結果ここまで ---"
  echo ""

  # REVIEW_OUTPUT に統合（Issue 作成判定に使用）
  REVIEW_OUTPUT="$REVIEW_OUTPUT

[PR #$pr_num レビュー]
$PR_REVIEW_OUTPUT"

  if echo "$PR_REVIEW_OUTPUT" | grep -qi "critical\|🔴"; then
    REVIEW_HAS_CRITICAL=true
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
# Phase 5: GitHub Issue 自動作成
# ==============================================================================
create_github_issues() {
  local review_text="$1"
  local include_medium="${2:-false}"

  info "Phase 5: GitHub Issue 自動作成"
  ISSUE_URLS=""

  if ! command -v gh &>/dev/null; then
    error "gh CLI が見つかりません。brew install gh でインストールしてください"
    return 1
  fi

  if ! gh auth status &>/dev/null; then
    error "gh の認証が完了していません。gh auth login を実行してください"
    return 1
  fi

  local repo
  repo=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)
  if [[ -z "$repo" ]]; then
    error "現在のディレクトリに GitHub リポジトリが見つかりません"
    return 1
  fi
  info "対象リポジトリ: $repo"

  # 必要なラベルを事前作成
  gh label create "codex-detected" --color "0075ca" --description "Codex CLI による自動検出" 2>/dev/null || true
  gh label create "critical"       --color "d73a4a" --description "Critical severity"         2>/dev/null || true
  gh label create "high-priority"  --color "e4e669" --description "High severity"             2>/dev/null || true

  local issue_count=0
  local current_title=""
  local current_body=""
  local current_labels=""

  _flush_issue() {
    local t="$1" b="$2" l="$3"
    [[ -z "$t" ]] && return 0

    # 重複チェック
    local existing
    existing=$(gh issue list --label "codex-detected" --search "$t in:title" --json number -q length 2>/dev/null || echo "0")
    if [[ "$existing" =~ ^[1-9] ]]; then
      warn "Issue「$t」はすでに存在するためスキップします"
      return 0
    fi

    local full_body
    full_body="$(echo -e "$b")\n\n---\n*この Issue は Codex CLI による自動レビューで検出されました*"

    local label_args=()
    IFS=',' read -ra la <<< "$l"
    for lbl in "${la[@]}"; do
      label_args+=(--label "$lbl")
    done

    local url
    url=$(gh issue create --title "$t" --body "$(echo -e "$full_body")" "${label_args[@]}" 2>/dev/null || true)
    if [[ -n "$url" ]]; then
      success "Issue 作成: $url"
      ISSUE_URLS+="  $url\n"
      issue_count=$((issue_count + 1))
    else
      warn "Issue「$t」の作成に失敗しました"
    fi
  }

  while IFS= read -r line; do
    if echo "$line" | grep -qE "Critical|🔴"; then
      _flush_issue "$current_title" "$current_body" "$current_labels"
      current_title="[Critical] $(echo "$line" | sed 's/.*Critical[^:]*:[[:space:]]*//' | head -c 80)"
      current_body="## 検出した問題\n$line\n"
      current_labels="bug,critical,codex-detected"

    elif echo "$line" | grep -qE "High|🟠"; then
      _flush_issue "$current_title" "$current_body" "$current_labels"
      current_title="[High] $(echo "$line" | sed 's/.*High[^:]*:[[:space:]]*//' | head -c 80)"
      current_body="## 検出した問題\n$line\n"
      current_labels="bug,high-priority,codex-detected"

    elif [[ "$include_medium" == "true" ]] && echo "$line" | grep -qE "Medium|🟡"; then
      _flush_issue "$current_title" "$current_body" "$current_labels"
      current_title="[Medium] $(echo "$line" | sed 's/.*Medium[^:]*:[[:space:]]*//' | head -c 80)"
      current_body="## 検出した問題\n$line\n"
      current_labels="enhancement,codex-detected"

    elif [[ -n "$current_title" ]]; then
      current_body+="$line\n"
    fi
  done <<< "$review_text"

  # 最後のアイテムをフラッシュ
  _flush_issue "$current_title" "$current_body" "$current_labels"

  if [[ $issue_count -eq 0 ]]; then
    success "Issue 作成は不要でした（該当する問題なし）"
  else
    success "GitHub Issue を $issue_count 件作成しました"
    echo -e "$ISSUE_URLS"
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
  PR_NUMBER=""
  RUN_REVIEW="true"
  RUN_TEST="true"
  CREATE_ISSUES="false"
  CREATE_MEDIUM="false"
  REVIEW_OUTPUT=""
  PR_REVIEW_OUTPUT=""
  TEST_GEN_OUTPUT=""
  TEST_RUN_OUTPUT=""
  REVIEW_HAS_CRITICAL=false
  ISSUE_URLS=""

  # 引数パース
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --base)          BASE_BRANCH="$2"; shift 2 ;;
      --commit)        REVIEW_COMMIT="$2"; shift 2 ;;
      --pr)            PR_NUMBER="$2"; shift 2 ;;
      --review-only)   RUN_TEST="false"; shift ;;
      --test-only)     RUN_REVIEW="false"; shift ;;
      --files)         TARGET_FILES="$2"; shift 2 ;;
      --model)         MODEL="$2"; shift 2 ;;
      --report)        REPORT_FILE="$2"; shift 2 ;;
      --timeout)       TIMEOUT_TEST_RUN="$2"; shift 2 ;;
      --create-issues) CREATE_ISSUES="true"; shift ;;
      --create-medium) CREATE_MEDIUM="true"; shift ;;
      -h|--help)       usage ;;
      *)               error "不明なオプション: $1"; usage ;;
    esac
  done

  echo ""
  echo "=============================================="
  echo "  🧪 Codex テスト委譲スクリプト"
  echo "=============================================="
  echo ""

  # Phase 0
  preflight_check

  # Phase 1a: 通常レビュー
  if [[ "$RUN_REVIEW" == "true" ]]; then
    run_review
  fi

  # Phase 1b: PR レビュー
  if [[ -n "$PR_NUMBER" ]]; then
    run_pr_review "$PR_NUMBER"
  fi

  if [[ "$REVIEW_HAS_CRITICAL" == "true" && "$RUN_TEST" == "true" ]]; then
    warn "Critical な問題がありますが、テストフェーズも続行します。"
  fi

  # Phase 2-3
  if [[ "$RUN_TEST" == "true" ]]; then
    run_test_gen
    run_test_exec
  fi

  # Phase 4
  generate_report

  # Phase 5: GitHub Issue 作成
  if [[ "$CREATE_ISSUES" == "true" ]] && [[ -n "$REVIEW_OUTPUT" ]]; then
    create_github_issues "$REVIEW_OUTPUT" "$CREATE_MEDIUM"
  elif [[ "$REVIEW_HAS_CRITICAL" == "true" ]]; then
    warn "🔴 Critical な問題があります。--create-issues オプションで GitHub Issue に自動登録できます。"
  fi

  echo ""
  success "全フェーズ完了"
}

main "$@"
