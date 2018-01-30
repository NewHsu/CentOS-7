# 软件管理
## 基础知识
CentOS 软件管理
在操作系统中，我们需要安装不同的软件来满足业务的需求，基于CentOS系列的软件包成为RPM，这种软件包既可以独立的安装和卸载，也可以实用yum管理器来进行管理，同时Linux操作系统也支持源码安装，也就是tar包的包安装，为了更好的管理CentOS，还是有必要深入学习一下软件的管理。
## RPM
RPM是由红帽开发并维护的软件包管理器，该程序提供一种标准的方式来打包软件进行分发，使得软件包的安装和卸载以及管理得到大大简化。管理员可以通过RPM管理器来跟踪软件包所安装的文件。有关已经安装的RPM软件包信息保存在各个系统本地的RPM数据库中。

###### 软件包命名

|libndp-1.2-4.el7.x86_64.rpm
-
###### 1. 命名格式为：
Name-version-release.architecture

    Name：描述其内容的一个词语，例如httpd-tools
    Version：原始软件版本号1.2
    Release：基于该版本的软件包发行号，由软件包商设置，不一定是原始软件开发商(el7)
    ARCE: 编译的软件包可以运行在何种处理器架构下，”noarch”表示软件包的内容不限定架构(x86_64)

>执行安装的时候只需输入软件包名称即可，系统会安装最高版本软件，如果有多个相同的软件包名，则安装发行号最高的软件包。

###### 2.	软件包组成
软件包安装文件

    元数据信息，例如：name/version/release/arch;描述和摘要，软件包之间的依赖关系，授权信息，更改日志等等；
    安装，更新或者删除软件包时可能运行的脚本；
###### 3.	GPG签名重要性
RPM  软件包可由为其打包的组织进行数字签名，来自某一特定来源的所有软件包通常使用相同的GPG私钥签名。如果软件被改动或损坏，签名将不在有效。这可以使系统在安装软件包之前验证其完整性。

###### 4.	更新和补丁
如果系统可以连接外部网络，既可以使用Centos的互联网更新服务器来给系统打补丁，所有的软件yum源都在/etc/yum.repo.d/ 内，以CneotOS-  开头的文本文件。

###### 5.	Rpm 安装和卸载以及升级
安装软件包

    [root@localhost Packages]# rpm -ivh zsh-5.0.2-7.el7.x86_64.rpm
    warning: zsh-5.0.2-7.el7.x86_64.rpm: Header V3 RSA/SHA256 Signature, key ID f4a80eb5: NOKEY
    Preparing...                          ################################# [100%]
    Updating / installing...
    1:zsh-5.0.2-7.el7                  ################################# [100%]

安装参数解释

    -i 安装
    -h 解压rpm的时候打印50个斜条 (#)
    -v 显示详细信息
卸载软件包

    [root@localhost Packages]# rpm –e zsh

卸载参数解释

    -e 卸载软件包
升级软件包

    [root@localhost Packages]# rpm –Uvh zsh

升级参数解释

    -U 升级
    -h 解压rpm的时候打印50个斜条 (#)
    -v 显示详细信息
###### 6.	Rpm查询
查询所有已安装的软件包：
> rpm –qa 或者 rpm –qa | grep 包名

    [root@centos7 ~]# rpm -q gcc make
    package gcc is not installed
    make-3.82-21.el7.x86_64
查询软件包安装位置

    [root@centos7 ~]# rpm -ql make
    /usr/bin/gmake
    /usr/bin/make
    ……
软件包信息

    [root@centos7 ~]# rpm -qi make
    Name        : make
    Epoch       : 1
    Version     : 3.82
    Release     : 21.el7
    Architecture: x86_64
    ………………..·
未安装软件包信息使用

    rpm -qip zsh-5.0.2-7.el7.x86_64.rpm

以上的内容只是RPM的管理方式，现在用的不是很多了，因为在安装和卸载RPM的时候会出现依赖关系，情况如下：

    [root@centos7 ~]# rpm -ivh gcc-4.8.3-9.el7.x86_64.rpm
    warning: gcc-4.8.3-9.el7.x86_64.rpm: Header V3 RSA/SHA256 Signature, key ID f4a80eb5: NOKEY
    error: Failed dependencies:
    	cpp = 4.8.3-9.el7 is needed by gcc-4.8.3-9.el7.x86_64
    	glibc-devel >= 2.2.90-12 is needed by gcc-4.8.3-9.el7.x86_64
    	libmpc.so.3()(64bit) is needed by gcc-4.8.3-9.el7.x86_64
同样的情况也出现在卸载中，我们可以手动解决依赖关系，但是如果以来太多的情况下，这个就很头疼了。

通常我们在做软件包管理的时候都会使用yum来做软件包管理，方便，快捷。

## yum软件包管理器
CentOS 系统在安装以后，都会自动安装yum软件包管理器，可以从互联网上进行软件包的更新和安装更多软件，最主要的是yum管理器在安装软件包和卸载软件包的时候会自动的替我们解决依赖关系。

yum命令在多个yum源中搜索软件包和其依赖关系，yum的主配置文件为/etc/yum.conf,其他的yum源配置文件位于”/etc/yum.repo.d/”目录内。
###### yum源配置文件范例

    [root@localhost ~]# cat /etc/yum.repos.d/CentOS-Base.repo
    …….
    [base]   //源ID
    name=CentOS-$releasever – Base    //源名称
    mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=os&infra=$infra   //源地址，可以是ftp和file等等..
    #baseurl=http://mirror.centos.org/centos/$releasever/os/$basearch/
    gpgcheck=1    //gpg签名校验
    gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7  //校验公钥的位置
    ……
###### yum使用方法
列出yum源

    [root@localhost ~]# yum repolist
列出可以安装的软件组，记住是一组软件并不是某个软件包

    [root@localhost ~]# yum grouplist
组安装，安装以后就可以支撑一个服务

    [root@localhost ~]# yum groupinstall "Basic Web Server"
列出所有源的软件包，单独软件包

    [root@localhost ~]# yum list
单独软件包安装，并自动解决依赖关系，-y参数是找到软件包即自动安装，如果没有-y参数，找到软件包后需要你手动输入y进行确认。

    [root@localhost ~]# yum –y install httpd
卸载软件包，同样会解决依赖关系

    [root@localhost ~]# yum remove zsh
只下载软件包，不安装

    [root@localhost ~]# yumdownloader zsh
更新 yum update zsh  更新zsh软件包

    [root@localhost ~]# yum update zsh
 降级软件包

    [root@localhost ~]# yum downgrade zsh
搜索软件包

    [root@localhost ~]# yum search httpd
该文件隶属于哪个软件包

    [root@localhost ~]# yum provides /etc/inittab
查询软件包信息

    [root@localhost ~]# yum info zsh
清除缓存

    [root@localhost ~]# yum clean all
>以上都是常用命令，更多信息可以查看 man yum

#### 光盘yum源配置
在无法连接到互联网的内部环境中，需要安装软件包，而这个软件包又是在CentOS光盘内，即可以使用光盘做为yum源进行安装。
###### 1.	编写光盘yum源配置文件
    [root@localhost ~]# vim /etc/yum.repos.d/test.repo
    [test]
    name=test
    baseurl=file:///mnt/cdrom
    gpgcheck=0
###### 2.	创建目录并挂载光盘
    [root@localhost ~]# mkdir /mnt/cdrom/
    [root@localhost ~]# mount /dev/cdrom /mnt/cdrom/
>以上步骤完成以后，既可以使用光盘作为yum源的安装为本机提供软件包

#### 自定义yum源
如果需要安装的软件包不在光盘内或者不在制定源内，我们可以通过添加特点的软件源或者是下载rpm包自己制作yum源来完成。
###### 1.	添加其他软件源

    rpm --import http://elrepo.org/RPM-GPG-KEY-elrepo.org
    rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
>安装软件源rpm包即可使用
###### 2.	自定义软件包yum源
1：将软件包统一放到一个文件夹内，例如 mkdir /root/zsh

2：cp zsh*.rpm  /root/zsh

3: createrepo –v /root/zsh

4: 完成以后将在/root/zsh目录下产生repordata文件夹，这个文件夹就是yum要读取的信息文件夹

5：配置yum的源文件，添加新源指向文件夹即可

    [root@localhost zsh]# cat /etc/yum.repos.d/zsh.repo
    [zsh]
    name=zsdd
    baseurl=file:///root/zsh
    gpgcheck=0

#### 内部网络yum源
如果内部网络内很多主机需要进行软件安装和升级补丁，可以在网络内搭建一台yum源服务器提供软件更新和安装。

1：将光盘内容或者自定义软件包的文件夹拷贝到ftp或者http或NFS目录即可

2：FTP 开放匿名登录，http可以通过浏览器访问看到光盘内容

3：yum源配置文件修改为

其中centos7文件夹既是存放光盘内容的地方

    baseurl=http://192.168.56.170/centos7/
pub目录下存放的既是光盘内容

    baseurl=ftp: //192.168.56.170/pub/

4：注意关闭防火墙

## 小结
以上既是yum的日常实用，一定要熟练该技能，千万别软件包都安装不上！
有时候yum会有一些小问题或者缓存出错，所以如果不行的时候，你可以试试
`yum clean all`然后在重新试试cache新的内容进来。
