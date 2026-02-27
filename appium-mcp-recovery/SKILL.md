---
name: appium-mcp-recovery
description: Appium + MCP の初期セットアップと復旧手順を定型実行するスキル。Use when Appium server, driver, WDA, simulator, or MCP bridge fails to start/connect, or when rebuilding a clean local E2E environment.
---

# Appium MCP Recovery

## 使う場面
- Appium サーバー起動失敗
- `appium driver` の未導入/不整合
- iOS Simulator と WDA の接続不良
- MCP ブリッジ（WebDriver 接続）の不達
- 環境を一度クリアして再構築したい場合

## 進め方
1. 症状を分類する
- `起動不可` `接続不可` `テスト失敗` `不安定` のどれかを先に確定する。

2. 基本疎通を確認する
- Appium: `curl -s http://127.0.0.1:4723/status`
- MCP/WebDriver 側ステータス: 使っているポートの `/status`
- driver 一覧: `appium driver list`

3. 依存関係を正す
- 不足ドライバを導入する（例: `xcuitest`）。
- Node/npm のバージョン差異が疑わしい場合は、まず実行バイナリの場所を固定して再試行する。

4. iOS 側を復旧する
- `xcrun simctl` で対象 Simulator 状態を確認。
- 必要に応じて `shutdown` -> 再起動。
- WDA 失敗時は署名設定・Team 設定・DerivedData を重点確認。

5. キャッシュ/残骸を整理する
- 古いセッション、異常停止プロセス、壊れた一時ファイルを削除。
- 削除は最小範囲で行い、破壊的操作はユーザー明示同意後に実施。

6. 最小シナリオで再検証する
- 新規セッション作成 -> 画面ソース取得 -> 1操作（tap など）まで通す。
- 通過後に本来のテストフローへ戻す。

## エラー処理
- 同一原因には最大3回まで再試行。
- 3回失敗したら以下をまとめてエスカレーションする。
- 実行コマンド
- 主要ログ（直近失敗箇所）
- 直前の変更点（依存更新、Xcode 更新など）

## 出力フォーマット
- 原因仮説（1行）
- 実施した復旧手順（番号付き）
- 結果（成功/未解決）
- 未解決時の次アクション（最小2案）

## 非対象
- テストシナリオ設計そのものは `appium-simulator-test` を優先。
