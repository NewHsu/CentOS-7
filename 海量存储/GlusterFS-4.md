# GlusterFS常用指令
## 1. 节点管理-gluster peer command

  1. 节点状态

          # gluster peer status
          Number of Peers: 2
          Hostname: server1
          Uuid: 5e987bda-16dd-43c2-835b-08b7d55e94e5
          State: Peer in Cluster (Connected)
          Hostname: server2
          Uuid: 1e0ca3aa-9ef7-4f66-8f15-cbc348f29ff7
          State: Peer in Cluster (Connected)
  2. 添加节点

          #gluster peer probe HOSTNAME
          #gluster peer probe node2 //将node2 添加到存储池中
  3. 删除节点

          #gluster peer detach HOSTNAME
          #gluster peer detach node2 将 node2 从存储池中移除
          //移除节点时，需要确保该节点上没有 brick，需要提前将 brick 移除

## 3.创建卷
  1. 分布式卷

          # gluster volume create NEW¬VOLNAME [transport [tcp | rdma | tcp,rdma]] NEW¬BRICK...

          # gluster volume create test¬volume node1:/exp1 node2:/exp2 node3:/exp3 node4:/exp4


2. 复制卷

        # gluster volume create NEW¬VOLNAME [replica COUNT] [transport [tcp |rdma | tcp,rdma]] NEW¬BRICK...

        # gluster volume create test¬volume replica 2 transport tcp node1:/exp1 node2:/exp2

3. 条带卷

        # gluster volume create NEW¬VOLNAME [stripe COUNT] [transport [tcp |
        rdma | tcp,rdma]] NEW¬BRICK...

        # gluster volume create test¬volume stripe 2 transport tcp node1:/exp1 node2:/exp2

4. 分佈式条带卷（復合型）

        # gluster volume create NEW¬VOLNAME [stripe COUNT] [transport [tcp |
        rdma | tcp,rdma]] NEW¬BRICK...

        # gluster volume create test¬volume stripe 4 transport tcp node1:/exp1 node2:/exp2
        node3:/exp3 node4:/exp4 node5:/exp5 node6:/exp6 node7:/exp7 node8:/exp8

5. 分布式復制卷（復合型）

        # gluster volume create NEW¬VOLNAME [replica COUNT] [transport [tcp |
        rdma | tcp,rdma]] NEW¬BRICK...

        # gluster volume create test¬volume replica 2 transport tcp node1:/exp1 node2:/exp2 node3:/exp3 node4:/exp4

        # gluster volume create test¬volume replica 2 transport tcp node1:/exp1 node2:/exp2 node3:/exp3 node4:/exp4 node5:/exp5 node6:/exp6

6. 条带復制卷（復合型）

        # gluster volume create NEW¬VOLNAME [stripe COUNT] [replica COUNT]
        [transport [tcp | rdma | tcp,rdma]] NEW¬BRICK...

        # gluster volume create test¬volume stripe 2 replica 2 transport tcp node1:/exp1
        node2:/exp2 node3:/exp3 node4:/exp4


        # gluster volume create test¬volume stripe 3 replica 2 transport tcp node1:/exp1
        node2:/exp2 node3:/exp3 node4:/exp4 node5:/exp5 node6:/exp6

7. 分布式条带復制卷(三種混合型)

        # gluster volume create NEW¬VOLNAME [stripe COUNT] [replica COUNT]
        [transport [tcp | rdma | tcp,rdma]] NEW¬BRICK...

        # gluster volume create test¬volume stripe 2 replica 2 transport tcp node1:/exp1
        node2:/exp2 node3:/exp3 node4:/exp4 node5:/exp5 node6:/exp6 node7:/exp7
        node8:/exp8

## 4.卷管理
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
## 5.Brick管理
1. 添加 Brick

        若是副本卷，则一次添加的 Bricks 数是 replica 的整数倍； stripe 具有同样的要求。
        # gluster volume add-brick VOLNAME NEW-BRICK

2. 移除 Brick

        若是副本卷，则移除的 Bricks 数是 replica 的整数倍； stripe 具有同样的要求。
        # gluster volume volume remove-brick <VOLNAME> [replica <COUNT>] <BRICK> ... <start|stop|status|commit|force>
3. 替换 Brick

        # gluster volume replace-brick VOLNAME BRICKNEW-BRICK start/pause/abort/status/commit

* 挂载gfs的方法

        #mkdir /gfs
        #mount.glusterfs  gfs1.hrb:/gfs  /gfs
        备注：也可通过smb和nfs的方式进行挂载，还请使用mount.glusterfs的方式挂载使用。

## 6.GlusterFS Top监控

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

## 7. Logging

    1. Glusterd:  /var/log/glusterfs/etc-glusterfs-glusterd.vol.log
    2. Gluster cli command: /var/log/glusterfs/cmd_history.log
    3. Bricks: /var/log/glusterfs/bricks/<path extraction of brick path>.log
    4. Rebalance: /var/log/glusterfs/VOLNAME-rebalance.log
    5. Self heal deamon: /var/log/glusterfs/glustershd.log
    6. Gluster NFS: /var/log/glusterfs/nfs.log
    7. SAMBA Gluster: /var/log/samba/glusterfs-VOLNAME-<ClientIp>.log
    8. FUSE Mount: /var/log/glusterfs/<mountpoint path extraction>.log
    9. Geo-replication: /var/log/glusterfs/geo-replication/<master>   /var/log/glusterfs/geo-replication-slaves
    10. Gluster volume heal VOLNAME info command: /var/log/glusterfs/glfsheal-VOLNAME.log
