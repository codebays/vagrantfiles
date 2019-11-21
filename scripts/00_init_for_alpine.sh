#!/bin/sh
# Alpine3.8 下环境初始化(安装Docker)
#
#   1). 更换仓库源并更新操作系统；
#   2). 优化系统：禁止ping通机器、vi的tab替换为4个空格；
#   3). 配置时间同步服务器、DNS服务器；
#   4). Linux内核优化；
#   5). 安装pip并更换pip源；
#   6). 安装docker、docker-compose环境，并更换docker源。

DOCKER_MIRROR="${1}"

# 更换仓库源并更新操作系统
version="v3.8"
echo "http://mirrors.ustc.edu.cn/alpine/${version}/main" > /etc/apk/repositories \
    && echo "http://mirrors.ustc.edu.cn/alpine/${version}/community" >> /etc/apk/repositories \
    && apk update --no-cache > /dev/null \
    && apk add --no-cache --update openrc > /dev/null

# 系统优化
{ \
    echo '#!/bin/sh'; \
    echo "echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_all"; \
} | tee /etc/local.d/00_ignore_ping.start \
&& rc-update add local boot
&& chmod +x /etc/local.d/00_ignore_ping.start
if grep -Eqi '^set ts=4' /etc/vim/vimrc; then
    echo
else
    { \
        echo 'set ts=4'; \
        echo 'set expandtab'; \
        echo 'set autoindent'; \
    } | tee -a /etc/vim/vimrc
fi
if grep -Eqi '^127.0.0.1[[:space:]]*localhost' /etc/hosts; then
    echo
else
    echo "127.0.0.1 localhost.localdomain localhost" >> /etc/hosts
fi
chown root:root /etc/passwd /etc/shadow /etc/group
chmod 0644 /etc/group
chmod 0644 /etc/passwd
chmod 0400 /etc/shadow
sed -i 's/^ClientAliveInterval .*/ClientAliveInterval 600/g' /etc/ssh/sshd_config
sed -i 's/^ClientAliveCountMax .*/ClientAliveCountMax 2/g' /etc/ssh/sshd_config
sed -i 's/^#ClientAliveInterval .*/ClientAliveInterval 600/g' /etc/ssh/sshd_config
sed -i 's/^#ClientAliveCountMax .*/ClientAliveCountMax 2/g' /etc/ssh/sshd_config

# Linux内核优化
if grep -Eqi '^net.ipv4.tcp_max_tw_buckets = 20000' /etc/sysctl.conf; then
    echo
else
    { \
        echo 'net.ipv4.tcp_max_tw_buckets = 20000'; \
        echo 'net.ipv4.tcp_syncookies = 1'; \
        echo 'net.ipv4.tcp_max_syn_backlog = 1048576'; \
        echo 'net.ipv4.tcp_synack_retries = 2'; \
        echo 'kernel.sysrq=1'; \
        echo 'net.ipv4.tcp_keepalive_time = 1800'; \
        echo 'net.ipv4.tcp_keepalive_probes = 3'; \
        echo 'net.ipv4.tcp_keepalive_intvl = 15'; \
        echo 'net.core.netdev_max_backlog = 1048576'; \
        echo 'net.core.somaxconn = 65535'; \
        echo 'vm.overcommit_memory = 1'; \
        echo 'fs.file-max = 6815744'; \
    } | tee -a /etc/sysctl.conf \
    && sysctl -p
fi

# DNS
{ \
    echo 'nameserver 223.5.5.5'; \
    echo 'nameserver 223.6.6.6'; \
} | tee /etc/resolv.conf

# NTP
TZ="Asia/Shanghai"
apk add --no-cache --update tzdata > /dev/null \
    && ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo "${TZ}" > /etc/timezone \
    && apk add --no-cache --update chrony > /dev/null \
    && mkdir -p /var/lib/chrony \
    && { \
        echo "server ntp1.aliyun.com iburst"; \
        echo "server ntp2.aliyun.com iburst"; \
        echo "server ntp3.aliyun.com iburst"; \
        echo "server ntp4.aliyun.com iburst"; \
        echo "server ntp5.aliyun.com iburst"; \
        echo "server ntp6.aliyun.com iburst"; \
        echo "server ntp7.aliyun.com iburst"; \
        echo "stratumweight 0"; \
        echo "driftfile /var/lib/chrony/drift"; \
        echo "rtcsync"; \
        echo "makestep 10 3"; \
        echo "bindcmdaddress 127.0.0.1"; \
        echo "bindcmdaddress ::1"; \
        echo "keyfile /etc/chrony/chrony.keys"; \
        echo "commandkey 1"; \
        echo "generatecommandkey"; \
        echo "logchange 0.5"; \
        echo "logdir /var/log/chrony"; \
    } | tee /etc/chrony/chrony.conf \
    && rc-update add chronyd boot \
    && rc-service chronyd start \
    && chronyc tracking > /dev/null

# 安装pip以及更新pip源
apk add --no-cache --update python3 python3-dev libffi-dev openssl-dev gcc libc-dev make > /dev/null \
    && { \
        echo '[global]'; \
        echo 'index-url = https://mirrors.aliyun.com/pypi/simple/'; \
        echo; \
        echo '[install]'; \
        echo 'trusted-host=mirrors.aliyun.com'; \
    } | tee /etc/pip.conf

# 安装Docker以及更新Docker镜像源
sysctl -e -w kernel.grsecurity.chroot_deny_chmod=0 > /dev/null 2>&1
sysctl -e -w kernel.grsecurity.chroot_deny_mknod=0 > /dev/null 2>&1
apk add --no-cache --update docker > /dev/null \
    && mkdir -p /etc/docker \
    && {\
        echo '{'; \
        echo -e '\t"registry-mirrors":['; \
        comma=""; \
        for mirror in ${DOCKER_MIRROR};do
            echo -e "\t\t${comma}\"${mirror}\"";
            comma=", ";
        done; \
        echo -e '\t]'; \
        echo '}'; \
    } | tee /etc/docker/daemon.json \
    && rc-update add docker boot \
    && rc-service docker start \
    && pip3 install -U docker-compose > /dev/null 2>&1

# 设置PATH
echo 'PATH=$PATH:/usr/local/bin:/usr/local/sbin' >> /etc/profile
source /etc/profile

# 相关目录
mkdir -p /runtimes \
    && chmod -R 1777 /runtimes

exit 0