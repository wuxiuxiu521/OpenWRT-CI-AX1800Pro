# OpenWRT-CI
云编译OpenWRT固件

官方版：
https://github.com/immortalwrt/immortalwrt.git

高通版：
https://github.com/VIKINGYFY/immortalwrt.git

# 固件简要说明：

仅选择 QCA-ALL 编译

固件信息里的时间为编译开始的时间，方便核对上游源码提交时间。

MEDIATEK系列、QUALCOMMAX系列、ROCKCHIP系列、X86系列。

# 目录简要说明：

workflows——自定义CI配置

Scripts——自定义脚本

Config——自定义配置

# Tips ! 如果你想在本地进行编译的话 准备以下步骤(针对AX1800Pro)

## 注意

1. **不要用 root 用户进行编译**
2. 国内用户编译前最好准备好梯子

- 首先安装ubuntu20.04LTS
  ## 编译命令

1. 首先装好 Linux 系统， Ubuntu 20.04 LTS

2. 安装编译依赖

   ```bash
   sudo apt update -y
   sudo apt full-upgrade -y
   sudo apt install -y ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential \
   bzip2 ccache cmake cpio curl device-tree-compiler fastjar flex gawk gettext gcc-multilib g++-multilib \
   git gperf haveged help2man intltool libc6-dev-i386 libelf-dev libglib2.0-dev libgmp3-dev libltdl-dev \
   libmpc-dev libmpfr-dev libncurses5-dev libncursesw5-dev libreadline-dev libssl-dev libtool lrzsz \
   mkisofs msmtp nano ninja-build p7zip p7zip-full patch pkgconf python2.7 python3 python3-pip libpython3-dev qemu-utils \
   rsync scons squashfs-tools subversion swig texinfo uglifyjs upx-ucl unzip vim wget xmlto xxd zlib1g-dev
   
   ```
## tips 上游不带有curl jq btop 但是cpu直接超频1.8G

3. 下载源代码，更新 feeds 并选择配置

   ```bash
   git clone https://github.com/VIKINGYFY/immortalwrt
   cd immortalwrt
   ./scripts/feeds update -a && ./scripts/feeds install -a
   make menuconfig
   
   ```

4. ！！！必须要的 否则编译不出来！！！ tips注意这个版本上游高通是锁1024M最大内存 改成512M 不影响日常使用

   ```bash
   echo "CONFIG_IPQ_MEM_PROFILE_1024=n" >> ./.config
   echo "CONFIG_IPQ_MEM_PROFILE_512=y" >> ./.config
   echo "CONFIG_ATH11K_MEM_PROFILE_1G=n" >> ./.config
   echo "CONFIG_ATH11K_MEM_PROFILE_512M=y" >> ./.config
   
   ```

5. 第一次编译 一步到位

   ```bash
   make download -j$(nproc) && make -j$(nproc)
   
   ```


## 编译完成后输出路径：bin/targets


## 二次编译直接运行

   ```bash
   make -j$(nproc)

   ```

## 以下个根据情况自行选择

1. 下载 dl 库，编译固件
（-j 后面是线程数，为便于排除错误推荐用单线程）

   ```bash
   make download -j8
   make -j1 V=s
   ```

2. 二次编译：

   ```bash
   cd immortalwrt
   git fetch && git reset --hard origin/main
   ./scripts/feeds update -a && ./scripts/feeds install -a
   make menuconfig
   make V=s -j$(nproc)
   ```

3. 如果需要重新配置：

   ```bash
   rm -rf .config
   make menuconfig
   make V=s -j$(nproc)
   ```
   
# 以下是该仓库对上游进行的调整
QCA-ALL.yml
仅编译 IPQ60XX-WIFI-YES 去除 (IPQ60XX-WIFI-NO, IPQ807X-WIFI-YES, IPQ807X-WIFI-NO)

IPQ60XX-WIFI-YES.txt
仅保留AX1800Pro编译 去除其他设备固件编译支持

Packages.sh
去除luci-theme-argon的替换更新 去除主题luci-theme-design的替换更新 去除主题luci-theme-kucat的替换更新 去除主题luci-theme-alpha的替换更新 去除主题配置luci-app-alpha-config的替换更新
去除htop 去除 iperf3 去除wolplus 去除tailscale
使用不良0 的clashapi homeproxy 无法显示clashapi一栏需要开启无痕 去除(tailscale)
添加openssh-sftp-server 添加btop 使用BBR拥塞控制算法 添加luci CPU 性能优化调节设置 

QCA-ALL.yml
修改 默认主机名 AX1800Pro 默认WIFI名 ImmortalWrt 默认地址 192.168.6.1

添加文件feed.sh 追加kiddin源 暂未使用
