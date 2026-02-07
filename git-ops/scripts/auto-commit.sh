#!/bin/bash

# 自動ブランチ作成・コミットスクリプト
# どのプロジェクトでも使用可能
#
# 使い方: ./scripts/auto-commit.sh [type] [description] [issue-number]
# 引数:
#   type         - コミットタイプ (feature|fix|refactor|docs|test|chore|hotfix) デフォルト: feature
#   description  - 変更の短い説明 デフォルト: auto-commit
#   issue-number - Issue番号（オプション）

set -e

TYPE="${1:-feature}"
DESC="${2:-auto-commit}"
ISSUE="${3:-}"

# 有効なtypeを検証
VALID_TYPES="feature fix refactor docs test chore hotfix"
if ! echo "$VALID_TYPES" | grep -qw "$TYPE"; then
    echo "⚠️  警告: 不明なtype '$TYPE'. 有効なtype: $VALID_TYPES"
    echo "    'feature'として続行します"
    TYPE="feature"
fi

# 現在のブランチを確認
CURRENT=$(git branch --show-current 2>/dev/null || echo "")

if [ -z "$CURRENT" ]; then
    echo "❌ エラー: Gitリポジトリではありません"
    exit 1
fi

# ステージング確認
if [ -z "$(git status --porcelain)" ]; then
    echo "✅ コミットする変更がありません"
    exit 0
fi

# main/master/developなら新ブランチ作成
if [[ "$CURRENT" =~ ^(main|master|develop)$ ]]; then
    DATE=$(date +%Y%m%d)
    
    # descriptionをブランチ名に適した形式に変換（スペースをハイフンに、小文字化）
    SAFE_DESC=$(echo "$DESC" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
    
    if [ -n "$ISSUE" ]; then
        BRANCH="${TYPE}/${ISSUE}-${SAFE_DESC}"
    else
        BRANCH="${TYPE}/${DATE}-${SAFE_DESC}"
    fi
    
    # ブランチ名が既に存在する場合は連番を付ける
    ORIGINAL_BRANCH="$BRANCH"
    COUNTER=1
    while git show-ref --verify --quiet "refs/heads/$BRANCH" 2>/dev/null; do
        BRANCH="${ORIGINAL_BRANCH}-${COUNTER}"
        COUNTER=$((COUNTER + 1))
    done
    
    echo "📌 新しいブランチを作成: $BRANCH"
    git switch -c "$BRANCH"
    CURRENT="$BRANCH"
fi

# 変更をステージング
git add -A

# 変更統計を取得
CHANGED_FILES=$(git diff --cached --stat | tail -1)

# コミットメッセージ生成
if [ -n "$ISSUE" ]; then
    MSG="${TYPE}: ${DESC} (#${ISSUE})"
else
    MSG="${TYPE}: ${DESC}"
fi

# コミット実行（signoff付き）
git commit --signoff -m "$MSG"

echo ""
echo "✅ コミット完了"
echo "---"
echo "ブランチ: $CURRENT"
echo "メッセージ: $MSG"
echo "変更: $CHANGED_FILES"
echo "---"
echo ""
echo "📋 次の推奨アクション:"
echo "  1. 変更をpush: git push origin $CURRENT"
echo "  2. PR作成: ./scripts/pr.sh"
