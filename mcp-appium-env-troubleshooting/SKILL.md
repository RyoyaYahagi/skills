---
name: mcp-appium-env-troubleshooting
description: "Appium MCP の起動失敗や依存不整合を短時間で切り分け・復旧するスキル。node module not found、nvm未設定、capabilities不整合、セッション作成失敗などの初動復旧で使用。トリガー: appium-mcp, MCPエラー, nvm, Cannot find module, create_session失敗。"
---

# MCP Appium Env Troubleshooting

## Goal

Appium MCP の環境エラーを再現可能な形で切り分け、最小手順で復旧する。
本スキルは「実操作テストそのもの」ではなく、テスト前提となる実行環境の復旧を担当する。

## When To Use

- `appium-mcpを設定したい`
- `MCPのエラーを解決して`
- `Cannot find module` や `command not found: nvm` が出る
- `create_session` が環境要因で失敗する

## Non-Goal

- 実装差分に対するE2E検証の設計と実行
- UI仕様の妥当性確認

上記は `appium-simulator-test` で扱う。

## Workflow

1. 症状の固定
- 失敗コマンド、エラーメッセージ、発生時刻を記録する。
- エラーを「依存」「ランタイム」「デバイス」「capabilities」「サーバー状態」に分類する。

2. 依存関係チェック
- Node/NPM のバージョンと PATH を確認する。
- `nvm` 不在時は、代替Node実行パスを特定する。
- `Cannot find module` は不足パッケージと壊れた install のどちらかを切り分ける。

3. Appium/MCPの生存確認
- Appium サーバー到達性 (`/status`) を確認する。
- MCP設定ファイルと capabilities ファイルの参照先を確認する。
- 既存プロセスが古い設定を握っていないか確認する。

4. iOSシミュレーター整合性確認
- 利用可能デバイス一覧と指定デバイス名の一致を確認する。
- `platformVersion` と実在ランタイムの不一致を修正する。

5. capabilities最小化検証
- 最小 capabilities で `create_session` を試行する。
- 成功後に必要項目を段階的に戻し、失敗点を特定する。

6. 復旧確認
- 復旧後に同一手順で再試行し、成功結果を記録する。
- 再現しない一過性障害か、恒常設定不備かを区別する。

## Retry Policy

- 同一原因への自動再試行は最大3回。
- 3回失敗したら、試行ログと暫定診断をまとめてエスカレーションする。

## Output Format

- 症状要約
- 原因分類
- 実施した切り分け手順
- 最終原因
- 恒久対策
- 再発時チェックリスト

## Coordination

- `appium-simulator-test` の前段として使う。
- `sandbox-escalation` が必要な操作は即時エスカレーションする。
