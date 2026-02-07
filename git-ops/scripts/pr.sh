#!/bin/bash

# 汎用PR作成スクリプト
# どのプロジェクトでも使用可能
# 
# 使い方: ./scripts/pr.sh [オプション]
# オプション:
#   -m, --merge    PRを作成後に自動マージ（非推奨）
#   -d, --draft    ドラフトPRとして作成
#   -b, --base     ベースブランチを指定（デフォルト: main）

set -e

# 引数の解析
AUTO_MERGE=false
DRAFT=false
BASE_BRANCH=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--merge) AUTO_MERGE=true; shift ;;
        -d|--draft) DRAFT=true; shift ;;
        -b|--base) BASE_BRANCH="$2"; shift 2 ;;
        *) shift ;;
    esac
done

# 現在のブランチを取得
BRANCH=$(git branch --show-current)

if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
    echo "Error: main/masterブランチからはPRを作成できません"
    exit 1
fi

# ベースブランチの自動検出
if [ -z "$BASE_BRANCH" ]; then
    if git show-ref --verify --quiet refs/remotes/origin/develop; then
        BASE_BRANCH="develop"
    elif git show-ref --verify --quiet refs/remotes/origin/main; then
        BASE_BRANCH="main"
    elif git show-ref --verify --quiet refs/remotes/origin/master; then
        BASE_BRANCH="master"
    else
        BASE_BRANCH="main"
    fi
fi

# コミットメッセージからPR情報を生成
COMMITS=$(git log origin/$BASE_BRANCH..$BRANCH --pretty=format:"- %s" --reverse 2>/dev/null || git log -10 --pretty=format:"- %s" --reverse)
FIRST_COMMIT=$(git log origin/$BASE_BRANCH..$BRANCH --pretty=format:"%s" --reverse 2>/dev/null | head -1 || git log -1 --pretty=format:"%s")

# コミットプレフィックスからラベルを決定
LABELS=""
if echo "$FIRST_COMMIT" | grep -q "^feat"; then
    LABELS="enhancement"
elif echo "$FIRST_COMMIT" | grep -q "^fix"; then
    LABELS="bug"
elif echo "$FIRST_COMMIT" | grep -q "^docs"; then
    LABELS="documentation"
elif echo "$FIRST_COMMIT" | grep -q "^refactor"; then
    LABELS="refactor"
elif echo "$FIRST_COMMIT" | grep -q "^test"; then
    LABELS="test"
elif echo "$FIRST_COMMIT" | grep -q "^chore"; then
    LABELS="chore"
elif echo "$FIRST_COMMIT" | grep -q "^hotfix"; then
    LABELS="bug,urgent"
fi

# 差分統計を取得
DIFF_STAT=$(git diff origin/$BASE_BRANCH --stat 2>/dev/null | tail -3 || echo "変更統計取得不可")

# リポジトリ情報
REPO_URL=$(git remote get-url origin 2>/dev/null || echo "unknown")

# PR本文を生成（テンプレート準拠）
BODY="## 概要
$FIRST_COMMIT

## 変更内容
$COMMITS

## 差分ハイライト
\`\`\`
$DIFF_STAT
\`\`\`

## 自動実行ログ
- ブランチ: \`$BRANCH\` → \`$BASE_BRANCH\`
- リポジトリ: $REPO_URL

## 動作確認手順
- [ ] ローカルで動作確認済み
- [ ] 本番環境で確認済み

## チェックリスト
- [ ] テスト/ビルドが通っている
- [ ] 変更が1つの目的にまとまっている
- [ ] セキュリティに影響する変更はない
- [ ] 必要なテストを追加した
"

# PRタイトル（最初のコミットメッセージ）
TITLE="$FIRST_COMMIT"

# PRを作成
echo "📋 PR作成中..."
echo "---"
echo "Title: $TITLE"
echo "Base: $BASE_BRANCH ← $BRANCH"
echo "Labels: ${LABELS:-none}"
echo "---"

PR_ARGS=(--title "$TITLE" --body "$BODY" --base "$BASE_BRANCH")

if [ -n "$LABELS" ]; then
    PR_ARGS+=(--label "$LABELS")
fi

if [ "$DRAFT" = true ]; then
    PR_ARGS+=(--draft)
fi

gh pr create "${PR_ARGS[@]}"

# 自動マージ（オプション指定時のみ）
if [ "$AUTO_MERGE" = true ]; then
    echo ""
    echo "⚠️  警告: 自動マージが有効です。ポリシーではPR確認後のマージを推奨しています。"
    echo "Auto-merging..."
    gh pr merge --squash --auto
fi

echo ""
echo "✅ Done!"
echo ""
echo "📋 次の推奨アクション:"
echo "  1. PRの内容を確認: gh pr view --web"
echo "  2. マージ: gh pr merge --squash"
