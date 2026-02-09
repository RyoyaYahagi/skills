---
name: git-ops
description: Git operations policy including automatic branch creation and commits when code changes are complete. Use when asked to commit, push, create PRs, or when finishing a code change session.
---

# Git Ops

## 自動トリガー
以下の状況で自動的にこのスキルを適用する：
- **コード変更完了時**: 機能実装、バグ修正、リファクタリングが一区切りついた時
- **タスク切り替え時**: 別のタスクに移る前
- **セッション終了時**: ユーザーが作業終了を示した時
- **新機能開始時**: 新しい機能の実装を始める前（ブランチ確認）

## 自動実行フロー
1. **ブランチ確認**: main/master/developにいる場合は新ブランチを作成
2. **変更確認**: `git status`で未コミットの変更を確認
3. **自動コミット**: 変更があれば`scripts/auto-commit.sh`で自動コミット

## 必須ステップ
- `references/git-policy.md`を読み、ポリシーに従う
- **機能分離ポリシーを厳守**（1機能=1ブランチ）
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
1. **Worktree使用**: `git worktree add`で別ディレクトリに
2. **Stash活用**: ブランチ切り替え前に`git stash push -m "機能名-wip"`
3. **状態確認**: `git status`で混在を防止

## 出力
- `references/git-policy.md`で指定されたフォーマットで結果を報告

## 他スキルとの連携

- **implementation-rules**: コード実装完了後、本スキルで自動コミット
- **code-review**: PR作成前のコードレビュー
- **ios-cicd-pipeline**: PR作成後、CIが自動実行される

