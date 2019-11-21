#!/usr/bin/env ruby
# -*- coding: UTF-8 -*-
# 优化版本基础Box
=begin
    优化版本的Docker环境

    SYSTEM: 基础系统，当前支持: centos, debian, ubuntu, alpine
    HOSTNAME: 主机名
    SNAPSHOT_DIR: 快照存储目录
    NEED_INSTALL_PLUGINS: 是否需要安装插件，"vagrant-vbguest", "vagrant-hostmanager"
    DOCKER_MIRROR：  Docker容器镜像源(可以为阿里云、网易、DaoDocker等提供的源)， 多个使用空格隔开
    DIRS: 共享目录列表："source" => "主机目录", "destination" => "虚拟机目录", "protocol" => "协议"
    PORTS: 端口映射： 虚拟机端口号 => 主机端口号
    IP: 私有IP地址
=end
ENV["LC_ALL"] = "en_US.UTF-8"
IS_IN_WINDOWS = !File.exists?("/etc/hosts")

SYSTEM = "debian"
HOSTNAME = "codebays.com"
IP = "10.111.111.101"
SNAPSHOT_DIR = nil 
NEED_INSTALL_PLUGINS = true
DOCKER_MIRROR = "http://f1361db2.m.daocloud.io"
DIRS = [
    {
        "source" => "./apps",
        "destination" => "/apps",
        "protocol" => Vagrant.has_plugin?("vagrant-winnfsd") || Vagrant.has_plugin?("vagrant-alpine") ? "nfs" : nil
    },
    {
        "source" => "./runtimes",
        "destination" => "/runtimes",
        "protocol" => Vagrant.has_plugin?("vagrant-winnfsd") || Vagrant.has_plugin?("vagrant-alpine") ? "nfs" : nil
    }
]
PORTS = {
    
}
if SYSTEM == "centos" then
    BOX = "centos/7"
    BOX_URL = nil
    BOX_VERSION = nil
    SHELL_PATH = File.expand_path("./scripts/00_init_for_centos7.sh")
elsif SYSTEM == "debian" then
    BOX = "debian/buster64"
    BOX_URL = nil
    BOX_VERSION = nil
    SHELL_PATH = File.expand_path("./scripts/00_init_for_debian.sh")
elsif SYSTEM == "ubuntu" then
    BOX = "ubuntu/bionic64"
    BOX_URL = nil
    BOX_VERSION = nil
    SHELL_PATH = File.expand_path("./scripts/00_init_for_ubuntu.sh")
elsif SYSTEM == "alpine" then
    BOX = "generic/alpine38"
    BOX_URL = nil
    BOX_VERSION = nil
    SHELL_PATH = File.expand_path("./scripts/00_init_for_alpine.sh")
end
SHELL_ARGS = [DOCKER_MIRROR]

Vagrant.configure("2") do |config|
    if NEED_INSTALL_PLUGINS
        if IS_IN_WINDOWS
            if SYSTEM == "alpine" then
                config.vagrant.plugins = ["vagrant-alpine", "vagrant-hostmanager"]                    
            else
                config.vagrant.plugins = ["vagrant-vbguest", "vagrant-hostmanager", "vagrant-winnfsd"]
            end
        else
            if SYSTEM == "alpine" then
                config.vagrant.plugins = ["vagrant-alpine", "vagrant-hostmanager"]
            else
                config.vagrant.plugins = ["vagrant-vbguest", "vagrant-hostmanager"]
            end
        end
    end
    config.vagrant.sensitive = ["password"]

    config.ssh.forward_agent = true
    config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"
    config.vm.synced_folder ".", "/vagrant", disabled: true

    if Vagrant.has_plugin?("vagrant-vbguest")
        config.vbguest.auto_update = false
    end

    config.vm.define "node" do |node|
        node.vm.box = BOX
        node.vm.box_url = BOX_URL
        node.vm.box_version = BOX_VERSION
        node.vm.hostname = HOSTNAME

        node.vm.provider "virtualbox" do |vb|
            vb.name = HOSTNAME
            vb.customize ["modifyvm", :id, "--memory", "2048"]
            vb.customize ["modifyvm", :id, "--cpus", "1"]
            vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
            vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
            if SNAPSHOT_DIR != nil && File.expand_path(SNAPSHOT_DIR)
                vb.customize ["modifyvm", :id, "--snapshotfolder", File.expand_path(SNAPSHOT_DIR)]
            end
        end

        PORTS.each do |guest, host|
            node.vm.network :forwarded_port, guest: guest, host: host
        end
        node.vm.network :private_network, ip:IP

        DIRS.each do |dir|
            node.vm.synced_folder dir["source"], dir["destination"], type: dir["protocol"]
        end

        node.vm.provision :shell do |shell|
            shell.path = SHELL_PATH
            shell.args = SHELL_ARGS
        end
    end
end