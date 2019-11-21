#!/bin/bash
# Ubuntu 18.04(bionic)LTS 下环境初始化
#
#   1). 更换APT源并更新；
#   2). 优化系统：文件最大打开数量、禁止ping通机器、vi的tab替换为4个空格；
#   3). 配置时间同步服务器、DNS服务器；
#   4). Linux内核优化；
#   5). 安装pip3并更换pip3源；
#   6). 安装docker、docker-compose环境，并更换docker源。

DOCKER_MIRROR="${1}"

# 更新YUM源和系统
version="bionic"
echo "deb http://mirrors.aliyun.com/ubuntu/ ${version} main restricted universe multiverse" > /etc/apt/sources.list  \
    && echo "deb-src http://mirrors.aliyun.com/ubuntu/ ${version} main restricted universe multiverse" >> /etc/apt/sources.list \
    && echo "deb http://mirrors.aliyun.com/ubuntu/ ${version}-security main restricted universe multiverse" >> /etc/apt/sources.list \
    && echo "deb-src http://mirrors.aliyun.com/ubuntu/ ${version}-security main restricted universe multiverse" >> /etc/apt/sources.list \
    && echo "deb http://mirrors.aliyun.com/ubuntu/ ${version}-updates main restricted universe multiverse" >> /etc/apt/sources.list \
    && echo "deb-src http://mirrors.aliyun.com/ubuntu/ ${version}-updates main restricted universe multiverse" >> /etc/apt/sources.list \
    && echo "deb http://mirrors.aliyun.com/ubuntu/ ${version}-proposed main restricted universe multiverse" >> /etc/apt/sources.list \
    && echo "deb-src http://mirrors.aliyun.com/ubuntu/ ${version}-proposed main restricted universe multiverse" >> /etc/apt/sources.list \
    && echo "deb http://mirrors.aliyun.com/ubuntu/ ${version}-backports main restricted universe multiverse" >> /etc/apt/sources.list \
    && echo "deb-src http://mirrors.aliyun.com/ubuntu/ ${version}-backports main restricted universe multiverse" >> /etc/apt/sources.list \
    && apt-get clean > /dev/null \
    && apt-get update -y > /dev/null

# 系统优化
if grep -Eqi '^hadoop - nofile 1024000' /etc/security/limits.conf; then
    echo
else
    { \
        echo "* soft nofile 1024000"; \
        echo "* hard nofile 1024000"; \
        echo "hadoop - nofile 1024000"; \
        echo "hadoop - nproc 1024000"; \
    } | tee -a /etc/security/limits.conf
fi
if [ -f /lib/systemd/system/rc-local.service ];then
    { \
        echo '[Install]'; \
        echo 'WantedBy=multi-user.target'; \
    } | tee -a /lib/systemd/system/rc-local.service \
    && { \
        echo '#!/bin/sh'; \
        echo "echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_all"; \
        echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled"; \
        echo "exit 0"; \
    } | tee /etc/rc.local \
    && chmod +x /etc/rc.local \
    && systemctl daemon-reload \
    && systemctl enable rc-local \
    && systemctl start rc-local
fi
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
chown root:root /etc/passwd /etc/shadow /etc/group /etc/gshadow
chmod 0644 /etc/group
chmod 0644 /etc/passwd
chmod 0400 /etc/shadow
chmod 0400 /etc/gshadow
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
rm -rf /etc/localtime \
    && ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo "${TZ}" > /etc/timezone \
    && apt-get install -y chrony \
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
    } | tee /etc/chrony/chrony.conf  \
    && systemctl restart chronyd \
    && timedatectl set-local-rtc 0 \
    && chronyc tracking > /dev/null

# 安装pip以及更新pip源
apt-get install -y python3-pip > /dev/null \
    && { \
        echo '[global]'; \
        echo 'index-url = https://mirrors.aliyun.com/pypi/simple/'; \
        echo; \
        echo '[install]'; \
        echo 'trusted-host=mirrors.aliyun.com'; \
    } | tee /etc/pip.conf

# 安装Docker以及更新Docker镜像源
apt-get remove -y docker \
    docker-engine docker.io \
    containerd runc > /dev/null 2>&1
apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common > /dev/null \
    && curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | apt-key add - \
    && add-apt-repository "deb [arch=amd64] http://mirrors.aliyun.com/docker-ce/linux/ubuntu ${version} stable" > /dev/null \
    && apt-get update -y > /dev/null \
    && apt-get install -y docker-ce docker-ce-cli containerd.io > /dev/null \
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
    && systemctl enable docker \
    && systemctl start docker \
    && pip3 install -U docker-compose > /dev/null 2>&1

# 设置PATH
echo 'PATH=$PATH:/usr/local/bin:/usr/local/sbin' >> /etc/profile
source /etc/profile

# 相关目录
mkdir -p /runtimes \
    && chmod -R 1777 /runtimes

exit 0