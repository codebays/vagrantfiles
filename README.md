# vagrantfiles
使用Vagrant搭建各种开发配置环境。教程: https://www.codebays.com

### 介绍
【[Vagrant](https://www.vagrantup.com/)】是一个虚拟机环境管理工具，他能够将整个虚拟机打包成一个一个的box，然后只需要简单的运行`vagrant up`就可以启动一个完全一样的虚拟机。

### 运行

* 安装VirtualBox
* 安装Vagrant
* 下载Box
* 添加box到Vagrant，命令: `vagrant box add xxx.box --name xxx/mybox`
* 安装Vagrant插件，命令: `vagrant plugin install [--local] 插件名`
* 修改配置文件Vagrantfile
* 启动机器`vagrant up`

### 教程

* 第一篇《[【VAGRANT】- 统一团队开发环境利器 (安装篇)](https://www.codebays.com/server/40.html)》介绍了Vagrant如何安装，本文介绍Box使用。
* 第二篇《[【VAGRANT】- 统一团队开发环境利器 (BOX教程)](https://www.codebays.com/server/152.html)》介绍Box的添加，更新，删除，以及.box文件基础格式。
* 第三篇《[【VAGRANT】- 统一团队开发环境利器 (虚拟机教程)](https://www.codebays.com/server/153.html)》介绍虚拟机的启动，暂停，SSH等。
* 第四篇《[【VAGRANT】- 统一团队开发环境利器 (共享目录)](https://www.codebays.com/server/154.html)》介绍共享目录设置相关。
* 第五篇《[【VAGRANT】- 统一团队开发环境利器 (网络配置)](https://www.codebays.com/server/155.html)》介绍网络配置相关。
* 第六篇《[【VAGRANT】- 统一团队开发环境利器 (Provision)](https://www.codebays.com/server/157.html)》介绍Provision配置。
* 第七篇《[【VAGRANT】- 统一团队开发环境利器 (插件管理)](https://www.codebays.com/server/158.html)》介绍插件管理相关。
* 第八篇《[【VAGRANT】- 统一团队开发环境利器 (快照管理)](https://www.codebays.com/server/161.html)》介绍快照管理相关。

### 配置(Vagrantfile)

```
    SYSTEM: 基础系统，当前支持: centos, debian, ubuntu, alpine
    HOSTNAME: 主机名
    SNAPSHOT_DIR: 快照存储目录
    NEED_INSTALL_PLUGINS: 是否需要安装插件，"vagrant-vbguest", "vagrant-hostmanager"
    DOCKER_MIRROR：  Docker容器镜像源(可以为阿里云、网易、DaoDocker等提供的源)， 多个使用空格隔开
    DIRS: 共享目录列表："source" => "主机目录", "destination" => "虚拟机目录", "protocol" => "协议"
    PORTS: 端口映射： 虚拟机端口号 => 主机端口号
    IP: 私有IP地址
```

### box 百度网盘下载

* 百度网盘下载: https://pan.baidu.com/s/1g0IH5p2dGUfaERFa_AQ4AQ 提取码: hzj3

### 目录结构

```
    README.md 说明文件
    LICENSE 版权信息文件
    Vagrantfile Vagrant运行配置文件
    apps/ 代码目录，映射到虚拟机/apps目录
    runtimes/ 运行时目录，映射到虚拟机/runtimes
    scripts/ 各个系统中初始化shell脚本
```