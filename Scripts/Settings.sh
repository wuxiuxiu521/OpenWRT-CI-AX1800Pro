#!/bin/bash

#修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改immortalwrt.lan关联IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")
#添加编译日期标识
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_CI-$WRT_DATE')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")
#修改默认WIFI名
sed -i "s/\.ssid=.*/\.ssid=$WRT_WIFI/g" $(find ./package/kernel/mac80211/ ./package/network/config/ -type f -name "mac80211.*")

CFG_FILE="./package/base-files/files/bin/config_generate"
#修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
#修改默认主机名
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE

#配置文件修改
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config

#手动调整的插件
if [ -n "$WRT_PACKAGE" ]; then
	echo "$WRT_PACKAGE" >> ./.config
fi

#高通平台锁定512M内存
if [[ $WRT_TARGET == *"IPQ"* ]]; then
	echo "CONFIG_IPQ_MEM_PROFILE_1024=n" >> ./.config
	echo "CONFIG_IPQ_MEM_PROFILE_512=y" >> ./.config
	echo "CONFIG_ATH11K_MEM_PROFILE_1G=n" >> ./.config
	echo "CONFIG_ATH11K_MEM_PROFILE_512M=y" >> ./.config
fi

# 想要剔除的
echo "CONFIG_PACKAGE_htop=n" >> ./.config
echo "CONFIG_PACKAGE_iperf3=n" >> ./.config
echo "CONFIG_PACKAGE_luci-app-wolplus=n" >> ./.config
echo "CONFIG_PACKAGE_luci-app-tailscale=n" >> ./.config
echo "CONFIG_PACKAGE_luci-app-advancedplus=n" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-kucat=n" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-design=n" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-alpha=n" >> ./.config
echo "CONFIG_PACKAGE_luci-app-alpha-config=n" >> ./.config

# 可以让FinalShell查看文件列表并且ssh连上不会自动断开
echo "CONFIG_PACKAGE_openssh-sftp-server=y" >> ./.config
# 解析、查询、操作和格式化 JSON 数据
echo "CONFIG_PACKAGE_jq=y" >> ./.config
# 简单明了的系统资源占用查看工具
echo "CONFIG_PACKAGE_btop=y" >> ./.config
# 多网盘存储
echo "CONFIG_PACKAGE_luci-app-alist=y" >> ./.config
# 强大的工具(需要添加源或git clone)
echo "CONFIG_PACKAGE_luci-app-lucky=y" >> ./.config
# 网络通信工具
echo "CONFIG_PACKAGE_curl=y" >> ./.config
# CPU 性能优化调节设置
echo "CONFIG_PACKAGE_luci-app-cpufreq=y" >> ./.config
# 图形化流量监控
echo "CONFIG_PACKAGE_luci-app-wrtbwmon=y" >> ./.config
# bbr加速+turboacc
# echo "CONFIG_PACKAGE_luci-app-turboacc=y" >> ./.config
# BBR 拥塞控制算法
echo "CONFIG_PACKAGE_kmod-tcp-bbr=y" >> ./.config
# docker(只能集成)
echo "CONFIG_PACKAGE_luci-app-dockerman=y" >> ./.config

# XDP 一种高级数据处理技术，旨在提高网络数据包处理的效率和性能。它允许在网络数据包进入内核的更早阶段进行处理，从而减少延迟和提高吞吐量。
# 基本 XDP 支持
echo "CONFIG_XDP=y" >> ./.config
# XDP Sockets
echo "CONFIG_XDP_SOCKETS=y" >> ./.config
# BPF 子系统支持（XDP 是 BPF 的一部分）
echo "CONFIG_BPF=y" >> ./.config
echo "CONFIG_BPF_SYSCALL=y" >> ./.config
# BPF 相关选项（为了全面支持 XDP）
echo "CONFIG_NET_CLS_BPF=y" >> ./.config
echo "CONFIG_NET_ACT_BPF=y" >> ./.config
echo "CONFIG_BPF_JIT=y" >> ./.config
echo "CONFIG_HAVE_EBPF_JIT=y" >> ./.config
echo "CONFIG_BPF_EVENTS=y" >> ./.config
echo "CONFIG_BPF_STREAM_PARSER=y" >> ./.config
# eBPF 和 JIT 编译器支持
echo "CONFIG_HAVE_BPF_JIT=y" >> ./.config
echo "CONFIG_BPF_JIT_ALWAYS_ON=y" >> ./.config
# 内核调试信息（可选）: 如果需要调试，可以选择启用内核调试和相关日志支持
echo "CONFIG_DEBUG_INFO=n" >> ./.config
echo "CONFIG_DEBUG_INFO_REDUCED=n" >> ./.config

# 测试！！！！！！！！！！！！！！！原仓库依旧缺失 iptables ip6tables libip4tc2 libip6tc2 libiptext0 libiptext6-0 修改后依旧缺失 ip6tables libip4tc2 libip6tc2 只能集成docker
# echo "CONFIG_PACKAGE_iptables=y" >> ./.config
# echo "CONFIG_PACKAGE_iptables-mod-extra=y" >> ./.config
# echo "CONFIG_PACKAGE_ip6tables=y" >> ./.config
# echo "CONFIG_PACKAGE_kmod-ipt-physdev=y" >> ./.config
# echo "CONFIG_PACKAGE_kmod-nf-ipvs=y" >> ./.config
# echo "CONFIG_PACKAGE_kmod-veth=y" >> ./.config
# echo "CONFIG_PACKAGE_libip4tc2=y" >> ./.config
# echo "CONFIG_PACKAGE_libip6tc2=y" >> ./.config
# echo "CONFIG_PACKAGE_libiptext0=y" >> ./.config
# echo "CONFIG_PACKAGE_libiptext6-0=y" >> ./.config
# echo "CONFIG_PACKAGE_kmod-ipt-fullconenat=y" >> ./.config
