# 基本概念

- 镜像（`Image`）

Docker 镜像是一个特殊的文件系统，除了提供容器运行时所需的程序、库、资源、配置等文件外，还包含了一些为运行时准备的一些配置参数（如匿名卷、环境变量、用户等）。镜像不包含任何动态数据，其内容在构建之后也不会被改变。

镜像只是一个虚拟的概念，其实际体现并非由一个文件组成，而是由一组文件系统组成，或者说，由多层文件系统联合组成。

镜像的构建采用分层存储的方式，会一层层构建，前一层是后一层的基础。每一层构建完就不会再发生改变，后一层上的任何改变只发生在自己这一层。比如，删除前一层文件的操作，实际不是真的删除前一层的文件，而是仅在当前层标记为该文件已删除。在最终容器运行的时候，虽然不会看到这个文件，但是实际上该文件会一直跟随镜像。因此，在构建镜像的时候，每一层尽量只包含该层需要添加的东西，任何额外的东西都应该在该层构建结束前清理掉。

- 容器（`Container`）

`镜像` 和 `容器` 的关系，就像是面向对象程序设计中的 `类` 和 `实例` 一样，镜像是静态的定义，类似于模板，容器是镜像运行时的实体。容器的创建是以镜像为基础层，在其上创建一个当前容器的存储层。

容器存储层的生存周期和容器一样，容器消亡时，容器存储层也随之消亡，任何保存于容器存储层的信息都会随容器删除而丢失。因此容器存储层要保持无状态化，所有的文件写入操作，都应该使用数据卷或者绑定宿主目录方式。数据卷的生存周期独立于容器，容器消亡，数据也不会丢失。

容器的实质是进程，但与直接在宿主执行的进程不同，容器进程运行于属于自己的独立的命名空间。因此容器可以拥有自己的 `root` 文件系统、网络配置和进程空间，甚至是自己的用户 ID 空间。容器内的进程是运行在一个隔离的环境里，使用起来，就好像是在一个独立于宿主的系统下操作一样。

- 仓库（`Repository`）

`Docker Registry` 是一个集中存储、分发镜像的服务，里面可以包含多个**仓库**（`Repository`），每个仓库可以包含多个**标签**（`Tag`），每个标签对应一个镜像。

一个仓库通常会包含同一个软件不同版本的镜像，而标签就常用于对应该软件的各个版本。我们可以通过 `<仓库名>:<标签>` 的格式来指定具体是这个软件哪个版本的镜像。如果不给出标签，将以 `latest` 作为默认标签。

仓库名经常以 *两段式路径* 形式出现，比如 `jwilder/nginx-proxy`，前者往往意味着 Docker Registry 多用户环境下的用户名，后者则往往是对应的软件名。

# Ubuntu18.04 安装 Docker

#### 卸载旧版本

```bash
sudo apt-get remove docker \
             docker-engine \
             docker.io
```

#### 使用 APT 安装

由于 `apt` 源使用 HTTPS 以确保软件下载过程中不被篡改。因此，首先需要添加使用 HTTPS 传输的软件包以及 CA 证书。

```bash
sudo apt-get update

sudo apt-get install \
  apt-transport-https \
  ca-certificates \
  curl \
  software-properties-common
```

为了确认所下载软件包的合法性，需要添加软件源的 `GPG` 密钥。

```bash
curl -fsSL https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
```

然后，向 `source.list` 中添加稳定版本的 Docker CE APT 镜像源。

```bash
sudo add-apt-repository \
  "deb [arch=amd64] https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu \
  $(lsb_release -cs) \
  stable"
```

#### 安装 Docker CE

```bash
sudo apt-get update

sudo apt-get install docker-ce
```

#### 启动 Docker CE

```bash
sudo service docker start
```

#### 建立 docker 用户组

默认情况下，`docker` 命令会使用 Unix socket 与 Docker 引擎通讯。而只有 `root` 用户和 `docker` 组的用户才可以访问 Docker 引擎的 Unix socket。出于安全考虑，一般 Linux 系统上不会直接使用 `root` 用户。因此，更好地做法是将需要使用 `docker` 的用户加入 `docker` 用户组。

建立 `docker` 用户组：

```bash
sudo groupadd docker
```

将需要使用 `docker` 的用户（示例为当前用户）加入 `docker` 用户组：

```bash
sudo usermod -aG docker $USER
```

#### 测试 Docker 是否安装正确

```bash
docker run hello-world
```

#### 镜像加速器

在 `/etc/docker/daemon.json` 中写入如下内容（如果文件不存在请新建该文件）

```json
{
  "registry-mirrors": [
    "https://registry.docker-cn.com"
  ]
}
```

重新启动服务

```bash
sudo service docker restart
```

#### 检查加速器是否生效

命令行执行 `docker info`，如果从结果中看到了如下内容，说明配置成功。

```bash
Registry Mirrors:
 https://registry.docker-cn.com/
```

### 参考文档

- [Docker 官方 Ubuntu 安装文档](https://docs.docker.com/install/linux/docker-ce/ubuntu/)
- [Docker 从入门都实践](https://yeasy.gitbooks.io/docker_practice/install/ubuntu.html)