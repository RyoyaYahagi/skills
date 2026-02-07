---
name: ios-cicd-pipeline
description: iOS CI/CDパイプライン構築 with GitHub Actions。PRビルド・テスト自動化、SwiftLint/Danger統合、SPM/CocoaPodsキャッシュ最適化、Discord通知設定。CI構築、GitHub Actions設定、iOS自動ビルド、パイプライン構築等のキーワードで使用。
---

# iOS CI/CD Pipeline

GitHub ActionsでiOSアプリのCI/CDパイプラインを構築するスキル。

## ワークフロー

1. プロジェクト構成を確認（Xcode workspace/project、依存管理方式）
2. ワークフローの目的を特定（PR検証、develop自動ビルド、リリースビルド）
3. 適切なテンプレートを選択・カスタマイズ
4. 品質チェック・通知を設定

## 必須入力

- Xcode project/workspace パス
- スキームとターゲット
- 依存管理: SPM / CocoaPods / Carthage / None
- テストターゲットの有無
- 品質ツール: SwiftLint / Danger / None
- 通知先: Discord / None

## ワークフロー種類

| 種類         | トリガー          | 用途                                 |
| ------------ | ----------------- | ------------------------------------ |
| PR検証       | pull_request      | ビルド・テスト・品質チェック         |
| 開発ブランチ | push to develop   | スナップショットビルド               |
| リリース     | workflow_dispatch | App Store/TestFlight（fastlane連携） |

## 実装手順

1. `.github/workflows/` ディレクトリを作成
2. `references/github-actions-templates.md`からテンプレートを選択
3. プロジェクト固有の設定を反映
4. 品質チェック追加時は`references/quality-checks.md`を参照
5. キャッシュ最適化は`references/caching-strategies.md`を参照

## 他スキルとの連携

- **git-ops**: PR作成後、CIパイプラインが自動実行される
- **fastlane-appstore-release**: リリースワークフローでFastlaneを呼び出す

## 出力

- `.github/workflows/ios-ci.yml`（PR検証用）
- `.github/workflows/ios-release.yml`（リリース用、fastlane連携）
- 必要に応じて `.swiftlint.yml`、`Dangerfile`

## References

- references/github-actions-templates.md
- references/quality-checks.md
- references/caching-strategies.md
