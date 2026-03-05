---
name: implementation-rules
description: Global implementation workflow and output format rules. Use when asked to implement changes, fix bugs, refactor, add features, or produce diffs/tests/PR reports. Apply the standard phased workflow, minimal-diff policy, risk enumeration, test requirements, and reporting format. Also load project-specific rules from rules.md when present.
---

# Implementation Rules

## Quick start
- Find the project root.
- If `rules.md` exists, read it first and follow it as project-specific rules.
- If project rules conflict with global rules, ask for user confirmation and stop.
- Read `references/implementation-rules.md` for the mandatory phases, constraints, and output format.

## GitHub Issue-First Rule (Global)
- 作業開始時、または「次に何をするか」を判断する直前に、GitHub Issue を確認する。
- `gh` が利用可能な場合は、最低でも `gh issue list --state open --limit 20` と、着手候補Issueの `gh issue view <番号>` を確認する。
- オープンIssueがある場合は、Issue本文・受け入れ条件・ラベル・優先度に基づいて次アクションを決める。
- 既存Issueと無関係な作業に入る場合は、理由（割り込み、ブロッカー解消、緊急修正など）を短く記録してから進む。
- `gh` が使えない環境では、その旨を報告し、代替の情報源（タスクノート等）で暫定判断する。

## Git keyword handling
- If the request includes commit/push/PR/merge/deploy keywords, invoke `$git-ops` and follow its policy before executing any git operations.

## Obsidian Project Context Loop (Global)
- 実装開始前に `project-hub` を使って対象プロジェクトを判定し、`Projects/{project}/` の既存ノートを必ず読み込む。
- 読み込み対象は最低でも `_Index.md`, `tasks.md`, `progress-log.md`, `decisions.md`, `failures.md` とし、存在しない場合のみ新規作成する。
- 同日セッションの `AI-Sessions/YYYY-MM-DD-{project}.md` があれば追記モードで使用し、なければ新規作成する。
- 実装フェーズの区切り（計画確定、実装完了、テスト完了、コミット完了）ごとに、進捗をObsidianへ追記する。
- コミットを行った場合は、コミット情報（ハッシュ/要約）をセッションノートと `progress-log.md` に反映する。
- ユーザーへ最終報告する前に、今回参照・更新したノートを確認し、記録漏れがない状態で報告する。

## iOS Simulator Verification (Global)
- For iOS app implementation tasks (detectable by `*.xcodeproj` or `*.xcworkspace` in the repo), ALWAYS invoke `$appium-simulator-test` after successful build and before commit/report.
- Completion condition is NOT a smoke pass. 実装差分に紐づく機能を実操作で全件検証し、全シナリオ PASS を必須とする。

## Testing Issue Registration (Global)
- テスト中に直せなかったバグ（失敗残存・タイムアウト）がある場合は、必ず GitHub Issue を作成する。
- テスト中に「追加すべき機能」を発見した場合も、`enhancement` ラベルで GitHub Issue を作成する。
- いずれも再現情報・期待結果・現状結果を Issue 本文に含める。

## 🚨 xcodebuild 実行前の必須手順

### シミュレーター自動検出（毎回必須）

`xcodebuild` を実行する前に、**必ず以下のコマンドで利用可能な destination を確認**すること：

```bash
# 利用可能なシミュレーター一覧を取得
xcodebuild -project <project.xcodeproj> -scheme <scheme> -showdestinations 2>&1 \
  | grep "platform:iOS Simulator" | head -10
```

- 取得した結果から **最新 iPhone（Pro/Plus以外を優先）** を選択して `-destination` に指定する
- **ハードコードした `iPhone 16` 等は禁止** — 存在しない場合にビルド失敗するため
- destination が取得できない場合は `xcrun simctl list devices available` でデバイス名を確認

### DerivedData 権限エラー時の自動修復

`xcodebuild` が DerivedData への書き込み Permission denied になった場合は、
`$sandbox-escalation` スキルの自動修復ルールに従い修復してから再実行する。

## 🚨 1機能1コミット（必須・厳守）

### ⚠️ 最重要ルール
**機能実装が完了しビルド成功したら、ユーザーへの報告・確認の前に必ずコミットを実行すること。**

### 実装完了時の必須チェックリスト
機能が完了したら、以下を**この順番で**実行：

1. [ ] ビルド成功を確認
2. [ ] iOSアプリ実装時は`$appium-simulator-test`で「実装差分の全機能を実操作で検証し、全シナリオPASS」を確認
3. [ ] `git status`で変更ファイルを確認
4. [ ] `git-ops`スキルを呼び出してコミット実行
5. [ ] コミット完了を確認
6. [ ] ユーザーに報告

### 自動コミットのトリガー
以下の作業が完了しビルド成功したら、**即座に**コミット：
- 新しいView/Screen追加
- 新しいService/Repository追加
- API連携実装
- バグ修正
- リファクタリング
- 設定変更

### 禁止事項（絶対に守ること）
- ❌ コミットせずにユーザーに報告しない
- ❌ コミットせずに次の機能に着手しない
- ❌ 複数機能をまとめてコミットしない
- ❌ 未完成の機能をコミットしない（WIPコミットは別ブランチで）
- ❌ セッション終了時に未コミットの変更を残さない

### 違反時の対応
もしコミットを忘れていた場合：
1. 即座に作業を中断
2. 未コミットの変更をコミット
3. ユーザーに謝罪と報告

## Output language & Enforce Japanese (CRITICAL)
- 常に **100% 日本語 (Japanese)** で出力すること。英語で説明を行わないこと。
- Gemini 3.1 Pro等のモデルは、コードやログの英語コンテキストに引きずられやすい特性があります。これを防ぐため、出力時は常に「自分は日本語で話すアシスタントである」と再認識してください。
- 必要に応じて `$force-japanese` スキルを参照し、その絶対ルールに従うこと。
