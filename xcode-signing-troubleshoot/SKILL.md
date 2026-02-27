---
name: xcode-signing-troubleshoot
description: Xcode の Code Signing / Provisioning エラーを短時間で切り分けて復旧するスキル。Use when build/archive/export fails due to signing certificates, provisioning profiles, entitlements, or team/bundle mismatch.
---

# Xcode Signing Troubleshoot

## 使う場面
- `Code signing failed`
- `No signing certificate` / `No profiles for ...`
- Archive/Export 時のみ失敗する
- Debug は通るが Release で失敗する

## 進め方
1. 失敗フェーズを固定する
- `build` `archive` `export` のどこで失敗したかを先に確定する。

2. 識別子と Team を整合させる
- `Bundle Identifier` と Provisioning Profile の組み合わせを確認。
- Target ごとに Team が混在していないか確認。

3. 証明書とプロファイルを確認する
- 有効期限切れ・失効・重複を確認。
- 自動署名/手動署名の方針を一時的に統一して挙動を確認。

4. Entitlements を照合する
- Push, Keychain, App Groups など capability と profile の対応を確認。
- Debug/Release で entitlements が分岐している場合は差分を確認。

5. ローカル状態をリフレッシュする
- DerivedData・キャッシュ・一時成果物を整理。
- Keychain の古い証明書が競合する場合は不要分を退避/削除。

6. 再ビルドして最小確認する
- まず build 成功を確認し、次に archive/export を段階的に確認する。

## エラー処理
- 同じ切り分けステップは3回まで再試行。
- 収束しない場合は、以下を添えてエスカレーション。
- 正確なエラーメッセージ
- 対象 Target/Configuration
- 署名方式（自動/手動）と最近の変更

## 出力フォーマット
- 原因候補（優先順3件）
- 実施した検証（チェック結果つき）
- 修正内容
- 再発防止（設定固定/ドキュメント化項目）

## 非対象
- Fastlane 全体設計や配布自動化は `fastlane-appstore-release` を優先。
