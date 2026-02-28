---
name: codex-test-delegate
description: Codex CLI以外のAI（Gemini, Claude等）で実装作業中、テストフェーズに入った際にCodex CLIへバグチェック・テストケース作成・テスト実行を委譲するスキル。テスト完了まで自動で回し、結果をレポートする。トリガー：「テストして」「テスト作成」「バグチェック」「Codexでテスト」「テストケース作成」「テスト実行」「codex test」「品質チェック」。実装完了後のテストフェーズで自動適用を推奨。
---

# Codex Test Delegate

Codex CLI 以外のAIで実装した変更を、Codex CLI に委譲してバグチェック・テストケース作成・テスト実行を行うスキル。

## 前提条件

- `codex` コマンドがインストール済み（`npm install -g @openai/codex`）
- `codex login` で認証済み
- Git リポジトリ内で実行すること

## ワークフロー

```
Phase 1: バグチェック & コードレビュー
    ↓ 問題があれば報告、重大なら中断
Phase 2: テストケース作成
    ↓ テストファイル生成を確認
Phase 3: テスト実行 & 修正ループ
    ↓ 全件PASSまで自動修正
Phase 4: 結果レポート
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

## Phase 1: バグチェック & コードレビュー

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
```

### 結果の処理

- レビュー結果の出力を取得する
- 🔴 Critical が含まれる場合: **ユーザーに即報告し、修正を提案**
- 🟠 High 以下のみ: レポートに記録し、Phase 2 へ進む

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

## 次のアクション
- [ ] レビュー指摘の対応
- [ ] テストのコミット
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

# レビューのみ（Phase 1 だけ実行）
bash <skill-path>/scripts/run_codex_test.sh --review-only

# テストのみ（Phase 2-3 だけ実行）
bash <skill-path>/scripts/run_codex_test.sh --test-only

# 特定ファイルだけテスト
bash <skill-path>/scripts/run_codex_test.sh --files "src/foo.ts src/bar.ts"
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
