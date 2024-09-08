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
#修改默认时区
sed -i "s/timezone='.*'/timezone='CST-8'/g" $CFG_FILE
sed -i "/timezone='.*'/a\\\t\t\set system.@system[-1].zonename='Asia/Shanghai'" $CFG_FILE

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
echo "CONFIG_PACKAGE_openssh-server=y" >> ./.config
# 解析、查询、操作和格式化 JSON 数据
echo "CONFIG_PACKAGE_jq=y" >> ./.config
简单明了的系统资源占用查看工具
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

# docker
echo "CONFIG_PACKAGE_luci-i18n-dockerman-zh-cn=y" >> ./.config


# 测试！！！！！！！！！！！！！！！原仓库依旧缺失 iptables ip6tables libip4tc2 libip6tc2 libiptext0 libiptext6-0 
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
