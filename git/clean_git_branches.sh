#!/bin/bash

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Git 已合并分支清理工具 ===${NC}"

# 获取当前所在分支
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ -z "$CURRENT_BRANCH" ]; then
    echo -e "${RED}错误：无法获取当前分支。请确保您在 Git 仓库中。${NC}"
    exit 1
fi
echo -e "${YELLOW}当前所在分支：${CURRENT_BRANCH}${NC}"
echo -e "${YELLOW}脚本将检查并删除已合并到此分支的分支。${NC}"

echo -e "\n${BLUE}--- 1. 获取最新远程信息并清理过期的远程跟踪分支 ---${NC}"
echo -e "${YELLOW}执行 'git fetch --prune origin' ...${NC}"
# 远程仓库已经删除的分支，在本地也会被移除
git fetch --prune origin
if [ $? -ne 0 ]; then
    echo -e "${RED}错误：git fetch --prune origin 失败。请检查您的网络连接或 Git 配置。${NC}"
    exit 1
fi
echo -e "${GREEN}远程信息已更新并清理。${NC}"

echo -e "\n${BLUE}--- 2. 查找已合并的本地分支 ---${NC}"
# 查找除了当前分支和 master/develop 外的所有已合并本地分支

# 排除 master 和 develop 是为了避免误删主要分支
MERGED_LOCAL_BRANCHES=$(git branch --merged | grep -v "$CURRENT_BRANCH" | grep -v "master$" | grep -v "develop$" | sed 's/^[[:space:]]*//')

if [ -z "$MERGED_LOCAL_BRANCHES" ]; then
    echo -e "${GREEN}没有找到可以删除的已合并本地分支（排除当前分支、master和develop）。${NC}"
else
    echo -e "${YELLOW}以下是已合并到 ${CURRENT_BRANCH} 的本地分支（不包括 ${CURRENT_BRANCH}、master、develop）：${NC}"
    echo -e "${MERGED_LOCAL_BRANCHES}"
    echo -e "\n${RED}警告：删除这些分支将移除本地的所有相关提交。${NC}"
    read -p "$(echo -e "${YELLOW}是否删除这些本地分支？ (y/N): ${NC}")" confirm_local_delete
    if [[ "$confirm_local_delete" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}正在删除本地分支...${NC}"
        for branch in $MERGED_LOCAL_BRANCHES; do
            echo -e "${YELLOW}删除本地分支：$branch${NC}"
            git branch -d "$branch"
            if [ $? -ne 0 ]; then
                echo -e "${RED}错误：无法删除本地分支 '$branch'。可能它有未合并的更改，请手动处理或使用 'git branch -D $branch' 强制删除。${NC}"
            fi
        done
        echo -e "${GREEN}本地分支删除完成。${NC}"
    else
        echo -e "${BLUE}跳过本地分支删除。${NC}"
    fi
fi

echo -e "\n${BLUE}--- 3. 查找已合并的远程跟踪分支 ---${NC}"
# 查找除了远程的 master 和 develop 外的所有已合并远程跟踪分支
# 注意：这里查找的是本地的远程跟踪分支，代表远程仓库中已合并的分支
MERGED_REMOTE_TRACKING_BRANCHES=$(git branch -r --merged | grep 'origin/' | grep -v 'origin/HEAD' | grep -v 'origin/master$' | grep -v 'origin/develop$' | sed 's/^[[:space:]]*origin\///')

if [ -z "$MERGED_REMOTE_TRACKING_BRANCHES" ]; then
    echo -e "${GREEN}没有找到可以删除的已合并远程跟踪分支（排除 origin/master 和 origin/develop）。${NC}"
else
    echo -e "${YELLOW}以下是已合并到 ${CURRENT_BRANCH} 的远程分支（通过本地的远程跟踪分支显示，不包括 origin/master 和 origin/develop）：${NC}"
    echo -e "${MERGED_REMOTE_TRACKING_BRANCHES}"
    echo -e "\n${RED}警告：删除这些分支将从远程仓库中移除它们，这是一个不可逆的操作！${NC}"
    read -p "$(echo -e "${YELLOW}是否删除这些远程分支？ (y/N): ${NC}")" confirm_remote_delete
    if [[ "$confirm_remote_delete" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}正在删除远程分支...${NC}"
        for branch in $MERGED_REMOTE_TRACKING_BRANCHES; do
            echo -e "${YELLOW}删除远程分支：origin/$branch${NC}"
            git push origin --delete "$branch"
            if [ $? -ne 0 ]; then
                echo -e "${RED}错误：无法删除远程分支 'origin/$branch'。请检查您的权限或手动处理。${NC}"
            fi
        done
        echo -e "${GREEN}远程分支删除请求已发送。${NC}"
        echo -e "${BLUE}正在清理本地远程跟踪分支...${NC}"
        git fetch --prune origin
        echo -e "${GREEN}本地远程跟踪分支清理完成。${NC}"
    else
        echo -e "${BLUE}跳过远程分支删除。${NC}"
    fi
fi

echo -e "\n${BLUE}=== 清理完成 ===${NC}"