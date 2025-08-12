#!/bin/bash

#修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改immortalwrt.lan关联IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")
#添加编译日期标识
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_MARK-$WRT_DATE')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")

WIFI_SH=$(find ./target/linux/{mediatek/filogic,qualcommax}/base-files/etc/uci-defaults/ -type f -name "*set-wireless.sh" 2>/dev/null)
WIFI_UC="./package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc"
if [ -f "$WIFI_SH" ]; then
	#修改WIFI名称
	sed -i "s/BASE_SSID='.*'/BASE_SSID='$WRT_SSID'/g" $WIFI_SH
	#修改WIFI密码
	sed -i "s/BASE_WORD='.*'/BASE_WORD='$WRT_WORD'/g" $WIFI_SH
elif [ -f "$WIFI_UC" ]; then
	#修改WIFI名称
	sed -i "s/ssid='.*'/ssid='$WRT_SSID'/g" $WIFI_UC
	#修改WIFI密码
	sed -i "s/key='.*'/key='$WRT_WORD'/g" $WIFI_UC
	#修改WIFI地区
	sed -i "s/country='.*'/country='CN'/g" $WIFI_UC
	#修改WIFI加密
	sed -i "s/encryption='.*'/encryption='psk2+ccmp'/g" $WIFI_UC
fi

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
	echo -e "$WRT_PACKAGE" >> ./.config
fi

#高通平台调整
DTS_PATH="./target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/"
if [[ "${WRT_TARGET^^}" == *"QUALCOMMAX"* ]]; then
	#取消nss相关feed
	echo "CONFIG_FEED_nss_packages=n" >> ./.config
	echo "CONFIG_FEED_sqm_scripts_nss=n" >> ./.config
	#开启sqm-nss插件
	echo "CONFIG_PACKAGE_luci-app-sqm=y" >> ./.config
	echo "CONFIG_PACKAGE_sqm-scripts-nss=y" >> ./.config
	#设置NSS版本
	echo "CONFIG_NSS_FIRMWARE_VERSION_11_4=n" >> ./.config
	if [[ "${WRT_CONFIG,,}" == *"ipq50"* ]]; then
		echo "CONFIG_NSS_FIRMWARE_VERSION_12_2=y" >> ./.config
	else
		echo "CONFIG_NSS_FIRMWARE_VERSION_12_5=y" >> ./.config
	fi
	#无WIFI配置调整Q6大小
	if [[ "${WRT_CONFIG,,}" == *"wifi"* && "${WRT_CONFIG,,}" == *"no"* ]]; then
		find $DTS_PATH -type f ! -iname '*nowifi*' -exec sed -i 's/ipq\(6018\|8074\).dtsi/ipq\1-nowifi.dtsi/g' {} +
		echo "qualcommax set up nowifi successfully!"
	fi
fi

# #修复dropbear
sed -i "s/Interface/DirectInterface/" ./package/network/services/dropbear/files/dropbear.config

# 想要剔除的
# echo "CONFIG_PACKAGE_htop=n" >> ./.config
# echo "CONFIG_PACKAGE_iperf3=n" >> ./.config
echo "CONFIG_PACKAGE_luci-app-wolplus=n" >> ./.config
echo "CONFIG_PACKAGE_luci-app-tailscale=n" >> ./.config
echo "CONFIG_PACKAGE_luci-app-advancedplus=n" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-kucat=n" >> ./.config

# Docker --cpuset-cpus="0-1"
echo "CONFIG_CGROUPS=y" >> ./.config
echo "CONFIG_CPUSETS=y" >> ./.config

# 可以让FinalShell查看文件列表并且ssh连上不会自动断开
echo "CONFIG_PACKAGE_openssh-sftp-server=y" >> ./.config
# 解析、查询、操作和格式化 JSON 数据
echo "CONFIG_PACKAGE_jq=y" >> ./.config
# base64 修改码云上的内容 需要用到
echo "CONFIG_PACKAGE_coreutils-base64=y" >> ./.config
echo "CONFIG_PACKAGE_coreutils=y" >> ./.config
# 简单明了的系统资源占用查看工具
echo "CONFIG_PACKAGE_btop=y" >> ./.config
# 多网盘存储
# echo "CONFIG_PACKAGE_luci-app-alist=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-openlist2=y" >> ./.config
# 强大的工具(需要添加源或git clone)
echo "CONFIG_PACKAGE_luci-app-lucky=y" >> ./.config
# 网络通信工具
echo "CONFIG_PACKAGE_curl=y" >> ./.config
echo "CONFIG_PACKAGE_tcping=y" >> ./.config
# # BBR 拥塞控制算法(终端侧) + CAKE 一种现代化的队列管理算法(路由侧)
# echo "CONFIG_PACKAGE_kmod-tcp-bbr=y" >> ./.config
# # echo "CONFIG_DEFAULT_tcp_bbr=y" >> ./.config
# # 更改默认的拥塞控制算法为cubic
# echo "CONFIG_DEFAULT_tcp_cubic=y" >> ./.config
# 磁盘管理
# echo "CONFIG_PACKAGE_luci-app-diskman=y" >> ./.config
echo "CONFIG_PACKAGE_cfdisk=y" >> ./.config
# docker(只能集成)
echo "CONFIG_PACKAGE_luci-app-dockerman=y" >> ./.config
# Podman
# echo "CONFIG_PACKAGE_luci-app-podman=y" >> ./.config
# qBittorrent
# echo "CONFIG_PACKAGE_luci-app-qbittorrent=y" >> ./.config
# 强大的工具Lucky大吉(需要添加源或git clone)
echo "CONFIG_PACKAGE_luci-app-lucky=y" >> ./.config
# Caddy
# echo "CONFIG_PACKAGE_luci-app-caddy=y" >> ./.config
# V2rayA
# echo "CONFIG_PACKAGE_luci-app-v2raya=y" >> ./.config
# echo "CONFIG_PACKAGE_v2ray-core=y" >> ./.config
# echo "CONFIG_PACKAGE_v2ray-geoip=y" >> ./.config
# echo "CONFIG_PACKAGE_v2ray-geosite=y" >> ./.config
# Natter2 报错
# echo "CONFIG_PACKAGE_luci-app-natter2=y" >> ./.config
# 文件管理器
echo "CONFIG_PACKAGE_luci-app-filemanager=y" >> ./.config
# 基于Golang的多协议转发工具
echo "CONFIG_PACKAGE_luci-app-gost=y" >> ./.config
# Git
echo "CONFIG_PACKAGE_git-http=y" >> ./.config
# Nginx替换Uhttpd
# echo "CONFIG_PACKAGE_nginx-mod-luci=y" >> ./.config
# Nginx的图形化界面
echo "CONFIG_PACKAGE_luci-app-nginx=y" >> ./.config
# HAProxy 比Nginx更强大的反向代理服务器
# echo "CONFIG_PACKAGE_luci-app-haproxy-tcp=y" >> ./.config
# Adguardhome去广告
echo "CONFIG_PACKAGE_luci-app-adguardhome=y" >> ./.config
# cloudflre速度筛选器
# echo "CONFIG_PACKAGE_luci-app-cloudflarespeedtest=y" >> ./.config
# OpenClash
# echo "CONFIG_PACKAGE_luci-app-openclash=y" >> ./.config
# nfs-kernel-server共享
# echo "CONFIG_PACKAGE_nfs-kernel-server=y" >> ./.config
# Kiddin9 luci-app-nfs
# echo "CONFIG_PACKAGE_luci-app-nfs=y" >> ./.config
# zoneinfo-asia tzdata（时区数据库）的一部分，只包含亚洲相关的时区数据 zoneinfo-all全部时区（体积较大，不推荐在嵌入设备）
echo "CONFIG_PACKAGE_zoneinfo-all=y" >> ./.config
# Caddy
# echo "CONFIG_PACKAGE_luci-app-caddy=y" >> ./.config
# Openssl
# echo "CONFIG_PACKAGE_openssl-util=y" >> ./.config
# dig命令
echo "CONFIG_PACKAGE_bind-dig=y" >> ./.config
# ss 网络抓包工具
echo "CONFIG_PACKAGE_ss=y" >> ./.config
