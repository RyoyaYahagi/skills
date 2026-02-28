---
name: obsidian-brain
description: "ObsidianをAIエージェントの第二の脳として活用。セッション記録、Daily Note運用、知識参照、ファイルリンク機能を提供。トリガー: 'おはよう', '朝', '今日のタスク', 'Daily', '今日の予定', 'セッション記録', '作業ログ', 'Obsidian', '知識検索', 'ノート参照', '記録して', '覚えておいて', 'メモして'"
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
| Job-hunting  | 就活関連                            | `Job-hunting/`  |

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

| Operation      | CLI Example                                                                  | Description      |
| -------------- | ---------------------------------------------------------------------------- | ---------------- |
| `read-note`    | `obsidian read vault=Second-brain path="Daily/2026-02-27.md"`                | ノート読み取り   |
| `create-note`  | `obsidian create vault=Second-brain path="AI-Sessions/xxx.md" content="..."` | ノート作成       |
| `append-note`  | `obsidian append vault=Second-brain path="AI-Sessions/xxx.md" content="..."` | ノート追記       |
| `search-vault` | `obsidian search vault=Second-brain query="SwiftUI 状態管理"`                | Vault内検索      |
| `list-files`   | `obsidian files vault=Second-brain folder="Daily"`                           | ファイル一覧取得 |
| `daily-append` | `obsidian daily:append vault=Second-brain content="- [ ] 今日のタスク"`      | Daily Noteへ追記 |

## Workflows

### 「おはよう」トリガー（Daily Note作成）

1. 当日のノートパスを決定（例: `Daily/2026-02-28.md`）
2. `obsidian read vault=Second-brain path="Daily/YYYY-MM-DD.md"` を実行
3. 読み取り失敗（未作成）の場合は `obsidian create vault=Second-brain path="Daily/YYYY-MM-DD.md" content="..."` で作成
4. 前日のノート（`Daily/YYYY-MM-DD.md`）を読み取り、未完了タスク・持ち越し事項を抽出する
5. 全Vault（`Second-brain`, `Labo`, `Personal`, `Tech`, `Job-hunting`）を対象に `- [ ]` 形式の未完了ToDoを検索し、重複を除いて候補化する
6. 候補から本日の実行タスクを原則3件選定し、`## 今日のタスク` に反映する（最優先1件 + 重要2件を目安）
7. 本日のタスクリスト作成時は「前日の持ち越し」と「他Vaultの未完了ToDo」を `## 取り込みタスク` として記録し、チェックボックス形式で追記する（`obsidian append vault=Second-brain path="Daily/YYYY-MM-DD.md" content="- [ ] ..."`）
8. 応答時は作成/更新したノートのパスを明示し、取り込んだソース（前日Daily/他Vault未完了ToDo）と選定した3件を簡潔に報告する

### セッション開始時

1. `obsidian create` で新規セッションノートを `AI-Sessions/YYYY-MM-DD-{project}.md` に作成
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
3. 必要に応じて `obsidian create` で `Knowledge/` に新規追加

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
- `project-hub` - プロジェクト別タスク管理・進捗記録・失敗記録
