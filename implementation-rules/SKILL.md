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

## Git keyword handling
- If the request includes commit/push/PR/merge/deploy keywords, invoke `$git-ops` and follow its policy before executing any git operations.

## iOS Simulator Verification (Global)
- For iOS app implementation tasks (detectable by `*.xcodeproj` or `*.xcworkspace` in the repo), ALWAYS invoke `$appium-simulator-test` after successful build and before commit/report.
- Completion condition is NOT a smoke pass. 実装差分に紐づく機能を実操作で全件検証し、全シナリオ PASS を必須とする。

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

## Output language
- Respond in Japanese unless the user explicitly asks otherwise.
