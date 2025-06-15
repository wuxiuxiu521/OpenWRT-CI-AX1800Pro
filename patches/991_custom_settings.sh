#!/bin/sh

# 检查当前nf_conntrack_max值是否小于65536，若更小则修改
current_value=$(sysctl -n net.netfilter.nf_conntrack_max)
if [ "$current_value" -lt 65535 ]; then
    # 从sysctl.conf删除旧的nf_conntrack_max配置以避免重复
    sed -i '/nf_conntrack_max/d' /etc/sysctl.conf
    # 写入新配置，设置最大连接数为65535
    echo "net.netfilter.nf_conntrack_max = 65535" >>/etc/sysctl.conf
    # 应用配置并立即生效
    sysctl -p
fi

# 解除dropbear访问限制
if uci show dropbear | grep -q "DirectInterface"; then
    uci delete dropbear.main.DirectInterface
    uci commit dropbear
    /etc/init.d/dropbear restart
fi

# 设置应用时间倒计时1秒
uci set luci.apply.holdoff='1'
uci commit luci

# 修复识别内存错误导致tmp小于内存
mount -o remount,size=$(awk '/MemTotal/ {print $2"k"}' /proc/meminfo) /tmp

# 判断账号密码是否设置
if [ -n "$PPPOE_USER" ] && [ -n "$PPPOE_PASS" ]; then
    echo "配置 PPPoE 拨号账户..."

    uci set network.wan.proto='pppoe'
    uci set network.wan.username="$PPPOE_USER"
    uci set network.wan.password="$PPPOE_PASS"
    uci commit network
    /etc/init.d/network restart

    echo "PPPoE 配置完成"
else
    echo "未设置 PPPoE 账号密码，跳过配置"
fi

# 修改nginx的头限制大小
uci set nginx.@server[-1].large_client_header_buffers='8 32k'
uci set nginx.@server[-1].client_max_body_size='128M'
uci commit nginx
/etc/init.d/nginx restart

RC_LOCAL="/etc/rc.local"
# 如果没有添加过，就添加
grep -q "large_client_header_buffers" "$RC_LOCAL" || {
    # 在 exit 0 之前插入命令
    sed -i '/exit 0/i \
uci set nginx.@server[-1].large_client_header_buffers='\''8 32k'\''\n\
uci set nginx.@server[-1].client_max_body_size='\''128M'\''\n\
uci commit nginx\n\
/etc/init.d/nginx restart\n' "$RC_LOCAL"
}
