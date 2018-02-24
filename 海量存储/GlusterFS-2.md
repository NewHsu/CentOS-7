# GlusterFS 技巧篇

常在河边走，哪有不湿鞋？
一旦这东西上了生产，没有一定技术底蕴和了解相关维护技巧，那么将会是四处碰壁，弄不好，数据都的毁你手里！生产无小事，操作需谨慎！

## 1. Glusterfs 副本卷更换磁盘，生产中多用副本卷。

1. 模拟故障

        临时利用sdc1模拟备用磁盘替换sdb1
        对sdc进行分区产生sdc1，进行xfs格式化
        [root@node1 glusterfs]# fdisk /dev/sdc
        [root@node1 glusterfs]# mkfs.xfs /dev/sdc1
        [root@node1 glusterfs]# mount /dev/sdc1 /glusterfs1
        查看gluster状态，模拟故障磁盘：
        [root@node1 ~]# gluster vol status
        Status of volume: Gluster-mod
        Gluster process                             TCP Port  RDMA Port  Online  Pid
        ------------------------------------------------------------------------------
        Brick node1:/glusterfs                      49153     0          Y       2233
        Brick node2:/glusterfs                      49152     0          Y       1702
        Brick node3:/glusterfs                      49152     0          Y       1699
        Self-heal Daemon on localhost               N/A       N/A        Y       2242
        Self-heal Daemon on node2                   N/A       N/A        Y       2107
        Self-heal Daemon on node3                   N/A       N/A        Y       2406

        kill掉node1上glusterfs的brick进程
        [root@node1 ~]# kill -9 2233

        再次查看：
        [root@node1 ~]# gluster vol status
        Status of volume: Gluster-mod
        Gluster process                             TCP Port  RDMA Port  Online  Pid
        ------------------------------------------------------------------------------
        Brick node1:/glusterfs                      N/A       N/A        N       N/A

2. 进行替换

        1. 挂载Gluster-mod 卷，刷新元数据，通知其他节点卷组.
        [root@client glustermnt]# mkdir test
        [root@client glustermnt]# rmdir test
        [root@client glustermnt]# setfattr -n trusted.non-existent-key -v abc /glustermnt
        [root@client glustermnt]# setfattr -x trusted.non-existent-key /glustermnt
        [root@node3 ~]# getfattr -d -m. -e hex /glusterfs
        getfattr: Removing leading '/' from absolute path names
        # file: glusterfs
        trusted.afr.Gluster-mod-client-0=0x000000000000000200000002   <----xattrs标记
        trusted.afr.dirty=0x000000000000000000000000
        trusted.gfid=0x00000000000000000000000000000001
        trusted.glusterfs.dht=0x000000010000000000000000ffffffff
        trusted.glusterfs.volume-id=0x2b6a5e51e201485aacb3ac52f3c3da05

        2. 替换磁盘（glusterfs 替换成 glusterfs1）
        [root@node1 ~]# gluster volume replace-brick Gluster-mod node1:/glusterfs node1:/glusterfs1 commit force
        volume replace-brick: success: replace-brick commit force operation successful

        3. 状态查看和确认
        [root@node1 ~]# gluster volume status
        Status of volume: Gluster-mod
        Gluster process                             TCP Port  RDMA Port  Online  Pid
        ------------------------------------------------------------------------------
        Brick node1:/glusterfs1                     49152     0          Y       3088   <----设备已经替换完成

        [root@node3 ~]# getfattr -d -m. -e hex /glusterfs
        getfattr: Removing leading '/' from absolute path names
        # file: glusterfs
        trusted.afr.Gluster-mod-client-0=0x000000000000000000000000   <---接触pending状态

        [root@node3 ~]# gluster volume heal Gluster-mod info | grep Number
        Number of entries: 276
        Number of entries: 276
        Number of entries: 276   <----数据同步完成，这里注意必须3个节点数值一样，才算同步完成。

## 2. 空间扩容

        空间扩容是生产中必备的技能，毕竟这是分布式文件系统，空间不足了，就要进行扩容。
        扩容分为2种形式，一种是磁盘扩容，一种是主机扩容。但是实际效果都是增加存储空间，操作方法也大同小异。

        1：磁盘扩容（接上例，将3台主机的sdc1扩容到GlusterFS集群中）
        有人会问，为什么是3台主机？其实道理很简单，因为我做的是3副本镜像卷，所以无论是扩磁盘增加brick还是扩主机节点，都要是3的倍数，如果你是2副本，则是2的倍数。

        [root@node1 ~]# gluster volume add-brick Gluster-mod node1:/glusterfs node2:/glusterfs1 node3:/glusterfs1 force
        volume add-brick: success

        [root@node1 ~]# gluster volume status
        Status of volume: Gluster-mod
        Gluster process                             TCP Port  RDMA Port  Online  Pid
        ------------------------------------------------------------------------------
        Brick node1:/glusterfs1                     49152     0          Y       3088
        Brick node2:/glusterfs                      49152     0          Y       1702
        Brick node3:/glusterfs                      49152     0          Y       1699
        Brick node1:/glusterfs                      49154     0          Y       3829
        Brick node2:/glusterfs1                     49153     0          Y       3485
        Brick node3:/glusterfs1                     49153     0          Y       3868

        [root@node1 ~]# gluster volume info

        Volume Name: Gluster-mod
        Type: Distributed-Replicate
        Volume ID: 2b6a5e51-e201-485a-acb3-ac52f3c3da05
        Status: Started
        Snapshot Count: 0
        Number of Bricks: 2 x 3 = 6

        新资源加入后要记得重新平衡资源，让资源均匀的分布在所有集群节点的brick上
        [root@node1 ~]# gluster volume rebalance Gluster-mod  start
        [root@node1 ~]# gluster volume rebalance Gluster-mod  status
        [root@node1 ~]# gluster vol status
        Task Status of Volume Gluster-mod
        ------------------------------------------------------------------------------
        Task                 : Rebalance
        ID                   : 5209e315-df47-4dd4-83b2-bf5232366d4e
        Status               : in progress       <----正在工作中，完成后是 Status : completed

        # gluster volume rebalance <VOLNAME> stop <----停止

        2：主机扩容
        主机扩容需要先将节点加入集群，然后按照磁盘扩容的方式完成扩容。

## 3. 挂载点网络中断

        例如前章节中，client挂载了node1:/Gluster-mod,但是如果node1，发生断网会出现什么情况呢？模拟断掉node1的public网络和private网络，然后进行数据写入。
        ## 断网后，客户端写入新数据到挂载点，发现还可以写入。
        [root@client glustermnt]# touch filetest

        到node1 上查看，发现没有数据写入。而node2 和 node3 上分别有数据写入

        到此说明node1为挂载点，但是即使他不存在了，客户端还是可以向其他GlusterFS集群写入数据的。此时恢复node1，会发现数据存在差异，这时集群会自动同步到最新状态。

        如果没有触发，可以尝试手动触发自愈

        [root@node3 ~]# gluster volume heal Gluster-mod  <----仅修复所需自愈文件
        [root@node3 ~]# gluster volume heal Gluster-mod full    <-----完全修复，出现异常状态可以尝试该命令

        也可以为该卷组开启自修复
        [root@node3 ~]# gluster volume heal Gluster-mod enable

        修复后，查看脑裂状态的文件
        [root@node3 ~]# gluster volume heal Gluster-mod info split-brain

## 4. 磁盘隐性错误

        如果你担心磁盘的隐性错误，可以开启BitRot检测
        [root@node3 ~]# gluster volume bitrot Gluster-mod  enable
        但是开启这个检测会很消耗性能，所以可以设置颗粒度，参数分别是
        # gluster volume bitrot <VOLNAME> scrub-throttle lazy   <---懒惰的
        # gluster volume bitrot <VOLNAME> scrub-throttle normal  <---常规模式
        # gluster volume bitrot <VOLNAME> scrub-throttle aggressive  <---进攻性的
        设置检测周期
        # gluster volume bitrot <VOLNAME> scrub-frequency daily   <---每天
        # gluster volume bitrot <VOLNAME> scrub-frequency weekly   <---每周
        # gluster volume bitrot <VOLNAME> scrub-frequency biweekly  <---双周
        # gluster volume bitrot <VOLNAME> scrub-frequency monthly   <---每月

        如果它降低了Glusterfs的性能，可以做临时停止和关闭
        # gluster volume bitrot Gluster-mod  scrub pause
        # gluster volume bitrot Gluster-mod  scrub resume

## 5. 保留磁盘数据，更换主机（灾难恢复）
      生产中，经常会出现主机故障，但是磁盘数据没有任何问题，这时候有2个选择，意识更换主机配件进行修复，有时候也有极端的现象，比如主机彻底无法使用，这时候需要把磁盘迁移到其他主机进行使用。处理过程如下：
        1: 安装新主机的操作系统和相关软件
        2: 恢复原来的节点名称和IP (同原机器一样)
        3: UID 查看 (新机器)
        cat /var/lib/glusterd/glusterd.info
        4: 在线的其他节上上查看原来更换主机的UID
        cat /var/lib/glusterd/peers/id
        找到原损坏主机的UID，也可以使用gluster peer status 进行查看id
        5：将ID进行复制,然后更改新主机的ID为原主机ID。
        vim /var/lib/glusterd/glusterd.info
        6：重启gluster
        7：添加节点(要恢复的机器上操作.添加存在的节点)
        gluster volume sync <nodename> all

## 6. 调优参数
      设置调优参数之前，先要终止对外提供服务，然后进行进行设置，在重新开启glusterfs。
      * 全局相关
      1. 启用修复模式
      [root@node2 ~]# gluster volume set Gluster-mod cluster.entry-self-heal on
      2. 元数据修复，用于复制卷模式的文件和目录，需要开启cluster.entry-self-heal
      [root@node2 ~]# gluster volume set Gluster-mod cluster.metadata-self-heal on
      3. 仅用于数据自我修复，仅用于复制卷的文件，需要开启cluster.entry-self-heal
      [root@node2 ~]# gluster volume set Gluster-mod cluster.data-self-heal on
      4. 开启修复
      [root@node2 ~]# gluster volume set Gluster-mod cluster.self-heal-daemon on
      5. 指定修复算法，“full”是将整个源文件复制一份；“diff”是通过算法将不一致的文件块进行复制，如果不指定则动态选择。
      [root@node2 ~]# gluster volume set Gluster-mod cluster.data-self-heal-algorithm full
      6. 磁盘最小剩余空间
      [root@node2 ~]# gluster volume set Gluster-mod cluster.min-free-disk 20%
      7. 最小空余inode
      [root@node2 ~]# gluster volume set Gluster-mod cluster.min-free-inodes 10%
      8. 条带卷的block读取和写入大小，默认128K
      [root@node2 ~]# gluster volume set Gluster-mod cluster.stripe-block-size 256KB
      9. 更改brick日志级别，默认是info，降低日志级别，有助于性能提升，不便于排错，如果非常稳定，可降低日志级别
      [root@node2 ~]# gluster volume set Gluster-mod diagnostics.brick-log-level ERROR
      10. 更改Client日志级别，所有日志可选范围是DEBUG|WARNING|ERROR|CRITICAL|NONE|TRACE|INFO
      [root@node2 ~]# gluster volume set Gluster-mod diagnostics.client-log-level ERROR
      11. 计数，统计相关操作延时，默认关闭状态，开启将消耗很大资源
      [root@node2 ~]# gluster volume set Gluster-mod diagnostics.latency-measurement on
      12. 被缓存的文件最大size，单位字节，依据内存的大小，存储文件大小而设定，建议多测试。2G
      [root@node2 ~]# gluster volume set Gluster-mod performance.cache-max-file-size 2147483648
      13. 被缓存文件最小size，字节单位，依据内存的大小，存储文件大小而定值，建议多测试而定义。2MB
      [root@node2 ~]# gluster volume set Gluster-mod performance.cache-min-file-size 2097152
      14. 设置cache大小。总缓存，一定要考虑挂载系统，太大了，无法挂载，客户端内存不足以支撑。
      [root@node2 ~]# gluster volume set Gluster-mod performance.cache-size 512MB
      15. 数据被缓存的时间，单位秒（1-60）。
      [root@node2 ~]# gluster volume set Gluster-mod performance.cache-refresh-timeout 1
      16. IO缓存转换器会定期的根据文件的修改时间来验证缓存中相应文件的一致性，默认关闭
      [root@node2 ~]# gluster volume set Gluster-mod performance.client-io-threads on

      * 控制
      1. 限制网络访问，仅允许192.168.56.网段进行访问。*可以替换为某个主机IP。
      [root@node2 ~]# gluster volume set Gluster-mod  auth.allow 192.168.56.*
      2. 拒绝哪些地址访问
      [root@node2 ~]# gluster volume  set Gluster-mod auth.reject 192.168.57.*

      * 写操作相关
      1. “后写”技术极大提升写操作的速度。是将多个小的写操作整合成为几个大的写操作，并在后台执行。
      [root@node2 ~]# gluster volume set Gluster-mod performance.write-behind on
      2. 每个文件写入缓冲区的大小，默认1MB， write-behind的buffer容量
      [root@node2 ~]# gluster volume set Gluster-mod performance.write-behind-window-size 8MB
      3. 开启异步模式，使用该选项将close()和flush()放在后台执行，返回操作成功或者失败，加速客户端请求，然后在逐步的刷新落地。
      [root@node2 ~]# gluster volume  set  Gluster-mod performance.flush-behind on

      * 读操作相关
      1. 预读，当应用程序忙于处理读入数据是，GlusterFS可以预先读取下一组所需数据，保证高效读取，此外，传输时候的较小IO读取会降低磁盘和网络压力。
      [root@node2 ~]# gluster volume set Gluster-mod performance.read-ahead on
      2. 目录预读功能
      [root@node2 ~]# gluster volume set Gluster-mod performance.readdir-ahead on
      3. 预读页数 1-16，预读取块的最大数。这个最大值仅适用于顺序读取，每个page默认是128KB，默认是2
      [root@node2 ~]# gluster volume set Gluster-mod performance.read-ahead-page-count 8
      4. IO cache，对于读大于写的操作非常有用。默认开启
      [root@node2 ~]# gluster volume set Gluster-mod performance.io-cache on
      5. 小文件加速，注意会有性能损失，多测试。
      [root@node2 ~]# gluster volume set Gluster-mod performance.quick-read on
      6. IO缓存器，默认开启，O缓存转换器读数据一次读page-size设置的大小的数据，并把读到的数据缓存起来指到cache-size设置的大小

      * 线程控制
      1. 设置 io 线程 8 ， 取值 1-64，默认为16，并不是越多越快，要衡量自身硬件的吞吐量，建议设置小于或者等于CPU数量
      [root@node2 ~]# gluster volume set Gluster-mod performance.io-thread-count 8


>以上调优参数并不是都要使用，一定要利用io zone 或者 fio 进行多测试，然后结合不同调优参数进行调节。通常如果不考虑或者能力不够的情况下，建议开启如下即可：

      1. 写模式开启“write-behind”和“flush-behind”
      2. 开启修复“cluster.self-heal-daemon”
      3. 保护磁盘和inode不被用尽“cluster.min-free-disk”和“cluster.min-free-inodes”
      4. 加大缓存到合适的值“performance.cache-size”
      5. 进阶一点可以分析存储文件构成，设置 max和min的缓存文件大小
      6. 在进阶一点可以设置“performance.write-behind-window-size”，数值太大写的慢，数值太小写的太频繁，依据队列长度和请求频率找到合适值。
      7. 分析访问频率和量，调节io线程“performance.io-thread-count”
      8. 小文件太多，可以开启小文件模式“performance.quick-read”
      9. 顺序文件较多，命中率较高的情况下，或者是大文件较多可以开启预读并设置合适的count“performance.read-ahead”、”performance.readdir-ahead“、”performance.read-ahead-page-count“
>如何需要颗粒度更细的调优，可以直接调节配置文件，这里有更多的隐藏参数，但是风险也很高，如果不熟悉源码，无法定位哪些选项有哪些值，建议还是以上调优参数配置即可，文件位于“/var/lib/glusterd/vols/Gluster-mod/”


## 脑裂
* 简单来说就是两个节点之间的心跳断了，每个主机都各写各的，都认为自己是对的，对方是错的。这种情况下只能手动判断和恢复了，但是对于智能的分布式系统来说，这不科学！gluster采用了quorum机制尽可能的预防脑裂。
quorum机制运行在glusterd上，它是服务器端的一个守护进程。quorum的值是可以设置的，如果这个数没有达到，brick就被Kill掉了，任何命令都不能运行：

    [root@node2 ~]# gluster volume set Gluster-mod cluster.server-quorum-type server    <----默认是none

    [root@node2 ~]# gluster volume set all cluster.server-quorum-ratio 70%   <----百分比数值

>这个设置涉及到集群是否工作，如上例的70%，如果活跃度低于70%，则整个集群会停止对外工作。

    1. 在线服务器的比率，有节点离线或者网络分裂时，系统进行投票
    2. 投票的结果依据设定值而判断，集群内能够通信的节点间进行相互投票，如果票数操作设定值，则继续工作，如果不满足设定值，则不再接受数据写入。
    3. 如果总共只有两个节点，则不要对此选项设置。


## 总结
本章节主要讲解一些较为常见的分布式存储维护方法和问题处理，实际生产中的问题可能要比这个复杂太多，一定要注意保障数据安全。
调优部分还请依据实际的情况进行调节。切记，多测试，多调节，得到最优的值，每次只改动一个参数或者一组相关参数，进行测试，然后调回。避免过多更改，而后自己都不记得该如何下手了。
