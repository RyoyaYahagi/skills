#!/bin/bash

# タスク単位で Git worktree を自動作成・再利用するスクリプト
#
# 使い方: ./scripts/auto-worktree.sh [type] [description] [issue-number]
# 引数:
#   type         - ブランチ種別 (feature|fix|refactor|docs|test|chore|hotfix) デフォルト: feature
#   description  - タスク説明 (ブランチ名の short-desc に使用) デフォルト: task
#   issue-number - Issue番号（オプション）
#
# 環境変数:
#   GIT_WORKTREE_ROOT - worktree作成先ルート（デフォルト: ../wt/<repo名>）

set -euo pipefail

TYPE="${1:-feature}"
DESC="${2:-task}"
ISSUE="${3:-}"

VALID_TYPES="feature fix refactor docs test chore hotfix"
if ! echo "$VALID_TYPES" | grep -qw "$TYPE"; then
    echo "⚠️  警告: 不明なtype '$TYPE'. 有効なtype: $VALID_TYPES"
    echo "    'feature'として続行します"
    TYPE="feature"
fi

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [ -z "$REPO_ROOT" ]; then
    echo "❌ エラー: Gitリポジトリではありません"
    exit 1
fi
cd "$REPO_ROOT"

CURRENT=$(git branch --show-current 2>/dev/null || true)
if [ -z "$CURRENT" ]; then
    echo "❌ エラー: 現在のブランチを判定できません"
    exit 1
fi

safe_slug() {
    local raw="$1"
    local slug
    slug=$(echo "$raw" \
        | tr '[:upper:]' '[:lower:]' \
        | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')
    if [ -z "$slug" ]; then
        slug="task"
    fi
    echo "$slug"
}

detect_base_branch() {
    local candidate
    for candidate in develop main master; do
        if git show-ref --verify --quiet "refs/heads/$candidate"; then
            echo "$candidate"
            return
        fi
        if git show-ref --verify --quiet "refs/remotes/origin/$candidate"; then
            echo "$candidate"
            return
        fi
    done
    echo "$CURRENT"
}

find_existing_worktree_path() {
    local branch_ref="refs/heads/$1"
    local current_path=""
    local line=""
    while IFS= read -r line; do
        case "$line" in
            worktree\ *)
                current_path="${line#worktree }"
                ;;
            branch\ *)
                if [ "${line#branch }" = "$branch_ref" ]; then
                    echo "$current_path"
                    return 0
                fi
                ;;
        esac
    done < <(git worktree list --porcelain)
    return 1
}

if [[ "$CURRENT" =~ ^(main|master|develop)$ ]]; then
    DATE=$(date +%Y%m%d)
    SAFE_DESC=$(safe_slug "$DESC")

    if [ -n "$ISSUE" ]; then
        BRANCH="${TYPE}/${ISSUE}-${SAFE_DESC}"
    else
        BRANCH="${TYPE}/${DATE}-${SAFE_DESC}"
    fi
else
    BRANCH="$CURRENT"
fi

if EXISTING_PATH=$(find_existing_worktree_path "$BRANCH"); then
    echo "✅ 既存worktreeを再利用します"
    echo "BRANCH=$BRANCH"
    echo "WORKTREE_PATH=$EXISTING_PATH"
    exit 0
fi

REPO_NAME=$(basename "$REPO_ROOT")
WORKTREE_ROOT_INPUT="${GIT_WORKTREE_ROOT:-../wt/${REPO_NAME}}"
mkdir -p "$WORKTREE_ROOT_INPUT"
WORKTREE_ROOT=$(cd "$WORKTREE_ROOT_INPUT" && pwd)

SAFE_BRANCH_DIR=$(echo "$BRANCH" | tr '/' '-')
WORKTREE_PATH="${WORKTREE_ROOT}/${SAFE_BRANCH_DIR}"

if [ -e "$WORKTREE_PATH" ] && [ -n "$(ls -A "$WORKTREE_PATH" 2>/dev/null || true)" ]; then
    echo "❌ エラー: 作成先ディレクトリが既に存在し、空ではありません: $WORKTREE_PATH"
    exit 1
fi

if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
    git worktree add "$WORKTREE_PATH" "$BRANCH"
else
    BASE_BRANCH=$(detect_base_branch)
    git worktree add -b "$BRANCH" "$WORKTREE_PATH" "$BASE_BRANCH"
fi

echo "✅ worktreeを作成しました"
echo "BRANCH=$BRANCH"
echo "WORKTREE_PATH=$WORKTREE_PATH"
