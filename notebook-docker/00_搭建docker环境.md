# 一、安装虚拟机

### 安装 VirtualBox

下载地址：`https://www.virtualbox.org/wiki/Downloads`

安装地址修改为：`D:\Program\Oracle\VirtualBox\`

在 `D` 盘创建 `VirtualBox_vms` 文件夹存在虚拟机文件，创建 `Data_backups` 文件夹用作同步文件夹

`VirtualBox` 全局设定，虚拟机默认文件夹修改为：`D:\VirtualBox_vms`，取消检查更新

### 安装 Ubuntu Server 18.04

下载地址：`https://www.ubuntu.com/download/server`

* 新建虚拟机，`设置 -> 存储` 中挂载 ISO 文件，启动
* `Mirror address` 使用 `https://mirrors.tuna.tsinghua.edu.cn/ubuntu`
* 选择 `Manual` 自定义分区，`swap` 分区 4096 M，剩余空间挂载到 `/` 下
* 安装完成后，点击工具栏中的 `控制 -> 正常关机`，根据提示按回车关机
* `设置 -> 存储` 检查 ISO 是否移除
* `设置 -> 网络 -> 高级 -> 端口转发` 设置 ssh mysql redmine 的端口转发

### Ubuntu Server 18.04 基础设置

* 启动 -> 输入用户名、密码登录
* `sudo passwd root` 修改 root 用户密码
* `su` 切换到 root 用户
* `vi /etc/ssh/sshd_config` 修改 `PermitRootLogin` 为 yes 并取消注释
* `service ssh restart` 重启 ssh

### 使用 Xshell 连接，Xftp 传输

下载地址：`https://www.netsarang.com/zh/free-for-home-school/`

* 新建，主机：`localhost`，端口号：`22`
* 在 `用户身份验证` 中填写用户名、密码
* 在 `终端` 中将 `终端类型` 修改为 linux

# 二、安装 RD、Docker 环境

### 安装 VirtualBox 增强功能

* 使用 Xftp 将 `RD_Docker_Env` 文件夹传输到 `/opt` 目录下
* `cd /opt/RD_Docker_Env/` 切换到该目录
* 运行 `sh VBoxLinuxAdditionsInstall.sh`

### 安装 RD、Docker 环境

* 运行 `sh RD_Docker_EnvInstall.sh`
* 安装完成后，关机

# 三、设置共享文件夹

### 设置共享粘贴板

* `设置 -> 常规 -> 高级` 中 `共享粘贴板` 设置为 `双向`

### 设置共享文件夹

* `设置 -> 共享文件夹` 中新增：
  * 共享文件夹路径：`D:\Data_backups`
  * 勾选 `自动挂载`
  * Mount point：`/opt/Data_backups`

