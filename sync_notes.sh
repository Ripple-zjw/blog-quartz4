#!/usr/bin/env bash

set -e

#############################################
# 读取 SOURCE_DIR 和 TARGET_DIR
#############################################

# 如果用户通过参数传入，就使用参数
if [ -n "$1" ]; then
    SOURCE_DIR="$1"
fi

if [ -n "$2" ]; then
    TARGET_DIR="$2"
fi

# 如果参数为空，则尝试从环境变量读取
SOURCE_DIR="${SOURCE_DIR:-$SOURCE_DIR_ENV}"
TARGET_DIR="${TARGET_DIR:-$TARGET_DIR_ENV}"

# 如果还没有内容，提示用户
if [ -z "$SOURCE_DIR" ] || [ -z "$TARGET_DIR" ]; then
    echo "用法："
    echo "  ./sync_notes.sh <SOURCE_DIR> <TARGET_DIR>"
    echo "或者提前设定环境变量："
    echo "  export SOURCE_DIR_ENV=/mnt/c/Users/.../Notes"
    echo "  export TARGET_DIR_ENV=~/obsidian-notes"
    exit 1
fi

#############################################
# 校验目录是否存在
#############################################
if [ ! -d "$SOURCE_DIR" ]; then
    echo "源目录不存在: $SOURCE_DIR"
    exit 1
fi

mkdir -p "$TARGET_DIR"


#############################################
# 开始同步 (带进度条 + 保留所有元数据)
#############################################

echo "开始同步："
echo "  从: $SOURCE_DIR"
echo "  到:   $TARGET_DIR"
echo ""

rsync -a \
      --info=progress2 \
      --delete \
      "$SOURCE_DIR"/ \
      "$TARGET_DIR"/

echo ""
echo "同步完成！"


