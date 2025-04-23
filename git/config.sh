#!/bin/bash

# 定义配置文件路径
CONFIG_FILE="$(dirname "$0")/conf.ini"

# 检查配置文件是否存在
if [ ! -f "$CONFIG_FILE" ]; then
    echo "错误: 配置文件不存在: $CONFIG_FILE"
    exit 1
fi

# 从 INI 文件读取分支配置
FEATURE_BRANCH=$(sed -n 's/^personal_branch[[:space:]]*=[[:space:]]*\(.*\)/\1/p' "$CONFIG_FILE")
DEVELOP_BRANCH=$(sed -n 's/^target_branch[[:space:]]*=[[:space:]]*\(.*\)/\1/p' "$CONFIG_FILE")

# 检查是否成功读取配置
if [ -z "$FEATURE_BRANCH" ] || [ -z "$DEVELOP_BRANCH" ]; then
    echo "错误: 无法从配置文件读取分支信息"
    exit 1
fi

# 获取当前使用的shell
current_shell=$(basename "$SHELL")

# 根据shell类型确定配置文件
if [ "$current_shell" = "zsh" ]; then
    config_file="$HOME/.zshrc"
elif [ "$current_shell" = "bash" ]; then
    config_file="$HOME/.bashrc"
else
    echo "不支持的shell类型: $current_shell"
    exit 1
fi

# 检查变量是否已存在，如果存在则删除
sed -i.bak "/^export FEATURE_BRANCH=/d" "$config_file"
sed -i.bak "/^export DEVELOP_BRANCH=/d" "$config_file"
sed -i.bak "/^alias merge=/d" "$config_file"

# 添加新的变量定义和别名
echo "" >> "$config_file"
echo "# Git branch configuration" >> "$config_file"
echo "export FEATURE_BRANCH=\"$FEATURE_BRANCH\"" >> "$config_file"
echo "export DEVELOP_BRANCH=\"$DEVELOP_BRANCH\"" >> "$config_file"
# merge -> merge.sh
echo "alias merge=\"$(cd "$(dirname "$0")" && pwd)/merge.sh\"" >> "$config_file"

# 删除备份文件
rm "${config_file}.bak"

echo "分支配置和别名已成功添加到 $config_file"
echo "请运行 'source $config_file' 使配置生效"