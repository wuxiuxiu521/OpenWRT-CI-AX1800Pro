# Hook式同步机制说明

## 概述

Hook式同步机制是一个智能的自动化同步系统，旨在减少每次编译时都需要手动同步上游源码的繁琐操作。通过增量更新、智能检测和缓存策略，大幅提高编译效率。

## 核心组件

### 1. SyncHook.sh
主同步脚本，提供多种同步模式：
- `force` - 强制完整同步
- `check` - 检查更新并增量同步
- `clean` - 清理同步缓存
- `status` - 显示同步状态

### 2. SmartSync.sh
智能同步脚本，集成到现有编译流程：
- 自动检测是否需要完整同步（24小时周期）
- 增量更新feeds
- 智能更新自定义软件包
- 缓存管理

### 3. Sync-Hook.yml
独立的GitHub Actions工作流：
- 每天凌晨2点自动检查上游更新
- 仅在有更新时触发同步
- 更新README中的同步状态

## 工作原理

### 智能检测机制
```
1. 检查本地缓存的上游提交哈希
2. 通过git ls-remote获取远程最新提交
3. 比较哈希值，决定是否需要同步
4. 仅在有变化时执行更新操作
```

### 缓存策略
```
.sync_cache/
├── openwrt_master.commit    # 主源码提交哈希
├── feeds_hash              # feeds配置哈希
├── pkg_*.commit           # 各软件包提交哈希
└── last_full_sync         # 上次完整同步时间
```

### 增量更新流程
```
1. 检查feeds.conf是否有变化
2. 无变化 → 跳过feeds update，仅执行feeds install
3. 有变化 → 执行完整feeds update
4. 检查各软件包本地状态（是否有修改）
5. 仅更新有更新的软件包
```

## 使用方法

### 手动执行同步
```bash
# 检查更新并增量同步
./Scripts/SyncHook.sh check

# 强制完整同步
./Scripts/SyncHook.sh force

# 清理缓存
./Scripts/SyncHook.sh clean

# 查看同步状态
./Scripts/SyncHook.sh status
```

### 自动化同步
- **定时任务**：Sync-Hook.yml每天凌晨2点自动检查
- **编译集成**：SmartSync.sh自动集成到WRT-CORE.yml
- **条件触发**：仅在上游有更新时执行完整同步

## 优势对比

### 传统方式
```
每次编译：
├── git clone 主源码 (耗时)
├── ./scripts/feeds update -a (耗时)
├── ./scripts/feeds install -a
├── git clone 各种软件包 (耗时)
└── 总耗时：10-30分钟
```

### Hook式同步
```
首次编译：
├── git clone 主源码 (耗时)
├── ./scripts/feeds update -a (耗时)
├── ./scripts/feeds install -a
├── git clone 各种软件包 (耗时)
└── 总耗时：10-30分钟

后续编译（无更新）：
├── 检测缓存 → 无更新
├── 跳过git clone
├── 跳过feeds update
├── 仅执行feeds install
└── 总耗时：1-3分钟

后续编译（有更新）：
├── 增量更新主源码
├── 仅更新变化的feeds
├── 仅更新变化的软件包
└── 总耗时：3-8分钟
```

## 配置说明

### 环境变量
- `WRT_REPO` - 上游源码仓库地址
- `WRT_BRANCH` - 上游源码分支
- `WRT_SOURCE` - 源码标识
- `GITHUB_WORKSPACE` - 工作空间路径

### 缓存策略
- 自动清理7天前的缓存文件
- 使用GitHub Actions cache保存同步状态
- 支持手动清理缓存

## 故障排除

### 常见问题
1. **同步失败** - 检查网络连接和GitHub API限制
2. **缓存冲突** - 执行 `./Scripts/SyncHook.sh clean` 清理缓存
3. **权限问题** - 确保脚本有执行权限 `chmod +x`

### 调试模式
```bash
# 查看详细日志
./Scripts/SyncHook.sh check 2>&1 | tee sync.log

# 检查缓存状态
ls -la .sync_cache/
cat .sync_state/state.json
```

## 扩展功能

### 自定义同步规则
可以在 `SyncHook.sh` 中添加自定义的同步逻辑：
```bash
# 在 sync_custom_packages 函数中添加
if [ "$pkg_name" = "your-package" ]; then
    # 自定义同步逻辑
fi
```

### 钩子脚本
支持在同步前后执行自定义脚本：
- `pre-sync.sh` - 同步前执行
- `post-sync.sh` - 同步后执行

## 维护建议

1. **定期清理**：每月执行一次 `./Scripts/SyncHook.sh clean`
2. **监控状态**：查看Sync-Hook.yml的运行记录
3. **更新策略**：根据项目需求调整同步频率

## 注意事项

1. 首次使用需要完整同步
2. 网络不稳定时可能需要手动重试
3. 大量软件包更新时可能触发GitHub API限制
4. 建议在非编译时段执行自动同步