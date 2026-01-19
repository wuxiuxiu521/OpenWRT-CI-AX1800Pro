#!/bin/bash

# 智能同步脚本 - 集成到现有编译流程
# 这个脚本会被WRT-CORE.yml调用，替代原来的直接feeds update

# 设置环境变量
WRT_REPO="${WRT_REPO:-}"
WRT_BRANCH="${WRT_BRANCH:-}"
WRT_SOURCE="${WRT_SOURCE:-}"
GITHUB_WORKSPACE="${GITHUB_WORKSPACE:-$PWD}"

# 同步缓存目录
SYNC_CACHE_DIR="$GITHUB_WORKSPACE/.sync_cache"
mkdir -p "$SYNC_CACHE_DIR"

# 智能检测是否需要完整同步
should_full_sync() {
    local cache_file="$SYNC_CACHE_DIR/last_full_sync"
    local current_time=$(date +%s)
    
    # 如果没有缓存文件，需要完整同步
    if [ ! -f "$cache_file" ]; then
        return 0
    fi
    
    # 读取上次同步时间
    local last_sync=$(cat "$cache_file")
    local time_diff=$((current_time - last_sync))
    
    # 24小时内不强制完整同步（除非上游有更新）
    if [ $time_diff -lt 86400 ]; then
        return 1
    fi
    
    return 0
}

# 增量更新feeds
incremental_feeds_update() {
    log_info "执行增量feeds更新..."
    
    cd ./wrt/
    
    # 检查feeds.conf是否有变化
    if [ -f "./feeds.conf" ]; then
        local feeds_hash=$(sha256sum "./feeds.conf" | cut -d' ' -f1)
        local cache_file="$SYNC_CACHE_DIR/feeds_hash"
        
        if [ -f "$cache_file" ]; then
            local old_hash=$(cat "$cache_file")
            if [ "$feeds_hash" = "$old_hash" ]; then
                log_info "feeds.conf无变化，跳过feeds update"
                # 仍然执行install以确保依赖完整
                ./scripts/feeds install -a
                return 0
            fi
        fi
        
        echo "$feeds_hash" > "$cache_file"
    fi
    
    # 执行feeds更新
    ./scripts/feeds update -a
    ./scripts/feeds install -a
    
    # 记录同步时间
    date +%s > "$SYNC_CACHE_DIR/last_full_sync"
}

# 智能包更新
smart_package_update() {
    log_info "执行智能包更新..."
    
    cd ./wrt/package/
    
    # 读取需要更新的包列表
    local packages_sh="$GITHUB_WORKSPACE/Scripts/Packages.sh"
    
    if [ ! -f "$packages_sh" ]; then
        log_error "Packages.sh不存在"
        return 1
    fi
    
    # 解析包定义并检查本地是否存在
    while IFS= read -r line; do
        if [[ "$line" =~ UPDATE_PACKAGE\ \"([^\"]+)\"\ \"([^\"]+)\"\ \"([^\"]+)\" ]]; then
            local pkg_name="${BASH_REMATCH[1]}"
            local pkg_repo="${BASH_REMATCH[2]}"
            local pkg_branch="${BASH_REMATCH[3]}"
            
            # 检查本地包目录是否存在
            if [ -d "./$pkg_name" ]; then
                # 检查是否有本地修改
                cd "./$pkg_name"
                if git status --porcelain | grep -q .; then
                    log_info "包 $pkg_name 有本地修改，跳过更新"
                    cd ..
                    continue
                fi
                
                # 检查远程是否有更新
                local cache_file="$SYNC_CACHE_DIR/pkg_${pkg_name}_commit"
                local remote_commit=$(git ls-remote "https://github.com/$pkg_repo.git" "refs/heads/$pkg_branch" 2>/dev/null | cut -f1)
                
                if [ -f "$cache_file" ]; then
                    local local_commit=$(cat "$cache_file")
                    if [ "$remote_commit" != "$local_commit" ]; then
                        log_info "包 $pkg_name 有更新，执行更新..."
                        git fetch origin
                        git reset --hard "origin/$pkg_branch"
                        echo "$remote_commit" > "$cache_file"
                    else
                        log_info "包 $pkg_name 已是最新"
                    fi
                else
                    echo "$remote_commit" > "$cache_file"
                fi
                
                cd ..
            else
                log_info "包 $pkg_name 不存在，将在Packages.sh中处理"
            fi
        fi
    done < "$packages_sh"
}

# 缓存管理
cache_management() {
    log_info "执行缓存管理..."
    
    # 清理超过7天的缓存文件
    find "$SYNC_CACHE_DIR" -type f -mtime +7 -delete 2>/dev/null
    
    # 显示缓存使用情况
    local cache_size=$(du -sh "$SYNC_CACHE_DIR" 2>/dev/null | cut -f1)
    log_info "缓存大小: $cache_size"
}

# 日志函数
log_info() {
    echo "[SmartSync] $1"
}

log_warn() {
    echo "[SmartSync][WARN] $1"
}

log_error() {
    echo "[SmartSync][ERROR] $1"
}

# 主函数
main() {
    log_info "智能同步开始"
    
    # 检查是否需要完整同步
    if should_full_sync; then
        log_info "需要执行完整同步"
        ./Scripts/SyncHook.sh force
    else
        log_info "执行增量同步"
        
        # 增量更新feeds
        incremental_feeds_update
        
        # 智能更新包
        smart_package_update
        
        # 缓存管理
        cache_management
        
        log_info "增量同步完成"
    fi
    
    log_info "智能同步结束"
}

# 如果直接执行此脚本
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main
fi