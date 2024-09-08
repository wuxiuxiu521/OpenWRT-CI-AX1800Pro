# 在OpenWrt根目录下创建files目录
mkdir -p files/etc/uci-defaults

# 在files目录下创建一个名为99-custom-init的脚本
cat << "EOF" > files/etc/uci-defaults/99-custom-init
#!/bin/sh
# 这里写你想在第一次启动时运行的命令

# echo "Hello, this is a custom command for the first boot." > /etc/firstboot.log
# 设置webui响应倒计时1s
uci set luci.apply.holdoff='1'
uci commit luci

# 完成后删除脚本以避免再次执行
rm -f /etc/uci-defaults/99-custom-init
EOF

# 确保脚本是可执行的
chmod +x files/etc/uci-defaults/99-custom-init
