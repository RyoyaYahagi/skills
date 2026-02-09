---
name: ios-bug-checker
description: iOSアプリのよくあるバグパターンを網羅的にチェック。メモリリーク、循環参照、並行処理バグ、UIレイアウト問題、Force Unwrap、ライフサイクル問題、Swift Concurrencyエラーなどを静的解析＋動的チェック。トリガー：「バグチェック」「クラッシュ調査」「メモリリーク」「コードレビュー」「品質チェック」「iOS診断」。
---

# iOS Bug Checker

iOSアプリのよくあるバグパターンを網羅的にチェックするスキル。

## ワークフロー

1. **対象スコープ特定** - プロジェクト全体 or 特定ファイル/機能
2. **静的解析** - コードパターンからバグを検出
3. **動的チェック** - ビルド警告、Instrumentsプロファイル
4. **レポート生成** - 重要度別に分類したバグ一覧

## チェック実行

```bash
# プロジェクトで実行
scripts/ios_bug_checker.py <project-path> [--category <category>]
```

| カテゴリ      | 説明                                         |
| ------------- | -------------------------------------------- |
| `memory`      | メモリリーク、循環参照、強参照サイクル       |
| `concurrency` | データ競合、デッドロック、メインスレッド違反 |
| `ui`          | レイアウト制約、Dark Mode、Safe Area         |
| `crash`       | Force Unwrap、未処理例外、配列境界           |
| `lifecycle`   | ViewController/App ライフサイクル問題        |
| `swift6`      | Swift 6 Concurrency、Sendable違反            |
| `network`     | エラーハンドリング不足、タイムアウト         |
| `all`         | 全カテゴリチェック（デフォルト）             |

## バグパターン詳細

各カテゴリの詳細なチェック項目：

| カテゴリ                    | 参照                                                             |
| --------------------------- | ---------------------------------------------------------------- |
| メモリ・参照サイクル        | [references/memory-bugs.md](references/memory-bugs.md)           |
| 並行処理・Swift Concurrency | [references/concurrency-bugs.md](references/concurrency-bugs.md) |
| UI・レイアウト              | [references/ui-bugs.md](references/ui-bugs.md)                   |
| クラッシュ・Optional        | [references/crash-bugs.md](references/crash-bugs.md)             |
| ライフサイクル・状態管理    | [references/lifecycle-bugs.md](references/lifecycle-bugs.md)     |

## 重要度レベル

| レベル     | 説明                               | 対応優先度         |
| ---------- | ---------------------------------- | ------------------ |
| 🔴 Critical | クラッシュ直結、データ損失リスク   | 即時対応必須       |
| 🟠 High     | パフォーマンス劣化、UX低下         | 今スプリントで対応 |
| 🟡 Medium   | 潜在的問題、将来のリスク           | 計画的に対応       |
| 🔵 Low      | コード品質、ベストプラクティス違反 | 余裕があれば対応   |

## 他スキルとの連携

- **ios-development**: 実装時のバグ予防
- **code-review**: PRレビュー時のバグチェック
- **appium-simulator-test**: 動的テストでバグ検出
- **security-audit**: セキュリティ関連バグの深掘り
