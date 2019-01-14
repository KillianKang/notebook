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

使用 `ENTRYPOINT` 指令指定容器主进程的默认启动命令后，在启动容器时可以带参数。

在使用 `docker run` 命令启动容器时，可以使用参数 `--entrypoint` 来指定新的启动命令。 `docker run` 最后面指定的命令将作为参数传给 `ENTRYPOINT` 指令。

当指定了 `ENTRYPOINT` 后，`CMD` 指令就只能是**参数列表**格式， `CMD` 的内容将作为参数传给 `ENTRYPOINT` 指令。

`ENTRYPOINT` 指令可让镜像变成可带参数的命令使用：

```Dockerfile
FROM ubuntu:18.04
RUN apt-get update \
    && apt-get install -y curl \
    && rm -rf /var/lib/apt/lists/*
ENTRYPOINT [ "curl", "-s", "https://ip.cn" ]
```

```bash
$ docker run myip
当前 IP：61.148.226.66 来自：北京市 联通

$ docker run myip -i
HTTP/1.1 200 OK
Server: nginx/1.8.0
Date: Tue, 22 Nov 2016 05:12:40 GMT
Content-Type: text/html; charset=UTF-8
Vary: Accept-Encoding
X-Powered-By: PHP/5.6.24-1~dotdeb+7.1
X-Cache: MISS from cache-2
X-Cache-Lookup: MISS from cache-2:80
X-Cache: MISS from proxy-2_6
Transfer-Encoding: chunked
Via: 1.1 cache-2:80, 1.1 proxy-2_6:8006
Connection: keep-alive

当前 IP：61.148.226.66 来自：北京市 联通
```

跟在最后面的 `-i` 不再是命令，而是作为参数传给 `ENTRYPOINT` 指令。

作为附带脚本的入口点：

```Dockerfile
FROM alpine:3.4
...
RUN addgroup -S redis && adduser -S -G redis redis
...
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 6379
CMD [ "redis-server" ]
```

其中先是创建了 redis 用户，然后指定了 `ENTRYPOINT` 为 `docker-entrypoint.sh` 脚本。

```bash
#!/bin/sh
...
# allow the container to be started with `--user`
if [ "$1" = 'redis-server' -a "$(id -u)" = '0' ]; then
    chown -R redis .
    exec su-exec redis "$0" "$@"
fi

exec "$@"
```

该脚本根据 `CMD` 的内容来进行对应的操作，如果是 `redis-server` 的话，则切换到 `redis` 用户身份启动服务器，否则依旧使用 `root` 身份执行。

### ENV 设置环境变量

- `ENV <key> <value>`
- `ENV <key1>=<value1> <key2>=<value2>...`

```Dockerfie
ENV VERSION=1.0 DEBUG=on \
    NAME="Happy Feet"
```

设置容器中的环境变量，当变量值中含有空格时，需要使用双引号括起来。定义了环境变量后，后续的指令也可以使用这个环境变量，如以下指令：`RUN`、`ADD`、`COPY`、`ENV`、`EXPOSE`、`LABEL`、`USER`、`WORKDIR`、`VOLUME`、`STOPSIGNAL`、`ONBUILD`。

### ARG 构建参数

* `ARG <参数名>[=<默认值>]`

`ARG` 指令用来定义参数名称和其默认值，该默认值可以在构建命令 `docker build` 中用 `--build-arg <参数名>=<值>` 来覆盖。该参数只可以在构建时（即 `Dockerfile` 文件）使用，容器中不会存在这些参数。但可以通过 `docker history` 看到这些值。

在 1.13 之前的版本，要求 `--build-arg` 中的参数名，必须在 `Dockerfile` 中用 `ARG` 定义过了，换句话说，就是 `--build-arg` 指定的参数，必须在 `Dockerfile` 中使用了。如果对应参数没有被使用，则会报错退出构建。从 1.13 开始，这种严格的限制被放开，不再报错退出，而是显示警告信息，并继续构建。这对于使用 CI 系统，用同样的构建流程构建不同的 `Dockerfile` 的时候比较有帮助，避免构建命令必须根据每个 Dockerfile 的内容修改。

### VOLUME 定义匿名卷

- `VOLUME ["<路径1>", "<路径2>"...]`
- `VOLUME <路径>`

容器运行时应该尽量保持容器存储层不发生写操作，对于数据库类需要保存动态数据的应用，其数据库文件应该通过 `docker run` 命令中 `-v` 参数将本地目录挂载为镜像的数据卷(volume)来保存动态数据。

为了防止运行时用户忘记将动态文件所保存目录挂载为卷，在 `Dockerfile` 中，可以事先指定某些目录挂载为匿名卷，这样在运行时如果用户忘记挂载，应用也可以正常运行，并且不会向容器存储层写入大量数据。

```Dockerfile
VOLUME /data
```

容器中的 `/data` 目录在容器运行时自动挂载为匿名卷，任何向 `/data` 中写入的数据都不会记录进容器存储层，从而保证了容器存储层的无状态化。通过 `docker volume ls` 命令可以查看到匿名卷。

### EXPOSE 声明端口

* `EXPOSE <端口1> [<端口2>...]`

`EXPOSE` 指令用来声明运行时容器提供的服务端口，这只是一个声明，在运行时并不会因为这个声明而开启端口，也不会进行端口映射。但是通过 `docker run` 命令中 `-P` 参数可以随机映射宿主端口到 `EXPOSE` 的端口。使用 `-p <宿主端口>:<容器端口>` 可以自定义宿主到容器的端口映射。

### WORKDIR 指定工作目录

* `WORKDIR <工作目录路径>`

`WORKDIR` 指令用来指定容器启动时的默认工作目录，如果目录不存在会自动创建。

### USER 指定当前用户

* `USER <用户名>[:<用户组>]`

`USER` 指令用来指定容器启动时的默认登陆用户，因此指定后后续命令都会使用这个用户执行。`USER` 只进行用户的切换，这个用户必须事先建立好，否则无法切换。

```Dockerfile
RUN groupadd -r redis && useradd -r -g redis redis
USER redis
RUN [ "redis-server" ]
```

### HEALTHCHECK 健康检查

- `HEALTHCHECK [选项] CMD <命令>`：设置检查容器健康状况的命令
- `HEALTHCHECK NONE`：如果基础镜像有健康检查指令，可使用该指令屏蔽

在没有 `HEALTHCHECK` 指令前，Docker 引擎只能通过容器内主进程是否退出来判断容器是否状态异常。当容器主进程进入死锁状态，或者死循环状态，应用进程并不退出，但是该容器已经无法提供服务。

当一个镜像指定了 `HEALTHCHECK` 指令后，启动容器时，初始状态为 `starting`，在 `HEALTHCHECK` 指令检查成功后变为 `healthy`，如果连续一定次数失败，则会变为 `unhealthy`。

`HEALTHCHECK` 支持下列选项：

- `--interval=<间隔>`：两次健康检查的间隔，默认为 30 秒；
- `--timeout=<时长>`：健康检查命令运行超时时间，如果超过这个时间，本次健康检查就被视为失败，默认 30 秒；
- `--retries=<次数>`：当连续失败指定次数后，则将容器状态视为 `unhealthy`，默认 3 次。

和 `CMD`, `ENTRYPOINT` 一样，`HEALTHCHECK` 只可以出现一次，如果写了多个，只有最后一个生效。

命令的返回值决定了该次健康检查是否成功：

* `0`：成功
* `1`：失败
* `2`：保留（建议不要使用这个值）

```Dockerfile
FROM nginx
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
HEALTHCHECK --interval=5s --timeout=3s \
  CMD curl -fs http://localhost/ || exit 1
```

示例中设置了每 5 秒检查一次，如果健康检查命令超过 3 秒没响应就视为失败，并且使用 `curl -fs http://localhost/ || exit 1` 作为健康检查命令。

为了帮助排障，健康检查命令的输出（包括 `stdout` 以及 `stderr`）都会被存储于健康状态里，可以用 `docker inspect` 来查看。

```bash
$ docker build -t myweb:v1 .
$ docker run -d --name web -p 80:80 myweb:v1
$ docker inspect --format '{{json .State.Health}}' web | python -m json.tool
{
    "FailingStreak": 0,
    "Log": [
        {
            "End": "2016-11-25T14:35:37.940957051Z",
            "ExitCode": 0,
            "Output": "<!DOCTYPE html>\n<html>\n<head>\n<title>Welcome to nginx!</title>\n<style>\n    body {\n        width: 35em;\n        margin: 0 auto;\n        font-family: Tahoma, Verdana, Arial, sans-serif;\n    }\n</style>\n</head>\n<body>\n<h1>Welcome to nginx!</h1>\n<p>If you see this page, the nginx web server is successfully installed and\nworking. Further configuration is required.</p>\n\n<p>For online documentation and support please refer to\n<a href=\"http://nginx.org/\">nginx.org</a>.<br/>\nCommercial support is available at\n<a href=\"http://nginx.com/\">nginx.com</a>.</p>\n\n<p><em>Thank you for using nginx.</em></p>\n</body>\n</html>\n",
            "Start": "2016-11-25T14:35:37.780192565Z"
        }
    ],
    "Status": "healthy"
}
```

### ONBUILD 延后执行

`ONBUILD` 是一个特殊的指令，它后面跟的是其它指令，比如 `RUN`, `COPY` 等，而这些指令，在当前镜像构建时并不会被执行。只有当以当前镜像为基础镜像，去构建下一级镜像的时候才会被执行。

例如在制作使用 Node.js 所写的应用镜像时，由于 Node.js 使用 `npm` 进行包管理，所有依赖、配置、启动信息等都会放到 `package.json` 文件里。在拿到程序代码后，需要先进行 `npm install` 才能获得所需要的依赖。然后就可以通过 `npm start` 来启动应用。因此如果要制作多个不同的这类镜像就得写多个 `Dockerfile` 文件，这个就可以使用 `ONBUILD` 指令合并为一个  `Dockerfile` 文件。

```Dockerfile
FROM node:slim
RUN mkdir /app
WORKDIR /app
ONBUILD COPY ./package.json /app
ONBUILD RUN [ "npm", "install" ]
ONBUILD COPY . /app/
CMD [ "npm", "start" ]
```

这样各个 Node.js 项目的 `Dockerfile` 文件就变成了简单地：

```Dockerfile
FROM my-node
```

当在各个项目目录中，用这个只有一行的 `Dockerfile` 构建镜像时，之前基础镜像的那三行 `ONBUILD` 就会开始执行，成功的将当前项目的代码复制进镜像、并且针对本项目执行 `npm install`，生成应用镜像。