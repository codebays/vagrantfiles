#!/bin/bash
# CentOS7 下环境初始化(安装Docker)
#
#   1). 更换yum源并更新操作系统；
#   2). 优化系统：文件最大打开数量、禁止ping通机器、vi的tab替换为4个空格、禁用SELinux；
#   3). 配置时间同步服务器、DNS服务器；
#   4). Linux内核优化；
#   5). 安装pip并更换pip源；
#   6). 安装docker、docker-compose环境，并更换docker源。

DOCKER_MIRROR="${1}"

# 更新YUM源和系统
rm -f /etc/yum.repos.d/*.repo \
    && curl -fsSL -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo \
    && curl -fsSL -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo  \
    && sed -i -e '/mirrors.cloud.aliyuncs.com/d' -e '/mirrors.aliyuncs.com/d' /etc/yum.repos.d/CentOS-Base.repo  \
    && sed -i -e '/mirrors.cloud.aliyuncs.com/d' -e '/mirrors.aliyuncs.com/d' /etc/yum.repos.d/epel.repo  \
    && yum clean all > /dev/null \
    && yum makecache > /dev/null \
    && yum update -y > /dev/null 

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
    { \
        echo "echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_all"; \
        echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled"; \
    } | tee -a /etc/rc.local \
    && chmod +x /etc/rc.local
if grep -Eqi '^set ts=4' /etc/virc; then
    echo
else
    { \
        echo 'set ts=4'; \
        echo 'set expandtab'; \
        echo 'set autoindent'; \
    } | tee -a /etc/virc
fi
setenforce 0
sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
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
        echo "keyfile /etc/chrony.keys"; \
        echo "commandkey 1"; \
        echo "generatecommandkey"; \
        echo "logchange 0.5"; \
        echo "logdir /var/log/chrony"; \
    } | tee /etc/chrony.conf \
    && systemctl enable chronyd \
    && systemctl restart chronyd \
    && timedatectl set-local-rtc 0 \
    && chronyc tracking > /dev/null \

# 安装pip以及更新pip源
yum -y install python3-pip > /dev/null  \
    && { \
        echo '[global]'; \
        echo 'index-url = https://mirrors.aliyun.com/pypi/simple/'; \
        echo; \
        echo '[install]'; \
        echo 'trusted-host=mirrors.aliyun.com'; \
    } | tee /etc/pip.conf

# 安装Docker以及更新Docker镜像源
yum remove -y docker \
    docker-client docker-client-latest \
    docker-common docker-latest \
    docker-latest-logrotate docker-logrotate \
    docker-engine > /dev/null 2>&1
yum install -y yum-utils device-mapper-persistent-data lvm2 > /dev/null \
    && yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo > /dev/null \
    && yum makecache fast > /dev/null \
    && yum -y install docker-ce docker-ce-cli containerd.io > /dev/null \
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