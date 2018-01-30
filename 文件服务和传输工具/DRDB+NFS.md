# PCS  HA（NFS+DRBD）
## 介绍
生产中有些时候前端一旦做了负载均衡的web或者有一些关联的批量任务，那么就会涉及到多台主机需要能够读取到同一个文件夹下的某些文件，其实这个问题可以使用集中的NAS存储来解决，但是集中的NAS存储挂载了太多的系统，往往会出现读写瓶颈，也可以使用外联的共享存储配合NFS来做一个共享，类似于前例数据的共享存储，挂载到NFS下，可以任意切换，保证不间断服务，但是共享存储的成本太高。其实还有另外的手段可以利用，比如下例用的DRBD来做本地的磁盘同步，取代昂贵的共享存储，

NFS高可用生成业务需求

    在企业实际生产应用场景中，NFS网络文件存储系统是中小型企业最常用的存储架构解决方案之一。该架构方案部署简单，维护方便，并且只需要通过配置Inotify（rsync+inotify）简单而高效的数据同步方式就可以实现对NFS存储系统的数据进行异机主从同步已经实现数据读写分离（类似Mysql的从同步方式），且多个从NFS存储系统还可以通过LVS或者HAPROXY等代理实现业务负载均衡，即分担大并发读数据的压力，同时又排除了从NFS存储的单点问题。

    在高可用的存储系统架构中，虽然从NFS存储系统是多个，但是主的NFS存储系统仅一个，也就是说主的NFS存储系统一旦宕机，所有的写业务都会终止，而从NFS存储系统宕机1个就没什么大影响，那么如何解决这个主NFS存储系统单点的问题呢，其实，可以做好业务的服务监控，然后，当主NFS存储系统宕机后，报警管理员来人为手工根据同步的日志记录选择最快的从NFS存储系统改为主，然后让其他从NFS存储系统和新主NFS存储同步，这个方案简单可行，但是需要人工处理。

    这里我们可以采用NFS+DRBD+Heartbeat高可以服务解决方案，这个解决方案可以有效解决主NFS存储系统单点的问题，当主NFS存储宕机后，可以实现把主NFS存储系统从一个主节点切换到另外一个备节点，而新的主NFS存储系统还会自动和所有其他的从NFS存储系统进行同步，且新主NFS存储系统的数据和宕机瞬间的主NFS存储系统几乎完全一致，这个切换过程完全是自动进行的，从而实现了NFS存储系统的热备方案
>以上部分待精简和修改

## 生产常用架构图
<center>
    <img src="./images/cluster 7/NFS.jpg">
</center>


## DRDB介绍
<center>
    <img src="./images/cluster 7/DRDB.png">
</center>

* 一张图说尽DRBD的工作模式，简单的理解其实就是数据通过DRBR软件通过网络传输在另外一侧的机器也复写了一份，所以2侧的数据是一样的。我们即可使用这个功效在俩侧数据保持一样的情况下来替代共享存储，但是他的致命弱点就是网络中断和网络延迟，如果延迟太高，而写入数据又非常频繁和大量，那么真不建议使用这个技术。
* 文件写入磁盘的步骤是: 写操作 --> 文件系统 --> 内存缓存中 --> 磁盘调度器 --> 磁盘驱动器 --> 写入磁盘。而DRBD的工作机制如上图所示，数据经过buffer cache后有内核中的DRBD模块通过tcp/ip协议栈经过网卡和对方建立数据同步。
>通常做法都是将这种DRDB的网络规划到独立的交换机走内部私有网络来进行通信。

### DRBD基础功能
* DRBD 技术是一种基于软件的，无共享存储的，复制的存储解决方案，在服务器之间的对块设备（硬盘，分区，逻辑卷等）进行镜像。
* 同步镜像和异步镜像：

        同步镜像，当本地发申请进行写操作进行时，同步写到两台服务器上
        异步镜像，当本地写申请已经完成对本地的写操作时，开始对其余服务器进行写操作
### DRBD模式
1.	单主模式

        1. 集群中只存在一个主节点。 正是因为这样在集群中只能有一个节点可以随时操作数据，对应的文件系统（EXT3、EXT4、XFS等等）。
        2. 集群当前操作数据的几点会被设置为”主动”，而另一侧则是”被动”，当主动出现问题，则会迁移到被动节点，并将”被动”设置为”主动”
        3. DRBD 单主节点模式可保证集群的高可用性（fail-over 遇故障转移的能力）
2.	双主模式

        1. DRBD 8.0 版本以后才支持双主模式
        2. 集群中资源存在两个主节点
        3. 考虑到双方数据存在同时操作的可能性，需要一个共享的集群文件系统，利用分布式的锁机制进行管理，如 Redhat 的GFS2 和Oracle的OCFS2。
### DRBD传输模式
* drbd有三种数据同步模式:同步，异步，半同步

        A：异步复制。本地磁盘写成功后立即返回，数据放在发送buffer中，可能丢失
        B：内存同步（半同步）复制。本地写成功并将数据发送到对方后立即返回，如果双机掉电，数据可能丢失
        C：同步复制。本地和对方写成功确认后返回。如果双机掉电或磁盘同时损坏，则数据可能丢失
>通常选用3模式，但是选用3模式又非常依赖网络，所以将网络单独规划出来并做冗余网络来支撑

### DRBD脑裂
* 既然是集群系统，有主备之分，那么难免的就会出现脑裂，无法感知对方，同时又将自己提升为”主动”模式，一旦恢复，那么后果不堪设想，到底以谁为主？谁的数据是准确的？通常我们都会配置邮件通知去人为干预，但是你也可以做如下设置：

        1. 丢弃比较新的主节点的所做的修改
        2. 丢弃老的主节点所做的修改
        3. 丢弃修改比较少的主节点的修改
        4. 一个节点数据没有发生变化的完美的修复裂脑

## DRBD安装和配置

    # rpm --import http://elrepo.org/RPM-GPG-KEY-elrepo.org
    # rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
    # yum -y install drbd84-utils kmod-drbd84
### DRBD配置
1.	双侧主机编写DRBD配置

        [root@node1 drbd.d] vi /etc/drbd.d/nfsdata.res
        resource data { 
        on ywdb1{ 
            device    /dev/drbd1;      //drbd设备名称
            disk      /dev/sdb1;      //对应物理磁盘，sdb1不需要格式化
            address    192.168.1.110:7789;    //通讯的地址和端口
            meta-disk internal; 
        } 
        on ywdb2{ 
            device    /dev/drbd1; 
            disk      /dev/sdb1; 
            address   192.168.1.112:7789; 
            meta-disk internal; 
        } 
        }
2.	初始化设备，双侧主机执行

        drbdadm create-md  data -c /etc/drbd.conf #中途提示输入”yes”
3.	启动DRBD

        [root@ywdb1 ~]# /etc/init.d/drbd restart
        Stopping all DRBD resources: Resource unknown
        .
        Starting DRBD resources: [
            create res: data
        prepare disk: data
            adjust disk: data
            adjust net: data
4.	查看启动后状态，双侧状态都为secondary，因为没有设置主设备，所以这个状态还不能使用

        [root@ywdb1 ~]# cat /proc/drbd 
        version: 8.4.6 (api:1/proto:86-101)
        GIT-hash: 833d830e0152d1e457fa7856e71e11248ccf3f70 build by phil@Build64R7, 2015-04-10 05:13:52
        1: cs:Connected ro:Secondary/Secondary ds:Inconsistent/Inconsistent C r-----
            ns:0 nr:0 dw:0 dr:0 al:0 bm:0 lo:0 pe:0 ua:0 ap:0 ep:1 wo:f oos:8387292
5.	设置主设备

        [root@ywdb1 ~]#  drbdadm primary --force  data -c /etc/drbd.conf
6.	查看DRBD同步

        [root@ywdb1 ~]# cat /proc/drbd 
        version: 8.4.6 (api:1/proto:86-101)
        GIT-hash: 833d830e0152d1e457fa7856e71e11248ccf3f70 build by phil@Build64R7, 2015-04-10 05:13:52
        1: cs:SyncSource ro:Primary/Secondary ds:UpToDate/Inconsistent C r-----
            ns:4792 nr:0 dw:0 dr:5520 al:0 bm:0 lo:0 pe:0 ua:0 ap:0 ep:1 wo:f oos:8382500
            [>....................] sync'ed:  0.1% (8184/8188)M
            finish: 1:27:19 speed: 1,596 (1,596) K/sec
7.	同步完成

        [root@ywdb1 ~]# cat /proc/drbd 
        version: 8.4.6 (api:1/proto:86-101)
        GIT-hash: 833d830e0152d1e457fa7856e71e11248ccf3f70 build by phil@Build64R7, 2015-04-10 05:13:52
        1: cs:Connected ro:Primary/Secondary ds:UpToDate/UpToDate C r-----
            ns:8387292 nr:0 dw:0 dr:8388020 al:0 bm:0 lo:0 pe:0 ua:0 ap:0 ep:1 wo:f oos:0

### PCS中配置DRBD资源
CentOS中的PCS不在支持DRBD模式，但是PCS是支持DRBD资源的，所以不必刻意遵循CentOS标准，可以使用PCS标准，一样，一样的。

    [root@ywdb2 ~]# pcs cluster cib drbd_cfg  
    [root@ywdb2 ~]# pcs -f drbd_cfg resource create Data ocf:linbit:drbd   drbd_resource=data op monitor interval=60s 
    [root@ywdb2 ~]# pcs -f drbd_cfg resource master DataClone Data  master-max=1 master-node-max=1 clone-max=2 clone-node-max=1  notify=true

    [root@ywdb2 ~]# pcs cluster cib-push drbd_cfg
    CIB updated
    [root@ywdb2 ~]# pcs status
    ……
    Master/Slave Set: DataClone [Data]
        Masters: [ ywdb2 ]
        Slaves: [ ywdb1 ]
    ……

### 配置DRBD文件系统

    [root@ywdb2 ~]# pcs cluster cib fs_cfg    
    [root@ywdb2 ~]#  pcs -f fs_cfg resource create NFS Filesystem device="/dev/drbd1" directory="/nfsdata"  fstype="xfs" 
    [root@ywdb2 ~]#  pcs -f fs_cfg constraint colocation add NFS DataClone INFINITY with-rsc-role=Master
    [root@ywdb2 ~]# pcs -f fs_cfg constraint order promote DataClone then start NFS
    Adding DataClone NFS (kind: Mandatory) (Options: first-action=promote then-action=start)
    [root@ywdb2 ~]# pcs -f fs_cfg constraint  
    Location Constraints:
    Ordering Constraints:
    promote DataClone then start NFS (kind:Mandatory)
    Colocation Constraints:
    NFS with DataClone (score:INFINITY) (with-rsc-role:Master)
    [root@ywdb2 ~]# pcs status
    …….
    Master/Slave Set: DataClone [Data]
        Masters: [ ywdb2 ]
        Slaves: [ ywdb1 ]
    NFS	(ocf::heartbeat:Filesystem):	Started ywdb2

### DRBD验证
将当前正在运行的ywdb2置为standby模式，进行查看切换到ywdb1为正常

    [root@ywdb2 ~]# pcs cluster standby  ywdb2
    [root@ywdb2 ~]# pcs status
    ……
    Master/Slave Set: DataClone [Data]
        Masters: [ ywdb1 ]
        Stopped: [ ywdb2 ]
    NFS	(ocf::heartbeat:Filesystem):	Started ywdb1 
    ……
>别忘记将主机在unstandby回来
    
    Pcs cluster unstandby ywdb2

### DRBD脑裂问题 (待补全)

## DRBD小结
这里只是说了DRBD是用磁盘镜像技术构建NFS集群，替代共享存储，实际DRBD的应用还有很多，也有更多的配置在本章尾部会简单罗列。


## PCS NFS配置	
继续使用前面的Cluster环境、
1.	创建NFS服务所需要的VIP

        root@ywdb1 /]#pcs resource create nfs_ip IPaddr2 ip=192.168.56.199 cidr_netmask=24
2.	将VIP 和 DRBD 的MASTER 捆绑运行，必须这么做，要不然各自跑在不同机器上就会有问题，你晓得的，文件系统无法挂起，IP无法工作在正确的机器上。

        [root@ywdb1 /]# pcs constraint colocation add nfs_ip DataClone INFINITY with-rsc-role=Master
3.	将文件系统和VIP添加到同一个group中，在同一主机运行

        [root@ywdb1 /]# pcs resource group add nfsshare nfs_ip NFS
        这样的做法很简单，VIP 和 NFS 在同一组，即可工作在同一主机，而DRBD的MASTER不能加入group中，所以我们要捆绑他和VIP在一个主机工作，也就是VIP 和NFS 文件系统在一起工作，而VIP又和DRBD在一起工作，这样即可完美解决DRBD不协调导致NFS文件系统无法挂起问题。
4.	创建NFS daemon 资源共享NFS文件夹，并添加到NFS 其他资源所在的group

        [root@ywdb1 nfsdata]# pcs resource create nfs-daemon nfsserver nfs_shared_infodir=/nfsdata nfs_no_notify=true  --group nfsshare
        [root@ywdb1 /]# pcs status
        …….
        Master/Slave Set: DataClone [Data]
            Masters: [ ywdb1 ]
            Slaves: [ ywdb2 ]
        Resource Group: nfsshare
            nfs_ip	(ocf::heartbeat:IPaddr2):	Started ywdb1 
            NFS	(ocf::heartbeat:Filesystem):	Started ywdb1 
            nfs-daemon	(ocf::heartbeat:nfsserver):	Started ywdb1 
        …….
5.	将共享的目录输出访问，并定义哪些地址可以访问，以及设置相关权限

        [root@ywdb1/]#pcs resource create nfs-root exportfs clientspec=* options=rw,sync,no_root_squash directory=/nfsdata fsid=0  --group nfsshare
        [root@ywdb1 /]# pcs status
        …….
        Master/Slave Set: DataClone [Data]
            Masters: [ ywdb1 ]
            Slaves: [ ywdb2 ]
        Resource Group: nfsshare
            nfs_ip	(ocf::heartbeat:IPaddr2):	Started ywdb1 
            NFS	(ocf::heartbeat:Filesystem):	Started ywdb1 
            nfs-daemon	(ocf::heartbeat:nfsserver):	Started ywdb1 
            nfs-root	(ocf::heartbeat:exportfs):	Started ywdb1 
        ……
6.	添加NFS集群消息通知资源，有了它才能正常工作，source地址写VIP即可

        [root@ywdb1 /]# pcs resource create nfs-notify nfsnotify source_host=192.168.56.199 --group nfsshare
        [root@ywdb1 /]# pcs status
        …….
        Master/Slave Set: DataClone [Data]
            Masters: [ ywdb1 ]
            Slaves: [ ywdb2 ]
        Resource Group: nfsshare
            nfs_ip	(ocf::heartbeat:IPaddr2):	Started ywdb1 
            NFS	(ocf::heartbeat:Filesystem):	Started ywdb1 
            nfs-daemon	(ocf::heartbeat:nfsserver):	Started ywdb1 
            nfs-root	(ocf::heartbeat:exportfs):	Started ywdb1 
            nfs-notify	(ocf::heartbeat:nfsnotify):	Started ywdb1 
        ……
## 客户端挂载测试
1.	创建目录并挂载，查看文件夹内容

        [root@localhost /]#mkdir /nfstest
        [root@localhost /]# mount -t nfs  192.168.56.199:/nfsdata /nfstest
        [root@localhost /]# showmount -e 192.168.56.199
        Export list for 192.168.56.199:
        /nfsdata *
        [root@localhost nfstest]# pwd
        /nfstest
        [root@localhost nfstest]# ls
        etab  export-lock  nfsdcltrack  rmtab  rpc_pipefs  statd  v4recovery  xtab
        [root@localhost nfstest]# mount
        ……
        192.168.56.199:/nfsdata on /nfstest type nfs (rw,relatime,vers=3,rsize=131072,wsize=131072,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,mountaddr=192.168.56.199,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=192.168.56.199)
## NFS切换测试
1. 将正在运行的ywdb1置于standby状态
    
        [root@ywdb1 /]# pcs cluster standby ywdb1
2. 查看停止过程

        [root@ywdb1 /]# pcs status
        ……
        Master/Slave Set: DataClone [Data]
            Slaves: [ ywdb1 ywdb2 ]
        Resource Group: nfsshare
            nfs_ip	(ocf::heartbeat:IPaddr2):	Stopped 
            NFS	(ocf::heartbeat:Filesystem):	Stopped 
            nfs-daemon	(ocf::heartbeat:nfsserver):	Stopped 
            nfs-root	(ocf::heartbeat:exportfs):	Stopped 
            nfs-notify	(ocf::heartbeat:nfsnotify):	Stopped 
        ……
3. 再次查看是否在ywdb2上启动成功

        [root@ywdb1 /]# pcs status
        ……
        Master/Slave Set: DataClone [Data]
            Masters: [ ywdb2 ]
            Stopped: [ ywdb1 ]
        Resource Group: nfsshare
            nfs_ip	(ocf::heartbeat:IPaddr2):	Started ywdb2 
            NFS	(ocf::heartbeat:Filesystem):	Started ywdb2 
            nfs-daemon	(ocf::heartbeat:nfsserver):	Started ywdb2 
            nfs-root	(ocf::heartbeat:exportfs):	Started ywdb2 
            nfs-notify	(ocf::heartbeat:nfsnotify):	Started ywdb2 
        ……
>别忘记将主机unstandby回来
>同时切换以后，可以在客户端进行测试，浏览NFS所挂载的文件

## 总结
到此为止集群部分都写完了，无论是复杂的NFS，没有共享存储的DRBD，自定义脚本的DB2，调用PCS提供的APACHE，都是比较经典的集群实例，可以为各位读者提供参考，文中很多地方我没有使用较为复杂的构建方式就是为了方便大家快速建立集群，而是刻意的规避了复杂的做法，比如，我们不按照资源顺序添加资源到group，将会导致资源在切换的时候出现问题，其实可以使用规则来限制，先启动那个资源，在启动那个资源，卸载的时候一样可以规定先卸载的资源和后卸载的资源，来进行，但是这样做可能会增加读者的学习难度，另外PCS还有很多规则可以限制，可以参考我集群第一章的指令实例部分来做。
备注：DRBD详细配置可以在附录1中找到

克隆某个资源，以便其在多个节点中处于活跃状态。例如：可以使用克隆的资源配置一个 IP 资源的多个实例，以便在整个集群中分布，保持节点平衡。可以克隆提供资源代理支持的任意资源。一个克隆包括一个资源或一个资源组。






