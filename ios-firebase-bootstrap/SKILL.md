---
name: ios-firebase-bootstrap
description: iOS プロジェクトへの Firebase 初期導入を安全に定型化するスキル。Use when adding Firebase to a new or existing iOS app, including SPM setup, GoogleService-Info.plist placement, initialization, and baseline verification.
---

# iOS Firebase Bootstrap

## 使う場面
- Firebase を初めて導入する
- `GoogleService-Info.plist` 配置や Bundle ID 整合で詰まる
- 初期化漏れで runtime エラーが出る

## 進め方
1. 導入目的を固定する
- 使うプロダクト（Analytics / Crashlytics / Auth / Messaging など）を先に列挙する。

2. 依存関係を追加する
- SPM で必要最小限の Firebase モジュールだけ導入する。
- 不要なモジュールの同時導入は避ける。

3. 設定ファイルを整合させる
- `GoogleService-Info.plist` を正しい Target に追加。
- Bundle ID と Firebase コンソール側 App 設定の一致を確認。

4. 初期化を実装する
- App 起動時に `FirebaseApp.configure()` を1回だけ実行。
- SwiftUI/AppDelegate 構成に応じて初期化位置を明示する。

5. 機能別の追加設定を行う
- Crashlytics, Push, URL Scheme など必要分のみ設定。
- capability 変更がある場合は signing 設定との整合を再確認。

6. ベースライン検証を実施する
- ビルド成功
- 起動時クラッシュなし
- ログ上で Firebase 初期化成功を確認

## エラー処理
- 同一手順で3回失敗した場合は、以下を添えてエスカレーション。
- 対象 Target と構成（Debug/Release）
- plist の配置状況
- Firebase コンソール設定との差分

## 出力フォーマット
- 導入対象機能
- 実施手順（番号付き）
- 検証結果
- 残課題（あれば）

## 非対象
- iOS 全般アーキテクチャ設計は `ios-development` を優先。
