---
name: obsidian-brain
description: "ObsidianをAIエージェントの第二の脳として活用。セッション記録、知識参照、ファイルリンク機能を提供。トリガー: 'セッション記録', '作業ログ', 'Obsidian', '知識検索', 'ノート参照', '記録して', '覚えておいて', 'メモして'"
---

# Obsidian Brain

ObsidianをAIエージェントのナレッジベースとして活用するスキル。

## Vault Location

メインVault: `/Users/yappa/Documents/Obsidian/Second-brain`

### 全 Vault 一覧

| Vault        | 用途                                | パス            |
| ------------ | ----------------------------------- | --------------- |
| Second-brain | AI セッション・Daily Note・ナレッジ | `Second-brain/` |
| Labo         | 実験・研究                          | `Labo/`         |
| Personal     | 個人メモ                            | `Personal/`     |
| Tech         | 技術知識                            | `Tech/`         |
| Work         | 就活関連                            | `Work/`         |

## Directory Structure（Second-brain）

```
Second-brain/
├── AI-Sessions/    # セッション記録
├── Daily/          # Daily Note
├── Projects/       # プロジェクト別知識
├── Knowledge/      # 技術知識
├── Templates/      # テンプレート
└── MOC/            # 索引ページ
```

## Obsidian CLI Operations

Obsidian CLI の以下の操作を使用:

| Operation        | CLI Example                                                                 | Description      |
| ---------------- | --------------------------------------------------------------------------- | ---------------- |
| `read-note`      | `obsidian read --vault Second-brain --file "Daily/2026-02-27.md"`          | ノート読み取り   |
| `create-note`    | `obsidian write --vault Second-brain --file "AI-Sessions/xxx.md" --create` | ノート作成       |
| `edit-note`      | `obsidian write --vault Second-brain --file "AI-Sessions/xxx.md" --append` | ノート編集       |
| `search-vault`   | `obsidian search --vault Second-brain --query "SwiftUI 状態管理"`          | Vault内検索      |
| `add-tags`       | `obsidian tags add --vault Second-brain --file "Knowledge/xxx.md" --tag x` | タグ追加         |
| `create-folder`  | `obsidian mkdir --vault Second-brain --path "Projects/new-project"`         | ディレクトリ作成 |

## Workflows

### セッション開始時

1. `obsidian write --create` で新規セッションノートを `AI-Sessions/YYYY-MM-DD-{project}.md` に作成
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

1. `obsidian search` でキーワード検索
2. 関連ノートを `obsidian read` で読み取り
3. 必要に応じて `obsidian write --create` で `Knowledge/` に新規追加

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
