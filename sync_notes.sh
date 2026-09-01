#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_NAME="${0##*/}"
readonly REQUIRED_RSYNC_VERSION="3.5.0"
readonly REQUIRED_RSYNC_MAJOR=3
readonly REQUIRED_RSYNC_MINOR=5
readonly REQUIRED_RSYNC_PATCH=0

DRY_RUN=false
ASSUME_YES=false
ALLOW_EMPTY_SOURCE=false
DELETE_EXTRA=true

usage() {
    printf '%s\n' \
        "用法：" \
        "  ./$SCRIPT_NAME [选项] [SOURCE_DIR] [TARGET_DIR]" \
        "" \
        "选项：" \
        "  --dry-run             只预览，不修改目标目录" \
        "  --yes, -y             确认执行删除操作（适用于自动化）" \
        "  --no-delete            不删除目标目录中的多余文件" \
        "  --allow-empty-source   允许空源目录镜像到目标目录" \
        "  --help, -h             显示帮助" \
        "" \
        "也可以使用环境变量：" \
        "  export SOURCE_DIR_ENV=/mnt/c/Users/.../Notes" \
        "  export TARGET_DIR_ENV=~/obsidian-notes" \
        "" \
        "脚本要求 rsync >= ${REQUIRED_RSYNC_VERSION}。"
}

die() {
    printf '错误：%s\n' "$*" >&2
    exit 1
}

while (($# > 0)); do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            ;;
        --yes|-y)
            ASSUME_YES=true
            ;;
        --no-delete)
            DELETE_EXTRA=false
            ;;
        --allow-empty-source)
            ALLOW_EMPTY_SOURCE=true
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -* )
            printf '未知选项：%s\n\n' "$1" >&2
            usage >&2
            exit 2
            ;;
        *)
            break
            ;;
    esac
    shift
done

if (($# > 2)); then
    printf '参数过多。\n\n' >&2
    usage >&2
    exit 2
fi

#############################################
# 读取 SOURCE_DIR 和 TARGET_DIR
#############################################

# 如果用户通过参数传入，就使用参数；否则兼容原有环境变量
if (($# >= 1)); then
    SOURCE_DIR="$1"
else
    SOURCE_DIR="${SOURCE_DIR:-${SOURCE_DIR_ENV:-}}"
fi

if (($# == 2)); then
    TARGET_DIR="$2"
else
    TARGET_DIR="${TARGET_DIR:-${TARGET_DIR_ENV:-}}"
fi

# 如果还没有内容，提示用户
if [[ -z "$SOURCE_DIR" || -z "$TARGET_DIR" ]]; then
    usage >&2
    exit 2
fi

#############################################
# 校验 rsync 版本
#############################################

# Homebrew 的 rsync 可能排在 macOS 自带 rsync 后面，优先使用已安装的 Homebrew 版本。
RSYNC_BIN="${RSYNC_BIN:-}"
if [[ -z "$RSYNC_BIN" ]] && command -v brew >/dev/null 2>&1; then
    if BREW_RSYNC_PREFIX="$(brew --prefix rsync 2>/dev/null)"; then
        if [[ -x "$BREW_RSYNC_PREFIX/bin/rsync" ]]; then
            RSYNC_BIN="$BREW_RSYNC_PREFIX/bin/rsync"
        fi
    fi
fi

if [[ -z "$RSYNC_BIN" ]]; then
    RSYNC_BIN="$(command -v rsync || true)"
fi

if [[ -z "$RSYNC_BIN" ]]; then
    die "找不到 rsync，请安装 rsync $REQUIRED_RSYNC_VERSION 或更高版本。"
fi

if ! RSYNC_VERSION_OUTPUT="$("$RSYNC_BIN" --version 2>&1)"; then
    die "无法执行 rsync：$RSYNC_BIN"
fi

if [[ ! "$RSYNC_VERSION_OUTPUT" =~ rsync[[:space:]]+version[[:space:]]+([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
    die "无法解析 rsync 版本：$RSYNC_VERSION_OUTPUT"
fi

RSYNC_MAJOR="${BASH_REMATCH[1]}"
RSYNC_MINOR="${BASH_REMATCH[2]}"
RSYNC_PATCH="${BASH_REMATCH[3]}"
RSYNC_VERSION="$RSYNC_MAJOR.$RSYNC_MINOR.$RSYNC_PATCH"

if ((
    RSYNC_MAJOR < REQUIRED_RSYNC_MAJOR ||
    (RSYNC_MAJOR == REQUIRED_RSYNC_MAJOR && RSYNC_MINOR < REQUIRED_RSYNC_MINOR) ||
    (RSYNC_MAJOR == REQUIRED_RSYNC_MAJOR && RSYNC_MINOR == REQUIRED_RSYNC_MINOR && RSYNC_PATCH < REQUIRED_RSYNC_PATCH)
)); then
    die "rsync 版本过旧：${RSYNC_VERSION}，需要 >= ${REQUIRED_RSYNC_VERSION}。"
fi

#############################################
# 校验目录是否存在及是否重叠
#############################################
if [[ ! -d "$SOURCE_DIR" ]]; then
    die "源目录不存在：$SOURCE_DIR"
fi

if [[ "$TARGET_DIR" == -* ]]; then
    die "目标目录不能以 - 开头，请改用 ./ 开头的相对路径。"
fi

if [[ ( -e "$TARGET_DIR" || -L "$TARGET_DIR" ) && ! -d "$TARGET_DIR" ]]; then
    die "目标路径不是目录：$TARGET_DIR"
fi

if [[ "$DRY_RUN" == true && ! -d "$TARGET_DIR" ]]; then
    die "预览模式不会创建目录，请先创建目标目录：$TARGET_DIR"
fi

mkdir -p "$TARGET_DIR"

SOURCE_REALPATH="$(cd -P -- "$SOURCE_DIR" && pwd -P)"
TARGET_REALPATH="$(cd -P -- "$TARGET_DIR" && pwd -P)"

is_same_or_child() {
    local path="$1"
    local parent="$2"

    [[ "$path" == "$parent" || "$parent" == "/" || "$path" == "$parent/"* ]]
}

if is_same_or_child "$SOURCE_REALPATH" "$TARGET_REALPATH" || \
   is_same_or_child "$TARGET_REALPATH" "$SOURCE_REALPATH"; then
    die "源目录和目标目录不能相同或互相包含：$SOURCE_REALPATH <-> $TARGET_REALPATH"
fi

if [[ "$DELETE_EXTRA" == true && "$DRY_RUN" == false && "$ALLOW_EMPTY_SOURCE" == false ]]; then
    if ! SOURCE_FIRST_ENTRY="$(find "$SOURCE_REALPATH" -mindepth 1 -maxdepth 1 -print -quit)"; then
        die "无法读取源目录：$SOURCE_REALPATH"
    fi

    if [[ -z "$SOURCE_FIRST_ENTRY" ]]; then
        die "源目录为空。为防止清空目标目录，请确认路径，或使用 --allow-empty-source。"
    fi
fi


#############################################
# 开始同步
#############################################

printf '%s\n' "开始同步：" \
    "  从：$SOURCE_REALPATH" \
    "  到：$TARGET_REALPATH" \
    "  rsync：$RSYNC_BIN ($RSYNC_VERSION)"

if [[ "$DELETE_EXTRA" == true ]]; then
    printf '%s\n' "警告：目标目录中源目录没有的文件将被删除。"
fi

if [[ "$DRY_RUN" == true ]]; then
    printf '%s\n' "预览模式：不会修改目标目录。"
elif [[ "$DELETE_EXTRA" == true && "$ASSUME_YES" == false ]]; then
    if [[ ! -t 0 ]]; then
        die "同步会删除目标文件。非交互执行时请先使用 --dry-run，确认后再加 --yes。"
    fi

    printf '%s' "继续执行？请输入 yes："
    CONFIRMATION=""
    if ! read -r CONFIRMATION; then
        die "未读取到确认内容，已取消。"
    fi
    if [[ "$CONFIRMATION" != "yes" ]]; then
        printf '%s\n' "已取消。"
        exit 0
    fi
fi

RSYNC_ARGS=(-a --info=progress2)
if [[ "$DELETE_EXTRA" == true ]]; then
    RSYNC_ARGS+=(--delete)
fi
if [[ "$DRY_RUN" == true ]]; then
    RSYNC_ARGS+=(--dry-run --itemize-changes)
fi

"$RSYNC_BIN" "${RSYNC_ARGS[@]}" -- "$SOURCE_DIR"/ "$TARGET_DIR"/

printf '%s\n' "" "同步完成！"
