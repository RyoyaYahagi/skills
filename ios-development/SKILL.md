---
name: ios-development
description: iOSアプリ実装パターン。MVVM/TCAアーキテクチャ、SwiftUI状態管理、API通信、データ永続化（SwiftData）、プッシュ通知設定。iOS実装、SwiftUI、アーキテクチャ、API通信、SwiftData等のキーワードで使用。
---

# iOS Development Patterns

SwiftUI/UIKitアプリの実装パターンとベストプラクティス。

## ワークフロー

1. アーキテクチャ選択（MVVM / TCA / MV）
2. 画面・機能ごとに適切なパターンを適用
3. 必要に応じてデータ永続化・API通信・通知を設定

## シミュレーター設定

xcodebuildでビルド・テストを実行する際は、以下のシミュレーターを使用すること：

```bash
# ビルドコマンド
xcodebuild -project {ProjectName}.xcodeproj -scheme {SchemeName} \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

# テストコマンド
xcodebuild -project {ProjectName}.xcodeproj -scheme {SchemeName} \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

**注意**: iPhone 16やその他のシミュレーターではなく、必ず**iPhone 17**を使用すること。

## 機能別ガイド

| 機能            | 参照ドキュメント                 |
| --------------- | -------------------------------- |
| アーキテクチャ  | references/architecture.md       |
| SwiftUIパターン | references/swiftui-patterns.md   |
| API通信         | references/networking.md         |
| データ永続化    | references/data-persistence.md   |
| プッシュ通知    | references/push-notifications.md |

## 推奨アーキテクチャ

| アプリ規模         | 推奨                               |
| ------------------ | ---------------------------------- |
| 小規模（1-5画面）  | MV（Model-View）                   |
| 中規模（5-20画面） | MVVM + Repository                  |
| 大規模             | TCA（The Composable Architecture） |

## 他スキルとの連携

- **hig-ooui-mobile-design**: UI設計 → 本スキルで実装
- **git-ops**: 機能実装完了 → コミット（**1機能1コミット必須**）
- **ios-cicd-pipeline**: 実装 → CI/CDパイプライン
- **fastlane-appstore-release**: CI → リリース

### 実装→コミットフロー
1. 機能実装完了
2. ビルド成功確認
3. git-opsでコミット提案
4. 次の機能へ

## References

- references/architecture.md
- references/swiftui-patterns.md
- references/networking.md
- references/data-persistence.md
- references/push-notifications.md
