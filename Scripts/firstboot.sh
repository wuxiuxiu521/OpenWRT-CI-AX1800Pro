# 创建并写入自定义初始化脚本
cat << 'EOF' > files/etc/uci-defaults/99-custom-init
#!/bin/sh
# Set Luci apply holdoff to 1
uci set luci.apply.holdoff='1'
uci commit luci

# Remove ULA prefix and other unwanted settings
uci del network.globals.ula_prefix
uci del dhcp.lan.ra_slaac
uci del dhcp.lan.ra_flags
uci add_list dhcp.lan.ra_flags='none'
uci set dhcp.lan.dns_service='0'

# Configure IPv6 settings
uci set network.lan.delegate='0'
uci set network.lan.ip6assign='64'
uci set network.lan.ip6ifaceid='random'

# Commit changes
uci commit network
uci commit dhcp

# Restart services to apply changes
/etc/init.d/network restart
/etc/init.d/dnsmasq restart
/etc/init.d/rpcd restart
EOF

# 赋予脚本执行权限
chmod +x files/etc/uci-defaults/99-custom-init
