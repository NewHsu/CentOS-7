## rsync传输工具
## rsync介绍
* rsync（remote synchronize）是一个远程数据同步工具，可通过LAN/WAN快速同步多台主机间的文件。rsync使用所谓的“rsync算法”来使本地和远程两个主机之间的文件达到同步，这个算法只传送两个文件的不同部分，而不是每次都整份传送（有点断点续传的意思），因此速度相当快。

### rsync特点
1. 可以镜像保存整个目录树和文件系统；
2. 可以很容易做到保持原来文件的权限、时间、软硬链接等；
3. 无须特殊权限即可安装；
4. 优化的流程，文件传输效率高；
5. 可以使用rsh、ssh等方式来传输文件，当然也可以通过直接的socket连接；
6. 支持匿名传输

![png](../images/rsync/rsync1.png)

### Rsync算法介绍
* rsync是unix/linux下同步文件的一个高效软件，同步更新两处计算机的文件与目录，主要是利用查找文件中的不同块以减少数据传输。
* rsync利用由澳洲电脑程式师Andrew Tridgell发明的算法。
* 深入了解之前，先了解一下rsync要解决的问题：

    1. 2个主机之间的数据同步，如何做数据对比？
    2. 如果2个主机之间互传数据，又相互覆盖，要如何处理？
    3. 能不能根据一些特殊的内容信息完成文件对比？
### Rsync算法概述（A->B传输文件）
1.	首先会把B文件平均切分成若干个小块，比如每块512个字节，然后对每块计算两个checksum
2.	同步目标端会把文件的一个checksum列表传给A主机，列表包含的主要内容有：rolling checksum(32bits)，md5 checksume(128bits)，文件块编号。
3.	A主机收到了这个列表后，会对A文件做同样的checksum，然后和B的checksum表做对比，这样就很容易知道哪些文件块改变了

### 经典使用场景
1.	在本地两个目录间进行数据同步
2.	本地与远程主机间完成数据同步
3.	使用ssh通道进行数据同步
4.	Update 更新
5.	删除不存在于源目录的目的地文件
6.	在同步时不在目的地创建新文件
7.	显示执行进度
8.	查看source 和 destination 间的区别
9.	按指定模式进行同步
10.	限制传输文件的大小
11.	全拷贝

## Rsync配置
### Rsync安装
	Linux系统已经默安装好了，无需额外安装，如果是AIX系统需要自安装rsync软件包。
### 匿名传输配置（范例）
```
#vim /etc/rsyncd.conf  (范例文本)
uid = nobody     //运行rsync的用户
gid = nobody     //运行rsync的组
use chroot = yes   //用户禁锢目录
max connections = 4    //最大链接数
pid file = /var/run/rsyncd.pid   
exclude = lost+found/    //排除文件夹内的目录
transfer logging = yes    //传输记录
timeout = 900          //传输超时
ignore nonreadable = yes    
log file=/var/log/rsyncd.log //日志位置
dont compress   = *.gz *.tgz *.zip *.z *.Z *.rpm *.deb *.bz2  //传输不压缩的文件

[ftp]     //这里是认证的模块名，在client端需要指定
path = /home/ftp       //需要做镜像的目录,不可缺少！
comment = ftp export area    //这个模块的注释信息
ignore errors              //可以忽略一些无关的IO错误
read only = yes           // 只读，read only=no 可写             
#hosts allow = 192.168.1.1,10.10.10.10      //允许主机
#hosts deny = 0.0.0.0/0                  //禁止主机
```

**启动rsync server**
```
#rsync --daemon /etc/rsyncd.conf
```
**启动后确认启动成功，rsync端口TCP 873(可更改)**
```
[root@localhost ftp]# netstat -an | grep 873
tcp        0      0 0.0.0.0:873             0.0.0.0:*               LISTEN     
tcp6       0      0 :::873                  :::*                    LISTEN
```
**测试传输数据**
```
[root@localhost log]# rsync -crpogP ./*.log 192.168.255.128::ftp/
sending incremental file list
Xorg.0.log
       40282 100%    7.17MB/s    0:00:00 (xfer#1, to-check=3/4)
boot.log
       10646 100%   10.15MB/s    0:00:00 (xfer#2, to-check=2/4)
pm-powersave.log
           0 100%    0.00kB/s    0:00:00 (xfer#3, to-check=1/4)
yum.log
           0 100%    0.00kB/s    0:00:00 (xfer#4, to-check=0/4)

sent 51253 bytes  received 84 bytes  4889.24 bytes/sec
total size is 50928  speedup is 0.99
```

**认证传输配置**
```
#vim /etc/rsyncd.conf  (范例文本)
uid = nobody     //运行rsync的用户
gid = nobody     //运行rsync的组
use chroot = yes   //用户禁锢目录
max connections = 4    //最大链接数
pid file = /var/run/rsyncd.pid   
exclude = lost+found/    //排除文件夹内的目录
transfer logging = yes    //传输记录
timeout = 900          //传输超时
ignore nonreadable = yes    
log file=/var/log/rsyncd.log //日志位置
dont compress   = *.gz *.tgz *.zip *.z *.Z *.rpm *.deb *.bz2  //传输不压缩的文件

[ftp]     //这里是认证的模块名，在client端需要指定
path = /home/ftp       //需要做镜像的目录,不可缺少！
comment = ftp export area    //这个模块的注释信息
ignore errors                                   //可以忽略一些无关的IO错误
read only = yes                              // 只读，read only=no 可写       
auth users = xcl        //认证的用户名，此用户与系统无关
secrets file = /etc/rsync.pas           //密码和用户名对比表，密码文件自己生成
#hosts allow = 192.168.1.1,10.10.10.10      //允许主机
#hosts deny = 0.0.0.0/0                  //禁止主机
```

**制作密码文件**
* 配置rsync密码（在上边的配置文件中已经写好路径） rsync.pas（名字随便写，只要和上边配置文件里的一致即可），格式(一行一个用户). 
```
服务器端密码问价格式为：xcl:password  （账户：密码）
客户端密码文件格式为： password （只写密码即可）
密码文件权限为600， chmod 600 /etc/rsync.pas
```

**测试传输数据**
```
[root@localhost var]# rsync -crpogP ./log/messages  xcl@192.168.255.128::ftp  --password-file=/etc/rsync.pas
sending incremental file list
messages
      377625 100%   14.30MB/s    0:00:00 (xfer#1, to-check=0/1)

sent 377757 bytes  received 27 bytes  32850.78 bytes/sec
total size is 377625  speedup is 1.00
``` 

***查看传输日志***
如果上面定义了log的位置，可以到log中查看详细的rsync的传输记录。



### 总结
* 生产系统主机间数据同步或者传输数据，至于认证和不认证要看特殊的需求，但是必须限制可以链接传输的主机。
* 怎么调用rsync？是不是每次都要使用shell命令去调用？你可以写道程序中调用，也可以使用crontab调用，很多方式。
* FTP被淘汰了？并不是说FTP淘汰了，而是生产环境中处于安全考虑以及监管的一些要求，会将FTP替换成rsync，毕竟FTP漏洞太多，而且还是账户和密码明传输。
* 什么时候用？任何时候！只要你想！

## 常用rsync客户端参数解释
|参数|解释|
|:--|:--|
|-v|--verbose 详细模式输出。
|-q|--quiet 精简输出模式。
|-c|--checksum 打开校验开关，强制对文件传输进行校验。
|-a|--archive 归档模式，表示以递归方式传输文件，并保持所有文件属性，等于-rlptgoD。
|-r|--recursive 对子目录以递归模式处理。
|-R|--relative 使用相对路径信息。
|-b|--backup 创建备份，也就是对于目的已经存在有同样的文件名时，将老的文件重新命名为~filename。可以使用--suffix选项来指定不同的备份文件前缀。
|--backup-dir| 将备份文件(如~filename)存放在在目录下。
|-suffix=SUFFIX| 定义备份文件前缀。
|-u|--update 仅仅进行更新，也就是跳过所有已经存在于DST，并且文件时间晚于要备份的文件，不覆盖更新的文件。
|-l|--links 保留软链结。
|-L|--copy-links 想对待常规文件一样处理软链结。
|--copy-unsafe-links| 仅仅拷贝指向SRC路径目录树以外的链结。
|--safe-links| 忽略指向SRC路径目录树以外的链结。
|-H|--hard-links 保留硬链结。
|-p|--perms 保持文件权限。
|-o|--owner 保持文件属主信息。
|-g|--group 保持文件属组信息。
|-D|--devices 保持设备文件信息。
|-t|--times 保持文件时间信息。
|-S|--sparse 对稀疏文件进行特殊处理以节省DST的空间。
|-n|--dry-run现实哪些文件将被传输。
|-w|--whole-file 拷贝文件，不进行增量检测。
|-x|--one-file-system 不要跨越文件系统边界。
|-B|--block-size=SIZE 检验算法使用的块尺寸，默认是700字节。
|-e|--rsh=command 指定使用rsh、ssh方式进行数据同步。
|--rsync-path=PATH| 指定远程服务器上的rsync命令所在路径信息。
|-C|--cvs-exclude 使用和CVS一样的方法自动忽略文件，用来排除那些不希望传输的文件。
|--existing| 仅仅更新那些已经存在于DST的文件，而不备份那些新创建的文件。
|--delete| 删除那些DST中SRC没有的文件。
|--delete-excluded| 同样删除接收端那些被该选项指定排除的文件。
|--delete-after| 传输结束以后再删除。
|--ignore-errors| 及时出现IO错误也进行删除。
|--max-delete=NUM| 最多删除NUM个文件。
|--partial| 保留那些因故没有完全传输的文件，以是加快随后的再次传输。
|--force| 强制删除目录，即使不为空。
|--numeric-ids| 不将数字的用户和组id匹配为用户名和组名。
|--timeout=time| ip超时时间，单位为秒。
|-I|--ignore-times 不跳过那些有同样的时间和长度的文件。
|--size-only| 当决定是否要备份文件时，仅仅察看文件大小而不考虑文件时间。
|--modify-window=NUM| 决定文件是否时间相同时使用的时间戳窗口，默认为0。
|-T| --temp-dir=DIR 在DIR中创建临时文件。
|--compare-dest=DIR |同样比较DIR中的文件来决定是否需要备份。
|-P| 等同于 --partial。
|--progress| 显示备份过程。
|-z|--compress 对备份的文件在传输时进行压缩处理。
|--exclude=PATTERN|指定排除不需要传输的文件模式。
|--include=PATTERN |指定不排除而需要传输的文件模式。
|--exclude-from=FILE |排除FILE中指定模式的文件。
|--include-from=FILE |不排除FILE指定模式匹配的文件。
|--version |打印版本信息。
|--address |绑定到特定的地址。
|--config=FILE |指定其他的配置文件，不使用默认的rsyncd.conf文件。
|--port=PORT| 指定其他的rsync服务端口。
|--blocking-io |对远程shell使用阻塞IO。
|--stats |给出某些文件的传输状态。
|--progress| 在传输时现实传输过程。
|--log-format=formAT |指定日志文件格式。
|--password-file=FILE |从FILE中得到密码。
|--bwlimit=KBPS| 限制I/O带宽，KBytes per second。
|-h|--help 显示帮助信息。