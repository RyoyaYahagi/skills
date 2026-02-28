---
name: codex-test-delegate
description: Codex CLI以外のAI（Gemini, Claude等）で実装作業中、テストフェーズに入った際にCodex CLIへバグチェック・テストケース作成・テスト実行を委譲するスキル。PRレビュー・品質チェック後に問題点をGitHub Issueとして自動登録する機能も備える。テスト完了まで自動で回し、結果をレポートする。トリガー：「テストして」「テスト作成」「バグチェック」「Codexでテスト」「テストケース作成」「テスト実行」「codex test」「品質チェック」「PRレビュー」「PRをレビュー」「issueを作成」「Issueに起票」「Githubに登録」。実装完了後のテストフェーズで自動適用を推奨。
---

# Codex Test Delegate

Codex CLI 以外のAIで実装した変更を、Codex CLI に委譲してバグチェック・テストケース作成・テスト実行を行うスキル。

## 前提条件

- `codex` コマンドがインストール済み（`npm install -g @openai/codex`）
- `codex login` で認証済み
- Git リポジトリ内で実行すること
- **GitHub Issue 作成機能を使う場合**: `gh` CLI のインストールと認証が必要（`gh auth login`）

## ワークフロー

```
Phase 1a: コードレビュー（差分 or コミット前）
    ↓
Phase 1b: PR レビュー ※ --pr オプション時
    ↓ 問題はレポートに記録（即時推告なし）
Phase 2: テストケース作成
    ↓ テストファイル生成を確認
Phase 3: テスト実行 & 修正ループ
    ↓ 全件PASSまで自動修正
Phase 4: 結果レポート
    ↓
Phase 5: GitHub Issue 自動作成 ※ バグ修正失敗時のみ
```

---

## Phase 0: 前提チェック

スキル開始時に以下を必ずチェックする。失敗したら即中断してユーザーに報告。

```bash
# Codex CLI があるか
which codex || { echo "❌ codex CLIが見つかりません。npm install -g @openai/codex でインストールしてください"; exit 1; }

# Git リポジトリ内か
git rev-parse --is-inside-work-tree || { echo "❌ Gitリポジトリ内で実行してください"; exit 1; }

# プロジェクトルートを特定
PROJECT_ROOT=$(git rev-parse --show-toplevel)
```

---

## Phase 1a: バグチェック & コードレビュー

Codex CLI の `review` サブコマンドで変更差分をレビューさせる。

### 実行コマンド

状況に応じてオプションを選択：

| 状況                           | コマンド                                                                                                                          |
| ------------------------------ | --------------------------------------------------------------------------------------------------------------------------------- |
| コミット前の変更（デフォルト） | `codex review --uncommitted`                                                                                                      |
| ブランチ差分をレビュー         | `codex review --base main`                                                                                                        |
| 特定コミットをレビュー         | `codex review --commit <SHA>`                                                                                                     |
| カスタム指示付き               | `codex review --uncommitted "日本語でレビューして。バグ、ロジックエラー、パフォーマンス問題、セキュリティ問題を重点的にチェック"` |

### 推奨プロンプト

```
以下の観点でコードレビューを行い、日本語で報告してください:
1. バグ・ロジックエラー（致命的なものを最優先）
2. エッジケースの未処理
3. パフォーマンス問題
4. セキュリティリスク
5. 命名・可読性の改善点

各問題には重大度（🔴 Critical / 🟠 High / 🟡 Medium / 🔵 Low）を付与すること。
問題がなければ「問題なし」と報告。
```

### 結果の処理

- レビュー結果は全てレポート（Phase 4）に記録する
- 重大度別の件数を集計し、レポートのサマリ表に追記する
- Phase 2 のテスト生成へそのまま進む（即時中断・ユーザー推告なし）

---

## Phase 1b: PR レビュー（`--pr` オプション時）

`--pr <PR番号>` が指定された場合に実行。Codex が PR の差分全体をレビューし、品質チェックを行う。

### 実行手順

```bash
# PR の差分を取得して Codex でレビュー
PR_NUM="<PR番号>"
BASE_BRANCH=$(gh pr view "$PR_NUM" --json baseRefName -q .baseRefName)

codex review --base "$BASE_BRANCH" \
  "このPR（#$PR_NUM）を以下の観点でレビューしてください:
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

問題がなければ 'LGTM' と報告。"
```

### PR 情報の取得

```bash
# PR のタイトル・本文・レビュアーを参照情報として取得
gh pr view "$PR_NUM" --json title,body,author,labels,additions,deletions
```

### 結果の処理

- レビュー結果は全てレポートに記録する（即時ユーザー推告なし）
- PR にコメントとして追記したい場合: `gh pr comment "$PR_NUM" --body "<レビュー結果>"`

---

## Phase 2: テストケース作成

`codex exec` で変更ファイルに対するテストケースを自動生成させる。

### 実行手順

1. 変更ファイルの一覧を取得:
```bash
CHANGED_FILES=$(git diff --name-only HEAD 2>/dev/null || git diff --name-only --cached)
echo "変更ファイル: $CHANGED_FILES"
```

2. Codex にテストケース作成を指示:
```bash
codex exec --full-auto -C "$PROJECT_ROOT" \
  "以下のファイルに対するユニットテストを作成してください。

変更ファイル:
$CHANGED_FILES

要件:
- プロジェクトで使用中のテストフレームワークに合わせること（既存テストがあればそれに倣う）
- 正常系・異常系・境界値のテストケースを含めること
- テストファイルはプロジェクトの慣習に従った場所に配置すること
- 各テストケースには日本語でテスト意図をコメントすること
- 既存テストがある場合は壊さないこと

テストファイルを作成したら、ファイルパスを報告してください。"
```

### 結果の確認

- テストファイルが生成されたか `git status` で確認
- 生成されなかった場合は再試行（最大2回）

---

## Phase 3: テスト実行 & 修正ループ

生成されたテストを実行し、失敗があればCodexに修正させる。

### 実行手順

```bash
codex exec --full-auto -C "$PROJECT_ROOT" \
  "テストを実行してください。

手順:
1. プロジェクトのテストコマンドを特定する（package.json, Makefile, pytest.ini, build.gradle 等を確認）
2. テストを実行する
3. 失敗したテストがあれば、テストコード OR 実装コードを修正する
   - テストの期待値が間違っている場合 → テストを修正
   - 実装にバグがある場合 → 実装を修正
4. 全テストがPASSするまで繰り返す（最大5回）
5. 最終的なテスト結果を報告する

報告フォーマット:
- 実行したテストコマンド
- テスト結果サマリ（PASS数 / FAIL数 / SKIP数）
- 修正した箇所の一覧（修正した場合）
- 全テストPASSしたかどうか"
```

### タイムアウト

- Phase 3 は最大 **10分** でタイムアウト
- タイムアウトした場合はその時点の状態をユーザーに報告

---

## Phase 4: 結果レポート

全フェーズの結果を統合してレポートを作成する。

### レポートフォーマット

```markdown
# 🧪 Codex テスト委譲レポート

## 実行概要
- **対象プロジェクト**: <プロジェクト名>
- **実行日時**: <タイムスタンプ>
- **変更ファイル数**: <N>件

## Phase 1: コードレビュー結果
| 重大度     | 件数 | 主な指摘 |
| ---------- | ---- | -------- |
| 🔴 Critical | 0    | -        |
| 🟠 High     | 1    | xxx      |
| 🟡 Medium   | 2    | yyy, zzz |

## Phase 2: テストケース作成
- **生成ファイル**: <ファイルパス一覧>
- **テストケース数**: <N>件

## Phase 3: テスト実行結果
- **最終結果**: ✅ 全件PASS / ❌ 一部FAIL
- **PASS**: <N>件 / **FAIL**: <N>件 / **SKIP**: <N>件
- **修正箇所**: <あれば列挙>
- **実行回数**: <N>回（修正ループ含む）

## Phase 5: GitHub Issue 自動作成

**バグ修正が失敗した場合のみ** Issue を登録する。Phase 3 のテスト実行で失敗数が残った場合や、タイムアウトした場合にトリガーされる。

> ただレビューで問題が見つかっただけでは Issue を作成しない。「Codex が修正を試みたが失敗した」問題だけを登録する。

- **作成 Issue 数**: <N>件
- **Issue URL 一覧**: <URL>

## 次のアクション
- [ ] レビュー指摘の対応
- [ ] Codex が修正したコードの差分確認
- [ ] テストのコミット
- [ ] 作成 Issue の優先対応
```

---

## コマンドリファレンス

### ヘルパースクリプト

`scripts/run_codex_test.sh` を使えば一括で全フェーズを実行できる:

```bash
# 基本的な使い方（コミット前の変更をテスト）
bash <skill-path>/scripts/run_codex_test.sh

# ブランチ差分をテスト
bash <skill-path>/scripts/run_codex_test.sh --base main

# レビューのみ（Phase 1a だけ実行）
bash <skill-path>/scripts/run_codex_test.sh --review-only

# テストのみ（Phase 2-3 だけ実行）
bash <skill-path>/scripts/run_codex_test.sh --test-only

# 特定ファイルだけテスト
bash <skill-path>/scripts/run_codex_test.sh --files "src/foo.ts src/bar.ts"

# PR をレビュー（テストは実行しない）
bash <skill-path>/scripts/run_codex_test.sh --pr 42 --review-only

# PR レビュー + テスト（全フェーズ）
bash <skill-path>/scripts/run_codex_test.sh --pr 42 --base main

# バグ修正失敗時のみ GitHub Issue 自動登録
bash <skill-path>/scripts/run_codex_test.sh --create-issues

# Medium 以上の修正失敗問題も Issue 化
bash <skill-path>/scripts/run_codex_test.sh --create-issues --create-medium
```

---

## 他スキルとの連携

- **implementation-rules**: 実装完了後、テストフェーズとして本スキルを呼び出す
- **code-review**: Codex のレビュー結果を補完する形で利用
- **git-ops**: テスト完了後のコミット
- **appium-simulator-test**: iOS アプリの場合、UIテストは appium-simulator-test を併用

## 注意事項

- Codex CLI は OpenAI API を使うため、**API利用料が発生する**
- `--full-auto` モードはサンドボックス内で実行されるが、ワークスペースへの書き込みは有効
- 大規模なプロジェクトではテスト生成に時間がかかる場合がある
- Codex が生成・修正したコードは必ず差分を確認してからコミットすること
