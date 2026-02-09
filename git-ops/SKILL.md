---
name: git-ops
description: Git operations policy including automatic branch/worktree creation and commits when code changes are complete. Use when asked to commit, push, create PRs, or when finishing a code change session.
---

# Git Ops

## 自動トリガー
以下の状況で自動的にこのスキルを適用する：
- **コード変更完了時**: 機能実装、バグ修正、リファクタリングが一区切りついた時
- **タスク開始時**: 新しいIssue/機能の着手時（worktree準備）
- **タスク切り替え時**: 別のタスクに移る前
- **セッション終了時**: ユーザーが作業終了を示した時
- **新機能開始時**: 新しい機能の実装を始める前（ブランチ確認）

## 自動実行フロー
1. **タスク情報の確定**: type/description/issue番号を決める
2. **ブランチ・Worktree自動設定**: `scripts/auto-worktree.sh`でタスク用worktreeを作成または再利用
3. **作業場所の固定**: 以降の実装/テスト/コミットは必ずそのworktreeで実施
4. **変更確認**: `git status`で未コミットの変更を確認
5. **自動コミット**: 変更があれば`scripts/auto-commit.sh`で自動コミット

## 必須ステップ
- `references/git-policy.md`を読み、ポリシーに従う
- **機能分離ポリシーを厳守**（1機能=1ブランチ）
- `scripts/auto-worktree.sh`でタスク別worktreeを自動作成（既存があれば再利用）
- `scripts/auto-commit.sh`でブランチ作成・コミットを自動化
- `scripts/pr.sh`でPR作成
- main/masterへの直接pushは禁止

## マイルストーンコミット（必須）
以下のタイミングで必ずコミット：
- 新ファイル作成後
- ビルド成功時
- 1機能完了時
- 別機能に着手する前

## 並行開発時の対策
複数機能を同時に開発する場合：
1. **Worktree自動化**: `scripts/auto-worktree.sh`でタスクごとに別ディレクトリを自動割当
2. **Stash活用**: ブランチ切り替え前に`git stash push -m "機能名-wip"`
3. **状態確認**: `git status`で混在を防止

## Worktree配置規約
- デフォルト配置先: `../wt/<repo名>/<branch名をスラッシュ置換>`
- ルート変更: `GIT_WORKTREE_ROOT` 環境変数で上書き可能
- 既存ブランチのworktreeがある場合は再作成せず再利用する

## 出力
- `references/git-policy.md`で指定されたフォーマットで結果を報告

## 他スキルとの連携

- **implementation-rules**: コード実装完了後、本スキルで自動コミット
- **code-review**: PR作成前のコードレビュー
- **ios-cicd-pipeline**: PR作成後、CIが自動実行される
