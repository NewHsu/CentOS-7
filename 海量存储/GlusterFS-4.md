### 3.7 GlusterFS常用指令
1. 基础指令
|进程|描述|
|:---|:---|
|卷信息| #gluster volume info  和  # gluster volume status
|启动/停止卷|# gluster volume start/stop VOLNAME
|删除卷|# gluster volume delete VOLNAME
|添加Brick|# gluster volume add-brick VOLNAME NEW-BRICK
|移除Brick|# gluster volume remove-brick VOLNAME BRICK start/status/commit
|I/O信息查看|Profile Command 提供接口查看一个卷中的每一个 brick 的 IO 信息。<br>//启动 profiling，之后则可以进行 IO 信息查看<br>#gluster volume profile VOLNAME start<br>查看 IO 信息，可以查看到每一个 Brick 的 IO 信息.<br>#gluster volume profile VOLNAME info<br>查看结束之后关闭 profiling 功能<br># gluster volume profile VOLNAME stop


2. 节点管理-gluster peer command
1. 节点状态

        #gluster peer status //在 serser0 上操作，只能看到其他节点与 server0 的连接状态
        Number of Peers: 2
        Hostname: server1
        Uuid: 5e987bda-16dd-43c2-835b-08b7d55e94e5
        State: Peer in Cluster (Connected)
        Hostname: server2
        Uuid: 1e0ca3aa-9ef7-4f66-8f15-cbc348f29ff7
        State: Peer in Cluster (Connected)
2. 添加节点
        #gluster peer probe HOSTNAME
        #gluster peer probe server2 //将server2 添加到存储池中

3. 删除节点
        #gluster peer detach HOSTNAME
        #gluster peer detach server2 将 server2 从存储池中移除
        //移除节点时，需要确保该节点上没有 brick，需要提前将 brick 移除
* 创建卷
1. 分布式卷

        # gluster volume create NEW¬VOLNAME [transport [tcp | rdma | tcp,rdma]] NEW¬BRICK...
        For example, to create a distributed volume with four storage servers using tcp:
        # gluster volume create test¬volume server1:/exp1 server2:/exp2 server3:/exp3 server4:/exp4
        Creation of test¬volume has been successful
        Please start the volume to access data.

2. 复制卷

        # gluster volume create NEW¬VOLNAME [replica COUNT] [transport [tcp |rdma | tcp,rdma]] NEW¬BRICK...
        For example, to create a replicated volume with two storage servers:
        # gluster volume create test¬volume replica 2 transport tcp server1:/exp1 server2:/exp2
        Creation of test¬volume has been successful
        Please start the volume to access data.
3. 条带卷

        # gluster volume create NEW¬VOLNAME [stripe COUNT] [transport [tcp |
        rdma | tcp,rdma]] NEW¬BRICK...
        For example, to create a striped volume across two storage servers:
        # gluster volume create test¬volume stripe 2 transport tcp server1:/exp1 server2:/exp2
        Creation of test¬volume has been successful
        Please start the volume to access data.
4. 分佈式条带卷（復合型）

        # gluster volume create NEW¬VOLNAME [stripe COUNT] [transport [tcp |
        rdma | tcp,rdma]] NEW¬BRICK...
        For example, to create a distributed striped volume across eight storage servers:
        # gluster volume create test¬volume stripe 4 transport tcp server1:/exp1 server2:/exp2
        server3:/exp3 server4:/exp4 server5:/exp5 server6:/exp6 server7:/exp7 server8:/exp8
        Creation of test¬volume has been successful
        Please start the volume to access data.
5. 分布式復制卷（復合型）

        # gluster volume create NEW¬VOLNAME [replica COUNT] [transport [tcp |
        rdma | tcp,rdma]] NEW¬BRICK...
        For example, four node distributed (replicated) volume with a two¬way mirror:
        # gluster volume create test¬volume replica 2 transport tcp server1:/exp1 server2:/exp2 server3:/exp3 server4:/exp4
        Creation of test¬volume has been successful
        Please start the volume to access data.
        For example, to create a six node distributed (replicated) volume with a two¬way mirror:
        # gluster volume create test¬volume replica 2 transport tcp server1:/exp1 server2:/exp2 server3:/exp3 server4:/exp4 server5:/exp5 server6:/exp6
        Creation of test¬volume has been successful
        Please start the volume to access data.
6. 条带復制卷（復合型）

        # gluster volume create NEW¬VOLNAME [stripe COUNT] [replica COUNT]
        [transport [tcp | rdma | tcp,rdma]] NEW¬BRICK...
        For example, to create a striped replicated volume across four storage servers:
        # gluster volume create test¬volume stripe 2 replica 2 transport tcp server1:/exp1
        server2:/exp2 server3:/exp3 server4:/exp4
        Creation of test¬volume has been successful
        Please start the volume to access data.
        To create a striped replicated volume across six storage servers:
        # gluster volume create test¬volume stripe 3 replica 2 transport tcp server1:/exp1
        server2:/exp2 server3:/exp3 server4:/exp4 server5:/exp5 server6:/exp6
        Creation of test¬volume has been successful
        Please start the volume to access data.
7. 分布式条带復制卷(三種混合型)

        # gluster volume create NEW¬VOLNAME [stripe COUNT] [replica COUNT]
        [transport [tcp | rdma | tcp,rdma]] NEW¬BRICK...
        For example, to create a distributed replicated striped volume across eight storage servers:
        # gluster volume create test¬volume stripe 2 replica 2 transport tcp server1:/exp1
        server2:/exp2 server3:/exp3 server4:/exp4 server5:/exp5 server6:/exp6 server7:/exp7
        server8:/exp8
        Creation of test¬volume has been successful
        Please start the volume to access data.
* 卷管理
1. 卷信息

        #gluster volume info
        //该命令能够查看存储池中的当前卷的信息，包括卷方式、包涵的 brick、卷的当前状态、卷名及 UUID 等。
2. 卷状态

        #gluster volume status
        //该命令能够查看当前卷的状态，包括其中各个 brick 的状态， NFS 的服务状态及当前 task执行情况，和一些系统设置状态等。
3. 启动||停止卷

        # gluster volume start/stop VOLNAME
        //将创建的卷启动，才能进行客户端挂载； stop 能够将系统卷停止，无法使用；此外 gluster
        未提供 restart 的重启命令
4. 删除卷
        # gluster volume delete VOLNAME
        //删除卷操作能够将整个卷删除，操作前提是需要将卷先停止
* Brick管理
1. 添加 Brick

        若是副本卷，则一次添加的 Bricks 数是 replica 的整数倍； stripe 具有同样的要求。
        # gluster volume add-brick VOLNAME NEW-BRICK
        #gluster volume add-brick dht_vol server3:/mnt/sdc1
        //添加 server3 上的/mnt/sdc1 到卷 dht_vol 上。
2. 移除 Brick

        若是副本卷，则移除的 Bricks 数是 replica 的整数倍； stripe 具有同样的要求。
        #gluster volume remove-brick VOLNAME BRICK start/status/commit
        #gluster volume remove-brick dht_vol start
        //GlusterFS_3.4.1 版本在执行移除 Brick 的时候会将数据迁移到其他可用的 Brick 上，当数据迁移结束之后才将 Brick 移除。 执行 start 命令，开始迁移数据，正常移除 Brick。
        #gluster volume remove-brick dht_vol status
        //在执行开始移除 task 之后，可以使用 status 命令进行 task 状态查看。
        #gluster volume remove-brick dht_vol commit
        //使用 commit 命令执行 Brick 移除，则不会进行数据迁移而直接删除 Brick，符合不需要数据迁移的用户需求。
        PS：系统的扩容及缩容可以通过如上节点管理、 Brick 管理组合达到目的。
        (1)扩容时，可以先增加系统节点，然后添加新增节点上的 Brick 即可。
        (2)缩容时，先移除 Brick
3. 替换 Brick

        #gluster volume replace-brick VOLNAME BRICKNEW-BRICK start/pause/abort/status/commit
        #gluster volume replace-brick dht_vol server0:/mnt/sdb1 server0:/mnt/sdc1 start
        //如上，执行 replcace-brick 卷替换启动命令，使用 start 启动命令后，开始将原始 Brick 的数据迁移到即将需要替换的 Brick 上。
        #gluster volume replace-brick dht_vol server0:/mnt/sdb1 server0:/mnt/sdc1 status
        //在数据迁移的过程中，可以查看替换任务是否完成。
        #gluster volume replace-brick dht_vol server0:/mnt/sdb1 server0:/mnt/sdc1 abort
        //在数据迁移的过程中，可以执行 abort 命令终止 Brick 替换。
        #gluster volume replace-brick dht_vol server0:/mnt/sdb1 server0:/mnt/sdc1 commit
        //在数据迁移结束之后，执行 commit 命令结束任务，则进行 Brick 替换。 使用 volume info
        命令可以查看到 Brick 已经被替换。

* 挂载gfs的方法

        #mkdir /gfs
        #mount.glusterfs  gfs1.hrb:/gfs  /gfs
        备注：也可通过smb和nfs的方式进行挂载

### GlusterFS Top监控
Top command 允许你查看 bricks 的性能例如： read, write, file open calls, file read calls, file
write calls, directory open calls, and directory real calls所有的查看都可以设top数，默认 100

    # gluster volume top VOLNAME open [brick BRICK-NAME] [list-cnt cnt]
    //查看打开的 fd
    #gluster volume top VOLNAME read [brick BRICK-NAME] [list-cnt cnt]
    //查看调用次数最多的读调用
    #gluster volume top VOLNAME write [brick BRICK-NAME] [list-cnt cnt]
    //查看调用次数最多的写调用
    # gluster volume top VOLNAME opendir [brick BRICK-NAME] [list-cnt cnt]
    # gluster volume top VOLNAME readdir [brick BRICK-NAME] [list-cnt cnt]
    //查看次数最多的目录调用
    # gluster volume top VOLNAME read-perf [bs blk-size count count] [brick BRICK-NAME] [list-cnt
    cnt]
    //查看每个 Brick 的读性能
    # gluster volume top VOLNAME write-perf [bs blk-size count count] [brick BRICK-NAME]
    [list-cnt cnt]
    //查看每个 Brick 的写性能

### 7.性能优化参数 （补全优化含义）
    #gluster vol set gfs ……
    performance.io-cache: on
    performance.read-ahead: on
    performance.quick-read: on
    performance.write-behind-window-size: 1073741824
    performance.flush-behind: on
    performance.write-behind: on
    performance.client-io-threads: on
    performance.io-thread-count: 64
    performance.cache-refresh-timeout: 1
    performance.cache-size: 4GB

## 实际操作案例
1. 实施部署
        
        GFS安装-参考GlusterFS安装部分

2. 配置双副本GFS

        gluster peer info
        gluster peer status
        gluster peer probe g3.com
        gluster peer probe g4.com
        gluster volume create gfs replica 2 g3:/data g4:/data force

3. 双副本添加主机

        gluster peer info
        gluster peer status
        gluster peer probe g3.com
        gluster peer probe g4.com
        gluster volume add-brick gfs g3:/data g4:/data force
4. 进行资源重新平衡

        Gluster volume rebalance gfs status
        Gluster volume rebalance gfs start


## IO加速/ssd加速
### 背景知识：
1. 在计算机系统中，cache几乎无处不在，CPU、LINUX、MYSQL、IO等系统中均能见到cache的身影。Cache是容量与性能之间取平衡的结果，以更低的成本，获得更高的收益。
2. 在计算机硬件发展的几十年来，传统的机械硬盘逐步成为整个系统的瓶颈，性能增长十分缓慢。对于依赖IO性能的应用Flash disk(SSD/FusionIO等)的出现，改变了这一切。
3. Flash disk将硬盘从机械产品变成了电气产品，功耗更小，性能更好，时延更优。但新的技术还存在一些问题，价格以及稳定性。
4. Flashcache是Facebook技术团队的一个开源项目，最初是为加速MySQL设计。Flashcache通过在文件系统（VFS）和设备驱动之间新增了一次缓存层，来实现对热门数据的缓存。

### Flashcache在内核的层次：

![](../images/Glusterfs/10.png)

* 一般用SSD作为介质的缓存，通过将传统硬盘上的热门数据缓存到SSD上，然后利用SSD优秀的读性能，来加速系统。这个方法较之内存缓存，没有内存快，但是空间可以比内存大很多。
* Flashcache最初的实现是write backup机制cache，后来又加入了write through和write around机制：
1. write backup: 先写入到cahce， 然后cache中的脏块会由后台定期刷到持久存储。
2. write through: 同步写入到cache和持久存储。
3. write around: 只写入到持久存储。

### 谁适合用Flashcache
读多写少。
高压力备库。
数据量很大（ 例如4TB） ， 热门数据也很大（ 800GB） ， 不必要或者不舍得全部买内存来缓存。
### 谁不适合用Flashcache
数据量不大的话， 一般Flashcache就没什么用武之地了， 内存就可以帮你解决问题了。
另外Flashcache的加入也使得系统的复杂度增加了一层， 如果你坚持KISS原则（ Keep it simple, Stupid!） ， 也可
以弃用之。

### 基本原理图
![](../images/Glusterfs/11.png)


### 安装加速
        下载地址： https://github.com/facebookarchive/flashcache
        #Unzip flashcache-master.zip
        #Make ; make install
### Flash cache配置
1. 首次创建Flashcach设备

                请注意， 设备上的文件将会被清空
                首先确保hdd的分区没有被挂载， 如果挂载了， 卸载之
                [root@localhost flashcache-master]# umount /dev/sda5
                [root@localhost flashcache-master]# flashcache_create -p back cachedev /dev/sdb /dev/sda5
                这样Linux就虚拟除了一个带缓存的块设备：
                [root@localhost flashcache-master]# ls -lah /dev/mapper/cachedev
                [root@localhost mapper]# mkfs.ext3 cachedev
2. 使用该设备
                
                [root@localhost flashcache-master]# mount /dev/mapper/cachedev /data/
3. 如何重建flashcache

                umount /data
                dmsetup remove cachedev
                flashcache_destroy /dev/sdb
4. 查询状态

                dmsetup status cachedev
                dmsetup table cachedev
                dmsetup info cachedev
5. flashcache内核参数设置

                dev.flashcache.fast_remove:删除flashcache卷时不同步脏缓存块。 这个选项用来快速删除。
                dev.flashcache.zero_stats:统计信息归零。
                dev.flashcache.reclaim_policy:缓存回收规则。 有两种算法： 先进先出FIFO(0),最近最少用LRU(1).默认是FIFO。
                dev.flashcache.write_merge:启用写入合并， 默认是开启的。
                dev.flashcache.dirty_thresh_pct:flachcache尝试保持每个单元的脏块在这个n%以下。 设置低增加磁盘写入和降低块重写， 但是增加了块读取缓存的可用性。
                dev.flashcache.do_sync:调度清除缓存中的所有脏块。
                dev.flashcache.stop_sync:停止同步操作。
                dev.flashcache.cache_all:全局缓存模式： 缓存所有和全部不缓存。 默认是缓存所有。
                dev.flashcache.fallow_delay:清除脏块的间隔。 默认60s.设置为0禁止空闲， 彻底清除。
                dev.flashcache.io_latency_hist:计算IO等待时间， 并绘制直方图。
                dev.flashcache.max_clean_ios_set:在清除块时， 每单元最大写入出错。
                dev.flashcache.max_clean_ios_total:在同步所有块时， 最大写入问题。
                dev.flashcache.debug:开启debug。
                dev.flashcache.do_pid_expiry:在白/黑名单上启用逾期的pid列表。




