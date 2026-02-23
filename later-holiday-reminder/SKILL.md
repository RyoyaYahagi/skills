---
name: later-holiday-reminder
description: "ユーザーが『あとで 〇〇』や『後で 〇〇』の形式で将来タスクを入力したときに、Googleカレンダーから直近の休み日を特定し、その日にApple Remindersへ自動登録するスキル。トリガー: あとで, 後で, later, 休みの日に入れて, 休日に入れて, defer task。"
---

# Later Holiday Reminder

## Goal

「あとで」入力を受けたら、直近の休み日を自動で選び、Apple Remindersに1件登録する。
既定の追加時刻は **14:00**。

## Scope Boundary

- 一次責務: `あとで/後で 〇〇` の解釈、休み日特定、時刻決定、学習による間隔調整
- `remindctl` の一般操作（編集/完了/削除/リスト管理、4099運用）は `remindctl-reminders-ops` が一次ソース
- `あとで` ロジックは本スキルを正として管理し、他スキルへ重複実装しない

## Workflow

1. 入力を解釈する。
- 対象: `あとで 〇〇` / `後で 〇〇`
- タイトルは接頭辞を除去して抽出する。
- 語尾の `をやる` `をする` `する` `やる` は必要に応じて除去する。

2. 事前確認を行う。
- `gog` と `remindctl` が使えることを確認する。
- `gog auth add <mail> --services calendar` 済みであることを確認する。
- `remindctl status` が authorized であることを確認する。

3. 直近の休み日を特定する。
- `gog calendar events` で期間内イベントを取得する。
- 判定条件:
  - `eventType` が `outOfOffice`
  - または 件名に `休み, 休日, 有給, off, vacation` を含む
  - または `研究室` 予定が入っていない日（既定の勤務予定キーワードは `研究室`）
- 抽出日付のうち最も近い未来日を1件採用する。

4. Apple Remindersへ登録する。
- 既存重複（同一タイトル + 同一期限日）を確認し、重複時は追加しない。
- 追加時刻は既定 `14:00`。同日の既存タスクとの間隔を学習値で調整し、`YYYY-MM-DD HH:mm` で登録する。
- `Mach error 4099` は最大3回（0.5s, 1s, 2s）で自動再試行する。

## Sandbox / 実行失敗対策（再発防止）

Codex等のサンドボックス環境では次の失敗が起きやすい。

- `gog calendar ...` が `No auth for calendar ...` で失敗する  
  - 原因: `keychain` 参照がサンドボックス内で制限されることがある
  - 対策: **サンドボックス外（escalated）で実行**する
- `remindctl_retry.sh` が `mktemp ... Operation not permitted` で失敗する
  - 原因: 一時ディレクトリへの書き込み制限
  - 対策: **サンドボックス外（escalated）で実行**する
- `Mach error 4099`
  - 原因: Remindersアクセスの競合・不安定
  - 対策: `remindctl` は**必ず直列実行**し、再試行（0.5s, 1s, 2s）を使う

実運用ルール:
- `gog` / `remindctl` の検証は最初に `dry-run` で確認
- 失敗時は環境変数で回避しようとせず、まず実行権限（sandbox/escalation）を確認
- トークンを `/tmp` に書き出した場合は検証後に必ず削除

## 所要時間推定と学習

- タイトル/入力文から所要時間（分）を推定
  - 明示指定（例: `30分`, `2時間`）を優先
  - 明示がない場合はキーワードで推定（軽作業30分 / 重作業90分 / 既定60分）
- 学習プロファイル（JSON）を使って、日々の追加結果から平均間隔を更新
  - 既定保存先: `~/Library/Application Support/gogcli/later-holiday-reminder-profile.json`
  - 学習値を使って、同日内のタスク時刻を自動で間隔調整

## Script

`scripts/later_holiday_reminder.mjs` を使って実行する。

```bash
node scripts/later_holiday_reminder.mjs \
  --input "あとで レポートを書く" \
  --account you@gmail.com \
  --list Personal \
  --apply
```

補助オプション:
- `--title`: 入力文ではなくタイトルを直接指定
- `--calendar-id`: 既定は `primary`
- `--from`, `--to`: 休み検索期間（既定: 今日から120日）
- `--due-time`: 追加時刻（既定: `14:00`）
- `--work-keywords`: 仕事予定キーワード（既定: `研究室`）
- `--fixed-spacing`: 学習間隔を使わず固定間隔（分）を使用
- `--profile`: 学習プロファイルJSONパスを指定
- `--dry-run`: 追加せず計画のみ表示（既定）

## Expected Output

- 抽出タイトル
- 採用した休み日
- 重複判定結果
- 実行コマンドと成否
- 失敗時はリトライ回数と最終エラー
