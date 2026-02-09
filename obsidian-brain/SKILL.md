---
name: obsidian-brain
description: "ObsidianをAIエージェントの第二の脳として活用。セッション記録、知識参照、ファイルリンク機能を提供。トリガー: 'セッション記録', '作業ログ', 'Obsidian', '知識検索', 'ノート参照', '記録して', '覚えておいて', 'メモして'"
---

# Obsidian Brain

ObsidianをAIエージェントのナレッジベースとして活用するスキル。

## Vault Location

`/Users/yappa/Documents/Obsidian Vault`

## Directory Structure

```
Obsidian Vault/
├── AI-Sessions/    # セッション記録
├── Projects/       # プロジェクト別知識
├── Knowledge/      # 技術知識
├── Templates/      # テンプレート
└── MOC/            # 索引ページ
```

## MCP Tools

Obsidian MCP serverの以下のツールを使用:

| Tool               | Description      |
| ------------------ | ---------------- |
| `read-note`        | ノート読み取り   |
| `create-note`      | ノート作成       |
| `edit-note`        | ノート編集       |
| `search-vault`     | Vault内検索      |
| `add-tags`         | タグ追加         |
| `create-directory` | ディレクトリ作成 |

## Workflows

### セッション開始時

1. 新規セッションノートを `AI-Sessions/YYYY-MM-DD-{project}.md` に作成
2. テンプレート `Templates/session.md` を使用
3. プロジェクトページにセッションリンクを追加

### 作業中

1. 進捗・変更をセッションノートに記録
2. 発見した知識は `Knowledge/` に追記
3. 関連ノートへのリンクを追加

### セッション終了時

1. セッションノートのサマリーを更新
2. Next Stepsを記録
3. MOCの更新（必要に応じて）

### 知識検索

1. `search-vault` でキーワード検索
2. 関連ノートを `read-note` で読み取り
3. 必要に応じて `Knowledge/` に新規追加

## Templates

テンプレートは `Templates/` ディレクトリに配置:

- `session.md` - セッション記録
- `project.md` - プロジェクトページ
- `knowledge.md` - 技術ノート

## Naming Conventions

| Type      | Format                     | Example                            |
| --------- | -------------------------- | ---------------------------------- |
| Session   | `YYYY-MM-DD-{project}.md`  | `2025-02-08-stockpile-manager.md`  |
| Project   | `{project-name}/_Index.md` | `stockpile-manager/_Index.md`      |
| Knowledge | `{category}/{topic}.md`    | `iOS-Development/SwiftUI-State.md` |

## Related Skills

- `agent-memory` - 短期メモリ（Obsidianは長期）
- `git-ops` - コミット時にセッション記録と連携
- `implementation-rules` - 実装時の自動記録
