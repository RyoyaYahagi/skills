---
name: project-hub
description: "Obsidian Second-Brain の Projects フォルダでプロジェクトごとのタスク管理・進捗記録・失敗記録を一元管理するスキル。作業ディレクトリやキーワードからプロジェクトを自動判定し、対応するプロジェクトノートを更新する。トリガー: 'プロジェクト', 'タスク追加', '進捗記録', '進捗確認', '失敗記録', '教訓', 'プロジェクト登録', 'プロジェクト一覧', 'project'。また、実装作業やセッション記録の際に作業ディレクトリからプロジェクトを自動判定する目的でも使用する。"
---

# Project Hub

Obsidian Second-Brain の `Projects/` フォルダを使い、プロジェクト単位でタスク管理・進捗記録・失敗記録を行うスキル。

## Vault & Paths

- Vault: `/Users/yappa/Documents/Obsidian/Second-brain`
- Projects: `Projects/`
- Templates: `Templates/`
- レジストリ: このスキルの `projects-registry.json`

## プロジェクト自動判定（3段階）

ユーザーが作業中のプロジェクトを以下の優先順で判定する。

### 1. 作業ディレクトリ判定（最優先）

`projects-registry.json` の各プロジェクトの `workDirs` と、ユーザーの現在の作業ディレクトリ（Active Document のパスやワークスペース URI）を**前方一致**で照合する。

```
例: workDirs に "/Users/yappa/code/app/foodstock" がある場合
    → /Users/yappa/code/app/foodstock/FoodStock/Views/... にマッチ
```

### 2. キーワード・文脈判定

作業ディレクトリで判定できなかった場合、ユーザーのリクエスト文中に `keywords` のいずれかが含まれるかを**大文字小文字区別なし**で照合する。

```
例: keywords に "FoodStock" がある場合
    → 「FoodStockのレシピ画面を修正して」にマッチ
```

複数プロジェクトにマッチした場合は、マッチしたキーワード数が多い方を優先する。同数の場合はユーザーに確認する。

### 3. ユーザー確認（フォールバック）

上記で一意に特定できない場合は、**必ず**ユーザーに質問する。推測で進めてはいけない。

```
「このタスクはどのプロジェクトに記録しますか？」
  1. FoodStock
  2. skills
  3. sc-experiment
  4. 新規プロジェクトを作成
```

## プロジェクト登録（新規作成）

新しいプロジェクトを登録する手順：

1. `projects-registry.json` にエントリを追加する
2. Obsidian に `Projects/{project-name}/` フォルダを作成する
3. 以下のノートを各テンプレートから作成する:
   - `_Index.md` ← `Templates/project.md`
   - `tasks.md` ← `Templates/project-tasks.md`
   - `progress-log.md` ← `Templates/project-progress-log.md`
   - `decisions.md` ← `Templates/project-decisions.md`
   - `failures.md` ← `Templates/project-failures.md`
4. `Projects/_Index.md` にプロジェクトリンクを追加する

## プロジェクトフォルダ構造

```
Projects/{project-name}/
├── _Index.md          # 概要・ステータス・Tech Stack
├── tasks.md           # タスク管理（チェックリスト）
├── progress-log.md    # 進捗ログ（時系列）
├── decisions.md       # 設計判断・意思決定記録
└── failures.md        # 失敗・教訓記録
```

## ノート操作

### タスク追加

`tasks.md` に追記:
```markdown
- [ ] {タスク内容}
  - 追加日: YYYY-MM-DD
  - 優先度: P1/P2/P3
```

### タスク完了

`tasks.md` のチェックボックスを更新:
```markdown
- [x] {タスク内容}
  - 追加日: YYYY-MM-DD → 完了日: YYYY-MM-DD
```

### 進捗記録

`progress-log.md` に追記:
```markdown
## YYYY-MM-DD
- 実施内容の要約
- 関連セッション: [[AI-Sessions/YYYY-MM-DD-{project}]]
```

### 失敗・教訓記録

`failures.md` に追記:
```markdown
## YYYY-MM-DD: {失敗の概要}
- **何が起きたか**: 
- **原因**: 
- **対処**: 
- **教訓**: 
```

### 意思決定記録

`decisions.md` に追記:
```markdown
## YYYY-MM-DD: {決定事項}
- **背景**: 
- **検討した選択肢**: 
- **決定内容**: 
- **理由**: 
```

## 暗黙の適用

以下のスキルが動作する際、プロジェクト判定を自動で行い、関連ノートの更新を検討する：

- `obsidian-brain` のセッション記録時 → 進捗ログに追記
- `implementation-rules` の実装完了時 → タスクの状態更新
- `git-ops` のコミット時 → 進捗ログに追記

## references

運用上の失敗や改善メモは `references/notes.md` に記録する。
判定精度の改善や、レジストリ運用のTipsなどはこのファイルを参照・追記すること。

## Related Skills

- `obsidian-brain` - Vault操作の基盤
- `implementation-rules` - 実装完了時の自動記録
- `git-ops` - コミット時の連携
