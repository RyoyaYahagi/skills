---
name: ai-orchestrator
description: "AIオーケストレーション — Obsidian ToDo・GitHub IssueからタスクをAIが自律選定し、計画→承認→実装→テスト→記録のサイクルを段階承認型で回す指揮スキル。トリガー: 「オーケストレーション」「次のタスク」「今日の作業」「タスク選定」「何をやるべき」「orchestrate」「作業計画」「自動計画」。また、セッション開始時・おはようトリガー後のタスク着手フェーズで自動適用する。"
---

# AI Orchestrator — 段階承認型オーケストレーション

Obsidian と GitHub Issue を情報源として、AIが **タスク選定 → 計画策定 → 承認 → 実装 → テスト → 記録** のサイクルを回す指揮スキル。

人間は各フェーズの承認ポイントで判断・承認を行い、実装フェーズではモデルを切り替えて別セッションで作業する運用を想定する。

## アーキテクチャ

```
┌─────────────────────────────────────────────────┐
│  Phase 0: 情報収集                                │
│  Obsidian ToDo + GitHub Issue + 前回 Next Steps  │
└──────────────┬──────────────────────────────────┘
               ▼
┌─────────────────────────────────────────────────┐
│  Phase 1: タスク選定・優先度判定                   │
│  緊急度×重要度で3件選定 → 人間に提示             │
└──────────────┬──────────────────────────────────┘
               ▼  ← 🔒 承認ポイント①
┌─────────────────────────────────────────────────┐
│  Phase 2: 計画策定                                │
│  research-plan-implement で詳細計画を作成         │
└──────────────┬──────────────────────────────────┘
               ▼  ← 🔒 承認ポイント②
┌─────────────────────────────────────────────────┐
│  Phase 3: 実装（モデル切替）                      │
│  人間が Sonnet 等に切り替えて実装                 │
│  完了後、本セッションに戻る                       │
└──────────────┬──────────────────────────────────┘
               ▼
┌─────────────────────────────────────────────────┐
│  Phase 4: 品質チェック（Codex委譲）               │
│  codex-test-delegate でレビュー+テスト+Issue作成  │
└──────────────┬──────────────────────────────────┘
               ▼  ← 🔒 承認ポイント③
┌─────────────────────────────────────────────────┐
│  Phase 5: 記録・次サイクル判定                    │
│  Obsidian記録 → 次タスクに進むか人間が判断       │
└─────────────────────────────────────────────────┘
```

## Phase 0: 情報収集

3つの情報源から未完了タスクを網羅的に収集する。

### 0-1. Obsidian ToDo 検索

```bash
# 全Vaultから未完了ToDoを検索
obsidian search vault=Second-brain query="- [ ]"

# 当日 Daily Note を確認
obsidian read vault=Second-brain path="Daily/YYYY-MM-DD.md"

# 対象プロジェクトのタスク確認（project-hub で判定後）
obsidian read vault=Second-brain path="Projects/{project}/tasks.md"
```

### 0-2. GitHub Issue 確認

```bash
# Open Issue を一覧取得
gh issue list --state open --limit 30

# 優先度ラベル付きを優先表示
gh issue list --state open --label "priority:high" --limit 10

# 気になるIssueの詳細を確認
gh issue view <番号>
```

### 0-3. 前回セッションの Next Steps

```bash
# 直近のセッションノートを検索
obsidian search vault=Second-brain query="Next Steps"

# 直近のセッションノートを読む
obsidian read vault=Second-brain path="AI-Sessions/YYYY-MM-DD-{project}.md"
```

### エラーハンドリング

- `gh` が使えない場合: Obsidian ToDo のみで優先度を判定する。GitHub Issue は手動確認を依頼
- `obsidian` CLI が使えない場合: ファイルシステム直接読み取り（`/Users/yappa/Documents/Obsidian/Second-brain/`）で代替
- 両方使えない場合: ユーザーに「今日やりたいこと」を直接質問してPhase 1 へ進む

### 収集結果の統合

収集した情報を内部的に整理し、Phase 1 でまとめて提示する。

## Phase 1: タスク選定・優先度判定

### 優先度マトリクス

収集したタスクを **緊急度 × 重要度** の2軸で評価する。

|                | 重要（高）   | 重要（低）   |
| -------------- | ------------ | ------------ |
| **緊急（高）** | 🔴 P1: 即対応 | 🟠 P2: 今日中 |
| **緊急（低）** | 🟡 P3: 今週中 | 🔵 P4: いつか |

### 判定基準

- **緊急度の判定材料**:
  - GitHub Issue にラベル `priority:high`, `bug`, `hotfix` がある → 緊急度 高
  - Daily Note の本日タスクに含まれる → 緊急度 高
  - 締め切り (due date) が今日/明日 → 緊急度 高
  - それ以外 → 緊急度 低

- **重要度の判定材料**:
  - ユーザーの直近の会話で言及されたタスク → 重要度 高
  - プロジェクトの `_Index.md` でマイルストーンに関連 → 重要度 高
  - 他タスクのブロッカーになっている → 重要度 高
  - それ以外 → 重要度 低

### 提示フォーマット（🔒 承認ポイント①）

以下の形式で人間にタスク候補を提示し、承認を求める：

```markdown
## 📋 本日のタスク候補

### 🔴 P1（即対応）
1. **[タスク名]** — [概要1行]
   - 源: GitHub Issue #XX / Obsidian ToDo / 前回NS
   - プロジェクト: {project-name}
   - 見積: 約X時間

### 🟠 P2（今日中）
2. **[タスク名]** — [概要1行]
   ...

### 保留タスク（P3-P4）
- [タスク名] — [理由]
- ...

---
**推奨**: タスク1 → タスク2 の順で着手
**質問**: この順序で進めてよいですか？変更・追加があれば指示してください。
```

人間が承認またはタスクを選択したら、Phase 2 へ進む。

## Phase 2: 計画策定

承認されたタスクについて、`research-plan-implement` スキルの Phase 1-4 を実行する。

### 実行手順

1. `research-plan-implement` の Phase 1（Research） を実行し `research.md` を作成
2. Phase 2（Planning）で `plan.md` を作成
3. Phase 3（Annotation Cycle）でユーザーと計画を精練
4. Phase 4（Todo List）で実装タスクリストを確定

### 計画に含める追加情報（オーケストレーター固有）

通常の `plan.md` に加え、以下を明記する：

```markdown
## 実装ガイド（Sonnet向け）

### コンテキスト
- プロジェクト: {project-name}
- ブランチ: {branch-name}（git-ops で事前作成）
- 関連Issue: #{issue-number}

### 実装時の注意点
- [プロジェクト固有のルール、rules.md から抽出]
- [既存コードのパターン、research.md から抽出]

### 完了条件
- [ ] 全タスク実装完了
- [ ] ビルド成功
- [ ] 既存テスト全PASS
```

### 承認（🔒 承認ポイント②）

計画を人間に提示し、承認を得る。ここで計画が fix される。

承認時に人間に伝えること：
```
計画が確定しました。
実装セッションに切り替えてください（Sonnet推奨）。
plan.md の Todo List に従って実装を進め、完了したらこのセッションに戻ってきてください。
```

## Phase 3: 実装（モデル切替）

このフェーズはオーケストレーター自身は実行しない。人間が別モデル（Sonnet等）に切り替えて実装する。

### オーケストレーターの仕事（実装前）

1. **ブランチ準備**: `git-ops` で実装ブランチを作成（`git checkout -b feature/{task-name}`）
2. **plan.md を作業ディレクトリに配置**: 実装者が参照できるようにする
3. **Obsidian に「実装開始」を記録**: セッションノートに追記

### 実装完了の検知

以下のキーワードで Phase 4 への遷移を判定する：
- 「実装完了」「戻ってきた」「テストして」「レビューして」「codex」「品質チェック」

遷移前に自動で確認する項目：
1. `git status` — 未コミット変更がないか
2. `git log --oneline -5` — コミット状況
3. ビルド可否（プロジェクトに応じて `npm run build` / `xcodebuild` / `swift build`）

未コミット変更がある場合は、`git-ops` でコミットを促してからPhase 4に進む。

## Phase 4: 品質チェック（Codex 委譲）

`codex-test-delegate` スキルを呼び出して品質チェックを実行する。

### 実行内容

1. **コードレビュー**: `codex review --base main` でブランチ差分をレビュー
2. **テストケース作成**: 変更ファイルに対するテスト自動生成
3. **テスト実行**: 全件PASSまで自動修正ループ
4. **Issue自動作成**: 直せなかったバグ・追加機能提案をGitHub Issueに登録

### 結果レポート

`codex-test-delegate` の Phase 4 レポートフォーマットに従い、結果を人間に報告する。

### 承認（🔒 承認ポイント③）

テスト結果を人間に提示：

```markdown
## 🧪 品質チェック結果

- **コードレビュー**: 🔴 0件 / 🟠 1件 / 🟡 2件
- **テスト結果**: ✅ 全件PASS（12/12）
- **Issue作成**: 1件（enhancement #XX）

**推奨アクション**:
- [ ] PR作成して main にマージ
- [ ] 次のタスクに着手

進めてよいですか？
```

承認後：
- `git-ops` の `scripts/pr.sh` で PR 作成
- iOSアプリの場合は `appium-simulator-test` も実行

## Phase 5: 記録・次サイクル判定

### Obsidian 記録（プロジェクト単位）

記録は `project-hub` で判定したプロジェクトのノートに集約する。
ノートが存在しない場合は自動で新規作成してから記録する。

#### Step 5-1: プロジェクトノートの存在確認と作成

```bash
# プロジェクトフォルダの存在確認
obsidian read vault=Second-brain path="Projects/{project}/_Index.md"

# 読み取り失敗（未作成）の場合 → project-hub のプロジェクト登録フローで一式作成
# 作成されるノート:
#   Projects/{project}/_Index.md
#   Projects/{project}/tasks.md
#   Projects/{project}/progress-log.md
#   Projects/{project}/decisions.md
#   Projects/{project}/failures.md
```

セッションノートも同様に存在確認 → 未存在なら作成：

```bash
# 本日のセッションノート確認
obsidian read vault=Second-brain path="AI-Sessions/YYYY-MM-DD-{project}.md"

# 未存在の場合 → テンプレートから新規作成
obsidian create vault=Second-brain path="AI-Sessions/YYYY-MM-DD-{project}.md" \
  content="# セッション: {project} (YYYY-MM-DD)\n\n## 目的\n- {task-name}\n\n## ログ\n"
```

#### Step 5-2: プロジェクトノートへの記録

```bash
# 1. セッションノートに完了記録
obsidian append vault=Second-brain path="AI-Sessions/YYYY-MM-DD-{project}.md" \
  content="## タスク完了: {task-name}\n- コミット: {hash}\n- PR: #{pr-number}\n- テスト結果: 全PASS\n- 所要時間: X時間"

# 2. プロジェクト進捗ログに追記
obsidian append vault=Second-brain path="Projects/{project}/progress-log.md" \
  content="## YYYY-MM-DD\n- {task-name} 完了\n- PR: #{pr-number}\n- 関連セッション: [[AI-Sessions/YYYY-MM-DD-{project}]]"

# 3. プロジェクトのタスクを完了にマーク
# Projects/{project}/tasks.md の該当タスクを [x] に更新

# 4. Daily Note に実績を記録（存在確認は obsidian-brain 側で担保）
obsidian append vault=Second-brain path="Daily/YYYY-MM-DD.md" \
  content="- [x] {task-name}（{project}）"
```

#### Step 5-3: 意思決定記録（decisions.md）

以下のタイミングで `Projects/{project}/decisions.md` に記録する：

- **Phase 2（計画確定時）**: 技術選定、アーキテクチャ判断、ライブラリ選択
- **Phase 4（テスト後）**: テスト結果に基づく方針変更、Issue化判断
- **承認ポイントでの人間の判断**: タスク選定理由、計画修正内容

```bash
obsidian append vault=Second-brain path="Projects/{project}/decisions.md" \
  content="## YYYY-MM-DD: {決定事項}\n- **背景**: {何が問題/論点だったか}\n- **検討した選択肢**: {選択肢A, B, ...}\n- **決定内容**: {何を選んだか}\n- **理由**: {なぜその選択肢を選んだか}"
```

#### Step 5-4: 失敗・教訓記録（failures.md）

以下のタイミングで `Projects/{project}/failures.md` に記録する：

- **Phase 4（テスト失敗時）**: Codexが修正できなかったバグ、タイムアウト
- **Phase 3（実装で問題発生時）**: ビルド失敗、設計ミス、手戻り
- **リトライ・方針変更時**: 計画の再策定が必要になった場合

```bash
obsidian append vault=Second-brain path="Projects/{project}/failures.md" \
  content="## YYYY-MM-DD: {失敗の概要}\n- **何が起きたか**: {事象}\n- **原因**: {根本原因}\n- **対処**: {どう解決したか}\n- **教訓**: {次回以降に活かすこと}"
```

> 失敗記録は恥ではなく資産。同じ失敗を繰り返さないために、小さな手戻りも記録する。

#### 記録の原則

- **記録先の優先順**: プロジェクトノート（`Projects/{project}/`） > セッションノート > Daily Note
- **未存在時**: 読み取りに失敗したノートは `project-hub` のテンプレートから自動作成してから追記
- **既存ノート**: 絶対に上書きせず、差分追記のみ
- **意思決定・失敗は Phase 完了を待たず即時追記**: 判断した瞬間・失敗した瞬間に記録する

### 次サイクル判定

人間に次のアクションを確認：

```markdown
## ✅ タスク完了

**{task-name}** が完了しました。

### 次の選択肢
1. **次のタスクに着手** → Phase 0 に戻って次のタスクを選定
2. **本日は終了** → セッション終了記録をして終了
3. **別の作業** → 指示をどうぞ

どうしますか？
```

「次のタスク」を選んだ場合は Phase 0 に戻る（情報を再収集して最新状態でタスク選定）。

## 承認ポイントまとめ

| #   | タイミング   | 人間が判断すること     | 判断後のアクション           |
| --- | ------------ | ---------------------- | ---------------------------- |
| ①   | タスク選定後 | どのタスクに着手するか | 選択されたタスクの計画策定へ |
| ②   | 計画策定後   | 計画の承認、修正指示   | 実装セッションへ切替         |
| ③   | テスト完了後 | PR作成/マージの承認    | PR作成 → 次サイクル判定      |

## 関連スキル

| スキル                    | 連携タイミング | 役割                               |
| ------------------------- | -------------- | ---------------------------------- |
| `obsidian-brain`          | Phase 0, 5     | ToDo読取、セッション記録           |
| `project-hub`             | Phase 0, 5     | プロジェクト判定、タスク管理       |
| `research-plan-implement` | Phase 2        | 計画策定の実行エンジン             |
| `codex-test-delegate`     | Phase 4        | テスト委譲・レビュー               |
| `git-ops`                 | Phase 3, 4     | ブランチ作成、コミット、PR         |
| `autonomous-decision`     | 全Phase        | 自律判断（エスカレーション判定）   |
| `implementation-rules`    | Phase 3        | 実装ルールの適用（Sonnet側で参照） |
| `appium-simulator-test`   | Phase 4        | iOSアプリのUI検証                  |

## 運用例

### 典型的な1日のフロー

```
09:00 「おはよう」→ obsidian-brain が Daily Note 作成
09:05  ai-orchestrator Phase 0-1: タスク候補を提示
09:10  人間がタスク1を承認 ← 承認①
09:15  Phase 2: 計画策定（research-plan-implement）
09:30  人間が計画を承認 ← 承認②
09:35  人間がモデルを Sonnet に切替、実装開始
11:00  実装完了、オーケストレーターのセッションに戻る
11:05  Phase 4: Codex でテスト委譲
11:20  テスト全PASS、人間がPR承認 ← 承認③
11:25  Phase 5: 記録完了、次タスクに進むか確認
11:30  次のタスクに着手 → Phase 0 に戻る
```

### 「次のタスク」のショートカット

Phase 5 完了直後に「次」と言われた場合は、Phase 0 の情報源を更新して Phase 1 のタスク選定に直接進む。
