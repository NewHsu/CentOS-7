## rsync传输工具
## rsync介绍
rsync（remote synchronize）是一个远程数据同步工具，可通过LAN/WAN快速同步多台主机间的文件。Rsync使用所谓的“Rsync算法”来使本地和远程两个主机之间的文件达到同步，这个算法只传送两个文件的不同部分，而不是每次都整份传送，因此速度相当快。

rsync本来是用于替代rcp的一个工具，目前由rsync.samba.org维护，所以rsync.conf文件的格式类似于samba的主配置文件。Rsync可以通过rsh或ssh使用，也能以daemon模式去运行，在以daemon方式运行时Rsync server会打开一个873端口，等待客户端去连接。

连接时，Rsync server会检查口令是否相符，若通过口令查核，则可以开始进行文件传输。
第一次连通完成时，会把整份文件传输一次，以后则就只需进行增量备份。

rsync支持大多数的类Unix系统，无论是Linux、Solaris还是BSD上都经过了良好的测试。此外，它在windows平台下也有相应的版本，如cwRsync和Sync2NAS等工具。

><center>**以上介绍来自网络**</center >
#### rsync特点
1. 可以镜像保存整个目录树和文件系统；
2. 可以很容易做到保持原来文件的权限、时间、软硬链接等；
3. 无须特殊权限即可安装；
4. 优化的流程，文件传输效率高；
5. 可以使用rsh、ssh等方式来传输文件，当然也可以通过直接的socket连接；
6. 支持匿名传输

![png](./images/rsync/rsync1.png)
#### Rsync算法介绍
rsync是unix/linux下同步文件的一个高效软件，同步更新两处计算机的文件与目录，主要是利用查找文件中的不同块以减少数据传输。rsync利用由澳洲电脑程式师Andrew Tridgell发明的算法。

在讲算法之前，我们有必要先了解一下rsync要解决的问题：
1. A主机和B主机想要进行文件不同部分的同步，那么就要进行比对，但是2台主机之间文件要如何比对呢？。
2. 如果软件的设计比对方案是传输一方文件到另一方进行比对，那么这与我们只想传输不同部的初衷相背。
3. 有没有一种算法可以让俩边的文件之传输一些特殊的内容就比对比出俩边文件有什么不同？于是出现了rsync的算法。
#### Rsync算法概况
假设我们要将A文件同步到B文件
1.	会把B文件平均切分成若干个小块，比如每块512个字节（最后一块会小于这个数），然后对每块计算两个checksum

		a) 一个是 rolling checksum，是弱checksum，32位的checksum，其使用的是Mark Adler发明的adler-32算法
		b) 另一个是强checksum，128位的，现在用md5 hash算法
		c) 为什么要2此checksum？因为弱的adler32算法碰撞概率太高了，强的checksum算法在早先的机器上计算太慢，所以先用弱计算，再用强计算。
2.	同步目标端会把B文件的一个checksum列表传给A主机，列表里包括了三个主要内容，rolling checksum(32bits)，md5 checksume(128bits)，文件块编号。
3.	A机器收到了这个列表后，会对A文件做同样的checksum，然后和B的checksum表做对比，这样就很容易知道哪些文件块改变了
#### Rsync算法步骤
1.	取A文件的第一个文件块（假设的是512个长度），也就是从A文件的第1个字节到第512个字节，做rolling checksum并存入hash表中查。
2.	和B文件传过来的rolling checksum作比较，如果找到相同的，则发现在B文件中有潜在相同的文件块，接着比较 md5的checksum，因为rolling checksume太弱了，可能发生碰撞。所以还要算md5的128bits的checksum。如果rolling checksum和md5 checksum都相同，这说明在B文件中有相同的块，记录下B的相同文件编号。
3.	如果A文件的rolling checksum 没有在hash table中找到，那就不用算md5 checksum了。表示这一块中有不同的信息。总之，只要rolling checksum 或 md5 checksum 其中有一个在B文件的checksum hash表中找不到匹配项，那么就会触发算法对A文件的rolling动作。算法会住后step 1个字节，取A文件中字节2-513的文件块要做checksum，go to (1) – ，这就是rolling checksum了吧。
4.	这样，我们就可以找出A文件相邻两次匹配中的那些文本字符，这些就是我们要往同步目标端传的文件内容了。
### Rsync配置
#### Rsync安装
	Linux系统已经默安装好了，无需额外安装，如果是AIX系统需要自安装rsync软件包。
#### 匿名传输配置（范例）
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
**rsync客户端参数解释** 
|参数|解释|
|--|:--|
|c|   |
|r|  |
|p|  |
|o|  |
|g|  |
|P|  |
|--delete|  |
|z|  |
|v|  |

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
```
配置rsync密码（在上边的配置文件中已经写好路径） rsync.pas（名字随便写，只要和上边配置文件里的一致即可），格式(一行一个用户). 
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

### 总结
* 我一般使用rsync在我生产的主机间去同步或者传输数据，至于认证和不认证要看特殊的需求，但是必须限制主机传输。
* 有人问我要怎么调用rsync？是不是每次都要使用shell去调用，你可以写道程序中调用，也可以使用crontab调用，很多方式，只要你想使用它传文件或者做同步。
* 并不是说FTP就不用了，我在备份传输的时候还是会使用ftp的，例如生产的数据库备份，每天都会传输到固定的主机，这里我使用的是FTP。
* 将传输分为2种：
	1. 生产主机间数据同步和文件传输（rsync）
	2. 数据备份上传下载 （FTP）
