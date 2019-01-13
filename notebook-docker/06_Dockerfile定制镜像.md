# 一、使用 Dockerfile 构建镜像

### Dockerfile 介绍

Dockerfile 是一个文本文件，文件中是一条条的**指令(Instruction)**，每一条指令构建一层镜像，因此每一条指令的内容，就是描述该层是如何构建。

在编写 Dockerfile 文件时，应该确保每一层都只添加真正需要添加的东西，任何无关的东西都应该避免加入或者在构建当前层前清理掉。

Dockerfile 支持 Shell 类的行尾添加 `\` 的命令换行方式，以及行首 `#` 进行注释的格式。

### docker build 命令

```bash
docker build [选项] <上下文路径/URL/->
```

`docker build` 命令用来构建镜像，例如：

```bash
$ docker build -t nginx:v3 .
Sending build context to Docker daemon 2.048 kB
Step 1 : FROM nginx
 ---> e43d811ce2f4
Step 2 : RUN echo '<h1>Hello, Docker!</h1>' > /usr/share/nginx/html/index.html
 ---> Running in 9cdc27646c7b
 ---> 44aa4490ce2c
Removing intermediate container 9cdc27646c7b
Successfully built 44aa4490ce2c
```

从命令的输出结果中，可以清晰的看到镜像的构建过程。在 `Step 2` 中，`RUN` 指令先是启动了一个容器 `9cdc27646c7b`，接着执行了所要求的命令，并提交了这一层 `44aa4490ce2c`，随后删除了所用到的这个容器 `9cdc27646c7b`。

`-t`: 指定镜像名。`.` 为镜像构建的上下文路径。

### 镜像构建时的上下文路径

要理解上下文路径，首先要理解 `docker build` 的工作原理。Docker 在运行时分为 Docker 引擎和客户端工具。Docker 引擎提供了一组 REST API，被称为 [Docker Remote API](https://docs.docker.com/develop/sdk/)，而如 `docker` 命令这样的客户端工具，则是通过这组 API 与 Docker 引擎交互，从而完成各种功能。因此，虽然表面上好像是在本机执行各种 `docker` 功能，但实际上，一切都是使用的远程调用形式在服务端（Docker 引擎）完成的。

在构建镜像的时候，经常需要使用 `COPY` 等指令将一些本地文件复制进镜像，而 `docker build` 命令构建镜像，并非在本地构建，而是在服务端，也就是 Docker 引擎中构建的。因此，在构建镜像的时候，用户需要指定构建镜像的上下文路径，`docker build` 命令得知这个路径后，会将路径下的所有内容打包上传给 Docker 引擎。这样 Docker 引擎收到这个上下文包后，展开就会获得构建镜像所需的一切文件。

如：

```Dockerfile
COPY ./package.json /app/
```

表示将**上下文**目录下的 `package.json` 文件复制进镜像里的 `/app/` 目录下。

从 `docker build` 的输出中也可以看到上下文的发送过程：

```bash
$ docker build -t nginx:v3 .
Sending build context to Docker daemon 2.048 kB
...
```

因此，在构建镜像时，应该先将 `Dockerfile` 置于一个空目录下，然后再将构建镜像所需要的文件复制到该目录下，再进行构建。如果希望目录下的一些文件不传给 Docker 引擎，那么可以用 `.gitignore` 一样的语法写一个 `.dockerignore`，用来剔除不需要作为上下文传递给 Docker 引擎的文件。

这只是默认行为，实际上 `Dockerfile` 的文件名并不要求必须为 `Dockerfile`，而且也不要求必须位于上下文目录中，比如可以用 `-f ../Dockerfile.php` 参数指定某个文件作为 `Dockerfile`。如果不额外指定 `Dockerfile` 的话，就会将上下文目录下名为 `Dockerfile` 的文件作为 Dockerfile。

# 二、Dockerfile 指令详解

### FROM 指定基础镜像

定制镜像时，一定是以一个镜像为基础，在其上进行定制。而 `FROM` 就是用来指定**基础镜像**，因此一个 `Dockerfile` 中 `FROM` 是必备的指令，并且必须是第一条指令。

特殊镜像 `scratch`，它表示一个空白的镜像，这个镜像是虚拟的概念，并不实际存在。

```dockerfile
FROM scratch
```

如果以 `scratch` 为基础镜像的话，意味着不以任何镜像为基础，接下来所写的指令将作为镜像的第一层。

### RUN 执行命令行命令

* **shell** 格式：`RUN <命令>`

```Dockerfile
RUN echo '<h1>Hello, Docker!</h1>' > /usr/share/nginx/html/index.html
```

* **exec** 格式：`RUN ["可执行文件", "参数1", "参数2"]`

```Dockerfile
RUN echo '<h1>Hello, Docker!</h1>' > /usr/share/nginx/html/index.html
```

错误示范：

```dockerfile
FROM debian:stretch

RUN apt-get update
RUN apt-get install -y gcc libc6-dev make wget
RUN wget -O redis.tar.gz "http://download.redis.io/releases/redis-5.0.3.tar.gz"
RUN mkdir -p /usr/src/redis
RUN tar -xzf redis.tar.gz -C /usr/src/redis --strip-components=1
RUN make -C /usr/src/redis
RUN make -C /usr/src/redis install
```

Dockerfile 中每一条指令都会构建一层镜像，其执行过程为新建一层，在其上执行一条指令，执行结束后，`commit` 这一层的修改，构成新的镜像。因此重复的使用指令是不正确的，这样会将很多运行时不需要的东西装入镜像，还会构建很多没有意义的层，而 **Union FS** 是有最大层数限制的。

正确示范：

```dockerfile
FROM debian:stretch

RUN buildDeps='gcc libc6-dev make wget' \
    && apt-get update \
    && apt-get install -y $buildDeps \
    && wget -O redis.tar.gz "http://download.redis.io/releases/redis-5.0.3.tar.gz" \
    && mkdir -p /usr/src/redis \
    && tar -xzf redis.tar.gz -C /usr/src/redis --strip-components=1 \
    && make -C /usr/src/redis \
    && make -C /usr/src/redis install \
    && rm -rf /var/lib/apt/lists/* \
    && rm redis.tar.gz \
    && rm -r /usr/src/redis \
    && apt-get purge -y --auto-remove $buildDeps
```

在撰写 Dockerfile 的时候，要经常提醒自己，这并不是在写 Shell 脚本，而是在定义每一层该如何构建，并且在每一条命令组的最后要添加清理工作的命令，一定要确保每一层只添加真正需要添加的东西，任何无关的东西都应该清理掉。

### COPY 复制文件到镜像

- `COPY [--chown=<user>:<group>] <源路径>... <目标路径>`

```Dockerfile
COPY hom?.txt /mydir/
```

- `COPY [--chown=<user>:<group>] ["<源路径1>",... "<目标路径>"]`

```Dockerfile
COPY --chown=myuser:mygroup files* /mydir/
```

`<源路径>` 是上下文中的相对路径，可以是多个文件，还可以使用通配符。

`<目标路径>` 可以是容器内的绝对路径，也可以是相对于容器工作目录的相对路径。

目标路径不需要事先创建，如果不存在会自动创建。此外，使用 `COPY` 指令，源文件的各种元数据都会保留。比如读、写、执行权限、文件变更时间等。

### ADD 更高级的复制文件

如果 `<源路径>` 为一个 `tar` 压缩文件的话，压缩格式为 `gzip`, `bzip2` 以及 `xz` 的情况下，`ADD` 指令将会自动解压缩这个压缩文件到 `<目标路径>` 去。

不推荐使用 `ADD` 命令，只有在需要自动解压缩的场合才适合使用该命令。

```Dockerfile
ADD ubuntu-xenial-core-cloudimg-amd64-root.tar.gz /
```

### CMD 容器启动命令

容器是进程，因此在启动容器的时候，需要指定所运行的程序及参数。`CMD` 指令就是用来指定容器主进程的默认启动命令。在使用 `docker run` 启动容器时，可以指定新的命令替换默认启动命令。

- **shell** 格式：`CMD <命令>`
- **exec** 格式：`CMD ["可执行文件", "参数1", "参数2"...]`
- **参数列表** 格式：`CMD ["参数1", "参数2"...]`。在指定了 `ENTRYPOINT` 指令后，用 `CMD` 指定具体的参数。

推荐使用 `exec` 指令格式，这类格式在解析时会被解析为 JSON 数组，因此一定要使用双引号 `"`。

如果使用 `shell` 格式的话，实际的命令会被包装为 `sh -c` 的参数的形式进行执行。比如：

```Dockerfile
CMD echo $HOME
```

在实际执行中，会将其变更为：

```Dockerfile
CMD [ "sh", "-c", "echo $HOME" ]
```

这就是为什么我们可以使用环境变量的原因，因为这些环境变量会被 shell 进行解析处理。

Docker 不是虚拟机，容器中的应用都是以前台的形式执行，容器中没有后台服务的概念，如果容器主进程退出，容器便会退出。

因此不能通过如下形式来进行后台程序启动：

```Dockerfile
CMD service nginx start
```

`CMD service nginx start` 会被理解为 `CMD [ "sh", "-c", "service nginx start"]`，因此主进程实际上是 `sh`。那么当 `service nginx start` 命令结束后，`sh` 也就结束了，`sh` 作为主进程退出，自然就会令容器退出。

正确的做法是直接执行 `nginx` 可执行文件，并且要求以前台形式运行。比如：

```Dockerfile
CMD ["nginx", "-g", "daemon off;"]
```

### ENTRYPOINT 入口点

使用 `ENTRYPOINT` 命令指定容器主进程的默认启动命令后，在启动容器时可以带参数。