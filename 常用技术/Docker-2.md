# 定制容器和私有仓库
## 创建Docker容器
* docker官方和个人发布的镜像由于版本等各种原因，漏洞较多，那我们如何自己从头开始做个定制的镜像呢？
* 参考脚本：
        
        https://raw.githubusercontent.com/docker/docker/master/contrib/mkimage-yum.sh
* 主要是如下几步：

        1．tmp目录下建立临时目录和文件系统
        2．使用yum安装相关的软件包
        3．软件包安装和信息定制
        4．tar打包
        5．清理
* 建立目录结构[rootfs]
 
        target=(mktemp−d−−tmpdir
        (basename $0).XXXXXX)
        
        set -x
        
        mkdir -m 755 "$target"/dev
        mknod -m 600 "$target"/dev/console c 5 1
        mknod -m 600 "$target"/dev/initctl p
        mknod -m 666 "$target"/dev/full c 1 7
        mknod -m 666 "$target"/dev/null c 1 3
        mknod -m 666 "$target"/dev/ptmx c 5 2
        mknod -m 666 "$target"/dev/random c 1 8
        mknod -m 666 "$target"/dev/tty c 5 0
        mknod -m 666 "$target"/dev/tty0 c 4 0
        mknod -m 666 "$target"/dev/urandom c 1 9
        mknod -m 666 "$target"/dev/zero c 1 5
        
        # amazon linux yum will fail without vars set
        if [ -d /etc/yum/vars ]; then
        mkdir -p -m 755 "$target"/etc/yum
        cp -a /etc/yum/vars "$target"/etc/yum/
        fi
* 软件包安装和信息定制

        yum -c "yumconfig"−−installroot="
        target" --releasever=/ --setopt=tsflags=nodocs \
            --setopt=group_package_types=mandatory -y groupinstall Core
        yum -c "yumconfig"−−installroot="
        target" -y clean all
        ...
* 打包

        tar --numeric-owner -c -C "target".|dockerimport−
        name:$version
        docker run -i -t name:
        version echo success
* 清理
        
        rm -rf "$target"
>如果我们需要自己的安全增强软件等定制，只需要在第2步将我们的内容合并进去即可生成的镜像可以作为我们工作的基础，当然你也可以push到开源社区

### 制作镜像：
* 执行脚本：

        ./makeimage-yum.sh -y /etc/yum.conf centos72
* 查看docker镜像

        [root@docker-1 ~]# docker images
        REPOSITORY    TAG           IMAGE ID         CREATED            SIZE
        centos72     7.2.1511     fb2f5997854a        About a minute ago   245.1 MB


## 定制容器
* dockerfile是为快速构建docker image而设计的，当你使用docker　build 命令的时候，docker 会读取当前目录下的命名为Dockerfile(首字母大写)的纯文本文件并执行里面的指令构建出一个docker image。
* 而另一种构建docker iamge 的方法是pull一些基础镜像下来启动成容器，然后进入容器内安装各种需要的程序以及配置好需要的环境，最后commit成一个镜像。但是相比之 Dockerfile的方法会更加自动化，更加方便快捷，而且功能也更强大。（Docker build方法底层里也是在基础镜像下启动容器然后commit的，但是这些不需要我们手动去commit以及rm，都是自动化的。）
### Dockerfile
* Dockerfile是由一系列命令和参数构成的脚本，这些命令应用于基础镜像并最终创建一个新的镜像。它们简化了从头到尾的流程并极大的简化了部署工作。Dockerfile从FROM命令开始，紧接着跟随者各种方法，命令和参数。其产出为一个新的可以用于创建容器的镜像。
### Dockerfile 语法
* 在我们深入讨论Dockerfile之前，让我们快速过一下Dockerfile的语法和它们的意义。
#### 什么是语法？
* 非常简单，在编程中，语法意味着一个调用命令，输入参数去让应用执行程序的文法结构。这些语法被规则或明或暗的约束。程序员遵循语法规范以和计算机 交互。如果一段程序语法不正确，计算机将无法识别。Dockerfile使用简单的，清楚的和干净的语法结构，极为易于使用。这些语法可以自我释义，支持注释。
#### Dockerfile 语法示例
>Dockerfile语法由两部分构成，注释和命令+参数

    # Line blocks used for commenting
    command argument argument ..
    一个简单的例子：
    # Print "Hello docker!"
    RUN echo "Hello docker!"
#### Dockerfile 命令
* Dockerfile有十几条命令可用于构建镜像，下文将简略介绍这些命令。
1. ADD

        ADD命令有两个参数，源和目标。它的基本作用是从源系统的文件系统上复制文件到目标容器的文件系统。如果源是一个URL，那该URL的内容将被下载并复制到容器中。
        # Usage: ADD [source directory or URL] [destination directory]
        ADD /my_app_folder /my_app_folder 
2. CMD

        和RUN命令相似，CMD可以用于执行特定的命令。和RUN不同的是，这些命令不是在镜像构建的过程中执行的，而是在用镜像构建容器后被调用。
        # Usage 1: CMD application "argument", "argument", ..
        CMD "echo" "Hello docker!"
3. ENTRYPOINT

        ENTRYPOINT 帮助你配置一个容器使之可执行化，如果你结合CMD命令和ENTRYPOINT命令，你可以从CMD命令中移除“application”而仅仅保留参数，参数将传递给ENTRYPOINT命令。
        # Usage: ENTRYPOINT application "argument", "argument", ..
        # Remember: arguments are optional. They can be provided by CMD
        # or during the creation of a container.
        ENTRYPOINT echo
        # Usage example with CMD:
        # Arguments set with CMD can be overridden during *run*
        CMD "Hello docker!"
        ENTRYPOINT echo
4. ENV 

        ENV命令用于设置环境变量。这些变量以”key=value”的形式存在，并可以在容器内被脚本或者程序调用。这个机制给在容器中运行应用带来了极大的便利。
        # Usage: ENV key value
        ENV SERVER_WORKS 4
5. EXPOSE

        EXPOSE用来指定端口，使容器内的应用可以通过端口和外界交互。
        # Usage: EXPOSE [port]
        EXPOSE 8080
6. FROM

        FROM命令可能是最重要的Dockerfile命令。改命令定义了使用哪个基础镜像启动构建流程。基础镜像可以为任意镜 像。如果基础镜像没有被发现，Docker将试图从Docker image index来查找该镜像。FROM命令必须是Dockerfile的首个命令。
        # Usage: FROM [image name]
        FROM ubuntu 
7. MAINTAINER

        我建议这个命令放在Dockerfile的起始部分，虽然理论上它可以放置于Dockerfile的任意位置。这个命令用于声明作者，并应该放在FROM的后面。
        # Usage: MAINTAINER [name]
        MAINTAINER authors_name 
8. RUN

        RUN命令是Dockerfile执行命令的核心部分。它接受命令作为参数并用于创建镜像。不像CMD命令，RUN命令用于创建镜像（在之前commit的层之上形成新的层）。
        # Usage: RUN [command]
        RUN aptitude install -y riak
9. USER

        USER命令用于设置运行容器的UID。
        # Usage: USER [UID]
        USER 751
10. VOLUME

        VOLUME命令用于让你的容器访问宿主机上的目录。
        # Usage: VOLUME ["/dir_1", "/dir_2" ..]
        VOLUME ["/my_files"]
11. WORKDIR

        WORKDIR命令用于设置CMD指明的命令的运行目录。
        # Usage: WORKDIR /path
        WORKDIR ~/
### 如何使用Dockerfiles
    使用Dockerfiles和手工使用Docker Daemon运行命令一样简单。脚本运行后输出为新的镜像ID。
    # Build an image using the Dockerfile at current location
    # Example: sudo docker build -t [name] .
    sudo docker build -t my_mongodb . 

### DockerFile 实例：(vim  /root/ Dockerfile/Dockerfile)
    # Pull base image
    FROM centos72:7.2.1511

    MAINTAINER chenglin xu "chenglinxu@xxx.com"

    # Install sshd sudo
    RUN yum install -y openssh-server sudo  httpd 
    RUN sed -i 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config  
    RUN yum clean all
    # 下面这两句比较特殊，在centos6上必须要有，否则创建出来的容器sshd不能登录  

    RUN ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key  
    RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key  

    # 添加测试用户admin，密码admin，并且将此用户添加到sudoers里  
    RUN useradd admin  
    RUN echo "root:root"| chpasswd
    RUN echo "admin:admin" | chpasswd  
    RUN echo "admin   ALL=(ALL)       ALL" >> /etc/sudoers  

    #注意这里的 run.sh是额外执行的脚本
    ADD run.sh /run.sh
    RUN chmod 755 /run.sh

    #pub key
    RUN mkdir -p /var/run/sshd
    CMD /run.sh
    EXPOSE 80
    EXPOSE 22

#### Run.sh 
    #!/bin/bash
    /usr/sbin/httpd 
    /usr/sbin/sshd –D

#### build
    [root@docker-1 Dockerfile]# pwd
    /root/Dockerfile
    [root@docker-1 Dockerfile]# docker build -t="centos72:Http" ./

#### 查看
    [root@docker-1 Dockerfile]# docker images
    REPOSITORY     TAG            IMAGE ID            CREATED             SIZE
    centos72       Http         d31e4d43651e        15 minutes ago      366.1 MB

#### 运行和测试
    [root@docker-1 Dockerfile]# docker run -itd -p 8081:80 -p 2222:22 d31e
    [root@docker-1 Dockerfile]# ssh admin@192.168.183.130 -p 2222
    admin@192.168.183.130's password: 
    [admin@7a81cc11b589 ~]$

![](../images/Docker/3.png)

## 私有仓库
* 和Mavan的管理一样，Dockers不仅提供了一个中央仓库，同时也允许我们使用registry搭建本地私有仓库。
* 使用私有仓库有许多优点：
    1. 节省网络带宽，针对于每个镜像不用每个人都去中央仓库上面去下载，只需要从私有仓库中下载即可；
    2. 提供镜像资源利用，针对于公司内部使用的镜像，推送到本地的私有仓库中，以供公司内部相关人员使用。

* 接下来我们就大致说一下如何在本地搭建私有仓库。
* 目前Docker Registry已经升级到了v2，最新版的Docker已不再支持v1。* * * Registry v2使用Go语言编写，在性能和安全性上做了很多优化，重新设计了镜像的存储格式。此文档是在v1的基础上写的，如果需要安装registry v2，只需下载* * registry:2.2即可，或者可以下载后面的安装脚本运行安装。	

### 基本步骤
1. 获取最新的registry的容器

        了解到目前最新版为2.4.1，于是直接使用docker pull命令从公用仓库去拉即可
        [root@docker-1 Dockerfile]# docker pull registry:2.4.1
2. 运行registry:2.4.1容器

        这里需要注意的是新registry仓库数据目录的位置。新registry的仓库目录是在/var/lib/registry，所以运行时挂载目录需要注意
        [root@docker-1 Dockerfile]# mkdir /root/datadocker
        [root@docker-1 Dockerfile]# chmod 777 /root/datadocker/
        [root@docker-1 Dockerfile]# docker run -d -p 5000:5000 --restart=always -v /root/datadocker/:/var/lib/registry/ registry:2.4.1  
        -v选项指定将/opt/registry-var/目录挂载给/var/lib/registry/
        当使用curl http://192.168.0.100:5000/v2/_catalog能看到json格式的返回值时，说明registry已经运行起来了。
        [root@docker-1 Dockerfile]# curl http://192.168.183.130:5000/v2/_catalog
        {"repositories":[]}
3. 修改配置文件以指定registry地址

        上面registry虽然已经运行起来了，但是如果想用push命令上传镜像是会报错的，需要在配置文件中指定registry的地址。在/etc/sysconfig/docker文件中添加一下配置：
        ADD_REGISTRY='--insecure-registry 192.168.183.130:5000'  
        为了配置简单，省去安全相关的配置，这里使用--insecure-registry选项。
        修改配置文件后，一定要重启docker服务才能生效，所以：
        [root@docker-1 Dockerfile]# systemctl restart docker.service
        这时再push就可以上传镜像到所搭建的registry仓库了。需要注意的是，上传前要先给镜像tag一个192.168.183.130:5000/为前缀的名字，这样才能在push的时候存到私库。
        [root@docker-1 Dockerfile]# docker tag centos72:Http 192.168.183.130:5000/chttp72
        [root@docker-1 Dockerfile]# docker images
        REPOSITORY                   TAG     IMAGE ID     CREATED      SIZE
        192.168.183.130:5000/chttp72   latest  d31e4d43651e   4 hours ago   366.1 MB
4. Docker其他主机接入私有仓库

        在/etc/sysconfig/docker文件中添加一下配置：
        ADD_REGISTRY='--insecure-registry 192.168.183.130:5000'  
        修改配置文件后，一定要重启docker服务才能生效，所以：
        [root@docker-2 ~]# systemctl restart docker.service
        [root@docker-2 ~]# docker pull 192.168.183.130:5000/chttp72
        Using default tag: latest
5. 配置带用户权限的registry

        到上面为止，registry已经可以使用了。如果想要控制registry的使用权限，使其只有在登录用户名和密码之后才能使用的话，还需要做额外的设置。
        registry的用户名密码文件可以通过htpasswd来生成：
        [root@docker-1 Dockerfile]#mkdir –p /opt/registry-var/auth/  
        [root@docker-1 Dockerfile]# docker run --entrypoint htpasswd registry:2.4.1 -Bbn xuchenglin xuchenglin >> /opt/registry-var/auth/htpasswd
        面这条命令是为xuchenglin用户名生成密码为xuchenglin的一条用户信息，存在/opt/registry-var/auth/htpasswd文件里面，文件中存的密码是被加密过的。
        使用带用户权限的registry时候，容器的启动命令就跟上面不一样了，将之前的容器停掉并删除，然后执行下面的命令：
        [root@docker-1 Dockerfile]#  docker run -d -p 5000:5000 --restart=always -v /opt/registry-var/auth/:/auth/ -e "REGISTRY_AUTH=htpasswd"  -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm"  -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd  -v /root/datadocker/:/var/lib/registry/ registry:2.4.1
        [root@docker-1 Dockerfile]# curl http://192.168.183.130:5000/v2/_catalog
        {"errors":[{"code":"UNAUTHORIZED","message":"authentication required","detail":[{"Type":"registry","Name":"catalog","Action":"*"}]}]}
        [root@docker-1 Dockerfile]# curl http://xuchenglin:xuchenglin@192.168.183.130:5000/v2/_catalog
        {"repositories":["chttp72"]}
6. 如果直接想查看仓库信息、pull或push都会出现权限报错。必须先使用docker login 命令来登录私有仓库：

        [root@docker-2 ~]#docker login 192.168.183.130:5000
        Username (xuchenglin): xuchenglin
        Password: 
        WARNING: login credentials saved in /root/.docker/config.json
        Login Succeeded
        根据提示，输入用户名和密码即可。如果登录成功，会在/root/.docker/config.json文件中保存账户信息，这样就可以继续使用了
        [root@docker-2 ~]#  curl http://xuchenglin:xuchenglin@192.168.183.130:5000/v2/_catalog
        {"repositories":["chttp-apache","chttp72"]}
        [root@docker-2 ~]# cat /root/.docker/config.json 
        {
            "auths": {
                "192.168.183.130:5000": {
                    "auth": "eHVjaGVuZ2xpbjp4dWNoZW5nbGlu",
                    "email": "xuchenglin@123.com"
                }
            }
        }
        通过 容器 log 查看容器日志
        [root@docker-1 Dockerfile]# docker logs 611f62f6338c
        192.168.183.139 - - [25/Nov/2016:08:29:32 +0000] "GET /v2/_catalog HTTP/1.1" 200 44 "" "curl/7.29.0"
>如果容器无法启动或者出现异常都可以通过 logs 来查看容器的日志信息。

## 总结
