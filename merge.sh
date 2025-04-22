#!/bin/bash

# 设置错误时退出
set -e

# 定义颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 默认分支名称
FEATURE_BRANCH="feature/jp_dev"
DEVELOP_BRANCH="develop"

# 显示执行状态的函数
show_status() {
    echo -e "${GREEN}$1${NC}"
}

# 错误处理函数
handle_error() {
    echo -e "${RED}错误: $1${NC}"
    exit 1
}

# 检查是否有未提交的更改
if ! git diff-index --quiet HEAD --; then
    handle_error "有未提交的更改，请先提交或存储您的更改"
fi

# 切换到develop分支并更新
show_status "切换到 ${DEVELOP_BRANCH} 分支..."
git checkout ${DEVELOP_BRANCH} || handle_error "无法切换到 ${DEVELOP_BRANCH} 分支"

show_status "拉取最新的 ${DEVELOP_BRANCH} 更新..."
git pull || handle_error "无法拉取 ${DEVELOP_BRANCH} 的更新"

# 切换到特性分支
show_status "切换到 ${FEATURE_BRANCH} 分支..."
git checkout ${FEATURE_BRANCH} || handle_error "无法切换到 ${FEATURE_BRANCH} 分支"

# 合并develop分支
show_status "合并 ${DEVELOP_BRANCH} 到 ${FEATURE_BRANCH}..."
git merge ${DEVELOP_BRANCH} || handle_error "合并过程中发生冲突"

# 推送更新到远程仓库
show_status "推送 ${FEATURE_BRANCH} 到远程仓库..."
git push origin ${FEATURE_BRANCH} || handle_error "推送到远程仓库失败"

show_status "完成！成功将 ${DEVELOP_BRANCH} 合并到 ${FEATURE_BRANCH} 并推送到远程仓库"