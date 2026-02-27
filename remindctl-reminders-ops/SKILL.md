---
name: remindctl-reminders-ops
description: "Apple Reminders を remindctl で安全に運用するスキル。追加・編集・完了・削除・リスト作成/改名を標準手順化し、Mach error 4099 の発生時に再試行で回復する。『あとで/後で 〇〇』は later-holiday-reminder へ委譲する。トリガー: remindctl, Reminder, Reminders, タスク追加, タスク編集, リスト改名, due, 締切。"
---

# Remindctl Reminders Ops

## Goal

Apple Reminders の操作を `remindctl` で安定実行する。
特に `Mach error 4099` の一時失敗を、予防ルールと再試行手順で吸収する。

## Scope Boundary

- 一次責務: `remindctl` の通常運用（追加/編集/完了/削除/リスト管理、4099回復）
- `あとで/後で` 入力の休み日判定と自動スケジューリング: **`later-holiday-reminder` が一次ソース**
- 本スキルでは `あとで` ロジックを重複実装しない（仕様ドリフト防止）

## When To Use

- `remindctl` でタスクを追加したい
- 既存タスクを編集/完了/削除したい
- リストを作成/改名/削除したい
- `Mach error 4099` が断続的に出る

## Preflight

1. 権限確認: `remindctl status`
2. 未認可なら: `remindctl authorize`
3. リスト確認: `remindctl list --plain`

## Standard Workflow

1. 追加
- 基本: `remindctl add --title "Call mom" --list personal --due tomorrow`
- 時刻指定: `remindctl add --title "Call mom" --list personal --due "2026-02-24 17:30"`

2. 編集
- `remindctl edit <id> --title "New title" --due 2026-01-04`
- `id` は `show` 出力の index または ID prefix を使う

3. 完了/未完了
- 完了: `remindctl complete <id>`
- 未完了化: `remindctl edit <id> --incomplete`

4. 削除
- `remindctl delete <id>`

5. リスト操作
- 一覧: `remindctl list --plain`
- 作成: `remindctl list shoppingList --create`
- 改名: `remindctl list buy --rename shoppingList`
- 削除: `remindctl list shoppingList --delete`

## 「あとで/後で」入力フロー

入力が `あとで 〇〇` または `後で 〇〇` の場合は、**`later-holiday-reminder` に委譲**する。

1. 実行
- `node /Users/yappa/code/skills/later-holiday-reminder/scripts/later_holiday_reminder.mjs --input "あとで 〇〇" --account <mail> --apply`
- このスクリプトは既定でTerminal.app自動実行を行う（Apple Reminders権限問題の回避）。Terminal.appでは新規タブで実行される。

2. 注意
- サンドボックス環境では `gog` の keychain 参照が制限される場合がある
- その場合はサンドボックス外（escalated）実行に切り替える

3. 保守ルール
- 休み日定義・時刻・学習ロジックは `later-holiday-reminder` 側のみ更新する
- 本スキル側には同等ロジックを再実装しない

## Date/Time Rules

- 日付のみは `YYYY-MM-DD` 形式を優先
- 日時は `YYYY-MM-DD HH:mm` をダブルクォートで渡す
- 相対日付は `tomorrow` が安定
- 環境によって `tomorrow 17:30` は `Invalid date` になることがある
- 入力末尾の全角スペース（`　`）を避ける

## Mach Error 4099 Prevention

完全防止は難しいため、以下の運用で発生率を下げる。

1. `remindctl` を並列実行しない（1コマンドずつ順次実行）
2. 書き込み系（add/edit/delete/rename）前に `list` など読み取り系で接続を温める
3. 対話入力を使わない（必要に応じて `--no-input`）
4. 失敗時は同一コマンドを最大3回再試行する

## Retry Policy (Mach 4099)

`Mach error 4099` が出た場合:

1. 同一コマンドを再試行（最大3回）
2. 推奨待機時間: 0.5秒 → 1秒 → 2秒
3. 成功後は `list` / `show` で反映確認
4. 3回失敗したらユーザーにエスカレーションし、次を提案
- Reminders アプリ再起動
- `remindctl status` 再確認
- macOS ログインセッション再取得（必要時）

## Helper Script

同梱スクリプトで 4099 再試行を自動化できる。

```bash
./scripts/remindctl_retry.sh remindctl add --title "Call mom" --list personal --due tomorrow
```

## Output Format

- 実行コマンド
- 結果（成功/失敗）
- 失敗時はリトライ回数と最終エラー
- 実データ確認（`list`/`show` で確認した行）
