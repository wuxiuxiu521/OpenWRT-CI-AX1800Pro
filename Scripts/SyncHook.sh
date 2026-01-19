#!/bin/bash

# Hook式同步机制 - 智能检测上游变化并增量同步
# 用法: ./SyncHook.sh [force|check|clean]

SYNC_MODE="${1:-check}"
WRT_REPO="${WRT_REPO:-}"
WRT_BRANCH="${WRT_BRANCH:-}"
WRT_SOURCE="${WRT_SOURCE:-}"

# 同步状态文件
SYNC_STATE_DIR="./.sync_state"
SYNC_STATE_FILE="$SYNC_STATE_DIR/state.json"
SYNC_CACHE_DIR="./.sync_cache"

# 创建同步状态目录
mkdir -p "$SYNC_STATE_DIR"
mkdir -p "$SYNC_CACHE_DIR"

# 日志函数
log_info() {
    echo "[INFO] $1"
}

log_warn() {
    echo "[WARN] $1"
}

log_error() {
    echo "[ERROR] $1"
}

# 检测上游是否有更新
check_upstream_update() {
    local repo_url="$1"
    local branch="$2"
    local cache_key="$3"
    
    if [ -z "$repo_url" ] || [ -z "$branch" ]; then
        log_error "Repository URL or branch is empty"
        return 1
    fi
    
    # 获取远程最新提交
    local remote_commit=$(git ls-remote "$repo_url" "refs/heads/$branch" 2>/dev/null | cut -f1)
    if [ -z "$remote_commit" ]; then
        log_warn "无法获取远程仓库信息: $repo_url"
        return 2
    fi
    
    # 检查本地缓存
    local cache_file="$SYNC_CACHE_DIR/$cache_key.commit"
    local local_commit=""
    
    if [ -f "$cache_file" ]; then
        local_commit=$(cat "$cache_file")
    fi
    
    # 比较提交
    if [ "$remote_commit" != "$local_commit" ]; then
        log_info "检测到上游更新: $repo_url ($branch)"
        echo "$remote_commit" > "$cache_file"
        return 0
    else
        log_info "上游无更新: $repo_url ($branch)"
        return 1
    fi
}

# 同步OpenWRT主源码
sync_openwrt_source() {
    log_info "开始同步OpenWRT源码..."
    
    if [ -z "$WRT_REPO" ] || [ -z "$WRT_BRANCH" ]; then
        log_error "WRT_REPO或WRT_BRANCH未设置"
        return 1
    fi
    
    local cache_key="openwrt_${WRT_SOURCE}_${WRT_BRANCH}"
    
    # 检查是否需要同步
    if [ "$SYNC_MODE" != "force" ]; then
        if ! check_upstream_update "$WRT_REPO" "$WRT_BRANCH" "$cache_key"; then
            log_info "源码无需更新，跳过同步"
            return 0
        fi
    fi
    
    # 执行同步
    if [ -d "./wrt" ]; then
        cd ./wrt/
        
        # 检查是否是同一个仓库
        local current_repo=$(git config --get remote.origin.url)
        if [ "$current_repo" = "$WRT_REPO" ]; then
            log_info "执行增量更新..."
            git fetch origin
            git reset --hard "origin/$WRT_BRANCH"
            git clean -fd
        else
            log_warn "仓库地址变更，重新克隆..."
            cd ..
            rm -rf ./wrt
            git clone --depth=1 --single-branch --branch "$WRT_BRANCH" "$WRT_REPO" ./wrt/
        fi
    else
        log_info "首次克隆源码..."
        git clone --depth=1 --single-branch --branch "$WRT_BRANCH" "$WRT_REPO" ./wrt/
    fi
    
    # 更新状态
    update_sync_state "openwrt" "$WRT_REPO" "$WRT_BRANCH"
    log_info "OpenWRT源码同步完成"
}

# 同步Feeds
sync_feeds() {
    log_info "开始同步Feeds..."
    
    if [ ! -d "./wrt" ]; then
        log_error "wrt目录不存在"
        return 1
    fi
    
    cd ./wrt/
    
    # 检查feeds.conf是否存在
    if [ ! -f "./feeds.conf" ]; then
        log_error "feeds.conf不存在"
        return 1
    fi
    
    # 解析feeds配置并检查更新
    local needs_update=false
    
    while IFS= read -r line; do
        # 跳过注释和空行
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue
        
        # 解析feeds配置
        if [[ "$line" =~ ^src-[^[:space:]]+[[:space:]]+([^[:space:]]+)[[:space:]]+([^[:space:]]+)[[:space:]]+(.*)$ ]]; then
            local feed_name="${BASH_REMATCH[1]}"
            local feed_repo="${BASH_REMATCH[2]}"
            local feed_branch="${BASH_REMATCH[3]}"
            
            local cache_key="feed_${feed_name}"
            
            if [ "$SYNC_MODE" = "force" ] || check_upstream_update "$feed_repo" "$feed_branch" "$cache_key"; then
                needs_update=true
            fi
        fi
    done < "./feeds.conf"
    
    if [ "$needs_update" = "false" ] && [ "$SYNC_MODE" != "force" ]; then
        log_info "所有Feeds均为最新，跳过更新"
        return 0
    fi
    
    # 执行feeds更新
    log_info "执行feeds更新..."
    ./scripts/feeds update -a
    
    # 更新状态
    update_sync_state "feeds" "all" "all"
    log_info "Feeds同步完成"
}

# 同步自定义软件包
sync_custom_packages() {
    log_info "开始同步自定义软件包..."
    
    if [ ! -d "./wrt/package" ]; then
        log_error "wrt/package目录不存在"
        return 1
    fi
    
    cd ./wrt/package/
    
    # 读取Packages.sh中的包定义并检查更新
    local packages_sh="$GITHUB_WORKSPACE/Scripts/Packages.sh"
    
    if [ ! -f "$packages_sh" ]; then
        log_error "Packages.sh不存在"
        return 1
    fi
    
    # 解析UPDATE_PACKAGE调用
    grep -E "^UPDATE_PACKAGE\s+" "$packages_sh" | while IFS= read -r line; do
        # 提取包信息
        if [[ "$line" =~ UPDATE_PACKAGE\ \"([^\"]+)\"\ \"([^\"]+)\"\ \"([^\"]+)\" ]]; then
            local pkg_name="${BASH_REMATCH[1]}"
            local pkg_repo="${BASH_REMATCH[2]}"
            local pkg_branch="${BASH_REMATCH[3]}"
            
            local cache_key="pkg_${pkg_name}"
            
            # 检查是否需要更新
            if [ "$SYNC_MODE" = "force" ] || check_upstream_update "https://github.com/$pkg_repo.git" "$pkg_branch" "$cache_key"; then
                log_info "需要更新包: $pkg_name"
                # 这里可以触发具体的更新逻辑
                # 实际更新在Packages.sh中处理
            fi
        fi
    done
    
    # 更新状态
    update_sync_state "packages" "custom" "all"
    log_info "自定义软件包检查完成"
}

# 更新同步状态
update_sync_state() {
    local type="$1"
    local repo="$2"
    local branch="$3"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # 读取现有状态
    local state_json="{}"
    if [ -f "$SYNC_STATE_FILE" ]; then
        state_json=$(cat "$SYNC_STATE_FILE")
    fi
    
    # 更新状态 (使用jq如果可用，否则使用简单方式)
    if command -v jq &> /dev/null; then
        local updated=$(echo "$state_json" | jq --arg type "$type" --arg repo "$repo" --arg branch "$branch" --arg ts "$timestamp" \
            '. + {($type): {repo: $repo, branch: $branch, last_sync: $ts}}')
        echo "$updated" > "$SYNC_STATE_FILE"
    else
        # 简单JSON格式
        echo "{\"$type\": {\"repo\": \"$repo\", \"branch\": \"$branch\", \"last_sync\": \"$timestamp\"}}" > "$SYNC_STATE_FILE"
    fi
}

# 清理同步缓存
clean_sync_cache() {
    log_info "清理同步缓存..."
    rm -rf "$SYNC_CACHE_DIR"
    rm -rf "$SYNC_STATE_DIR"
    mkdir -p "$SYNC_CACHE_DIR"
    mkdir -p "$SYNC_STATE_DIR"
    log_info "缓存清理完成"
}

# 显示同步状态
show_sync_status() {
    log_info "当前同步状态:"
    
    if [ -f "$SYNC_STATE_FILE" ]; then
        cat "$SYNC_STATE_FILE"
    else
        echo "无同步状态记录"
    fi
    
    echo ""
    echo "缓存文件:"
    ls -la "$SYNC_CACHE_DIR" 2>/dev/null || echo "无缓存文件"
}

# 主函数
main() {
    log_info "Hook式同步机制启动 - 模式: $SYNC_MODE"
    
    case "$SYNC_MODE" in
        "force")
            log_info "强制同步模式"
            sync_openwrt_source
            sync_feeds
            sync_custom_packages
            ;;
        "check")
            log_info "检查更新模式"
            sync_openwrt_source
            sync_feeds
            sync_custom_packages
            ;;
        "clean")
            clean_sync_cache
            ;;
        "status")
            show_sync_status
            ;;
        *)
            log_error "未知模式: $SYNC_MODE"
            echo "用法: $0 [force|check|clean|status]"
            exit 1
            ;;
    esac
    
    log_info "Hook式同步机制完成"
}

# 执行主函数
main