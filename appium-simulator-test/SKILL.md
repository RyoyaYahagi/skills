---
name: appium-simulator-test
description: "iOS/Androidシミュレーター・エミュレーターでのAppium実操作テスト。実装差分から検証対象機能を抽出し、シナリオ作成→実操作→結果検証を全件PASSまで実行する。シミュレーターテスト、Appium、e2eテスト等のキーワードで使用。加えてiOSアプリ実装タスク完了時の必須検証として自動適用する。"
---

# Appium Simulator Test

## Goal

Appium MCP を使って、実装した機能を「画面表示確認だけでなく実操作で」検証し、
実装差分に対応するシナリオが全て PASS するまで確認する。

## Auto-use Policy

- iOS 実装タスク完了時（`*.xcodeproj` / `*.xcworkspace` がある場合）は、このスキルを必ず実行する。
- 実装差分に対応する実操作検証が未実施、または FAIL が残る場合は、完了報告しない。
- 結果は `PASS/FAIL` だけでなく、失敗ステップと再現条件を必ず記録する。

## Workflow

1. **Default Configuration (iOS)**
   - Platform: iOS
   - Device: iPhone 17（不可なら最新 iPhone）
   - OS: 利用可能な最新
   - 可能な限り自動で進め、解決不能時のみユーザー確認

2. **Automatic App Path Discovery**
   - `.app` を以下順で探索:
     1. プロジェクトの `build/` / `DerivedData`
     2. `/Users/yappa/Library/Developer/Xcode/DerivedData`
   - 1件なら採用、複数なら最新更新を採用
   - 見つからない場合のみユーザーにパス確認

3. **Verify appium-mcp Connection**
   - appium-mcp 接続状態を確認
   - 未接続時: `npx appium-mcp@latest` を案内
   - Capabilities: `/Users/yappa/.appium-mcp/capabilities.json`

4. **Simulator Check & Capability Update**
   - `xcrun simctl list devices available` で対象端末確認
   - `scripts/update_capabilities.py` で以下を更新:
     - `platformName`: `iOS`
     - `deviceName`: `iPhone 17`（または代替）
     - `platformVersion`: 最新
     - `app`: 自動解決パス
     - `automationName`: `XCUITest`
   - 通知ダイアログ等の中断を避けるため `-automation-mode` を利用

5. **差分機能の抽出（必須）**
   - ユーザー要求・変更ファイル・実装内容から「今回実装した機能」を列挙する
   - 機能ごとに、以下を含む検証観点を作る
     - 実操作ステップ（tap/input/select/drag など）
     - 期待結果（UI状態・データ反映・ステータス文言）
     - 判定方法（どの locator / 文言で PASS 判定するか）

6. **シナリオ作成（実装差分ベース）**
   - 実装した全機能を最低1ケース以上でカバーする
   - 「押せた」だけのケースは不可。必ず結果検証を含める
   - 既定の最低確認（ベースライン）:
     1. タスク追加
     2. 完了切り替え
     3. タスク編集保存
     4. 複数選択で移動または削除
     5. 設定保存

7. **Execute via appium-mcp (Real Interaction)**
   - シナリオを順に実操作で実行
   - 各ステップで結果確認を実施し、`PASS/FAIL` を記録
   - locator が不安定な場合は page source と screenshot を併用して判定

8. **Failure Handling / Retry**
   - 一時的失敗（Stale, タイミングずれ等）は最大3回まで再試行
   - 恒常失敗は以下を記録:
     - 失敗シナリオ名
     - 失敗ステップ
     - 使用 locator
     - 期待値と実測値
     - 再現手順
   - 修正後は「失敗ケースのみ」ではなく、今回の全シナリオを再実行して回帰確認

9. **Completion Criteria**
   - 実装差分に紐づくシナリオが全件 PASS
   - FAIL 0 件
   - 未実施項目 0 件

## Report Format

- 対象機能一覧（差分から抽出）
- シナリオ一覧（機能との対応）
- 実行結果（PASS/FAIL）
- FAIL があれば詳細（失敗ステップ・原因・再現手順）
- 最終判定（全PASSで完了）

## Notes

- Silent by default: 自動解決できる項目は確認質問しない
- ただし以下は必ず確認/エスカレーション:
  - `.app` パス不明
  - 利用端末なし
  - 人間判断が必要な仕様差分

## 他スキルとの連携

- `implementation-rules`: 実装完了条件として本スキルの全PASSを要求
- `ios-development`: 実装意図と検証観点の対応付け
- `ios-cicd-pipeline`: CIでのAppium実操作検証拡張
