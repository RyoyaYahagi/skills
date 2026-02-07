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

## 自動実行フロー
1. **ブランチ確認**: main/master/developにいる場合は新ブランチを作成
2. **変更確認**: `git status`で未コミットの変更を確認
3. **自動コミット**: 変更があれば`scripts/auto-commit.sh`で自動コミット

## 必須ステップ
- `references/git-policy.md`を読み、ポリシーに従う
- `scripts/auto-commit.sh`でブランチ作成・コミットを自動化
- `scripts/pr.sh`でPR作成
- main/masterへの直接pushは禁止

## 出力
- `references/git-policy.md`で指定されたフォーマットで結果を報告

## 他スキルとの連携

- **implementation-rules**: コード実装完了後、本スキルで自動コミット
- **code-review**: PR作成前のコードレビュー
- **ios-cicd-pipeline**: PR作成後、CIが自動実行される

