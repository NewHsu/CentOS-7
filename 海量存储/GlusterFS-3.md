## 6. 配额

      1. 设置配额
      [root@node3 ~]# gluster volume quota Gluster-mod enable
      volume quota : success
      [root@node3 ~]# gluster volume quota Gluster-mod limit-usage / 20GB  <----限制 Gluster-mode中 / 最大使用 20GB 空间
      volume quota : success
      [root@node3 ~]# gluster volume quota Gluster-mod limit-usage /quotadir 2GB   <----限制Gluster-mod中的 /quotadir 目录配额2G
      volume quota : success
      [root@node3 ~]# gluster volume quota Gluster-mod list
      Path                   Hard-limit  Soft-limit      Used  Available  Soft-limit exceeded? Hard-limit exceeded?
      -------------------------------------------------------------------------------------------------------------------
      /                       20.0GB     80%(16.0GB)    2.1GB  17.9GB              No                   No
      /quotadir                2.0GB     80%(1.6GB)     0Bytes   2.0GB              No                   No

      2. 查看选项
      [root@node3 ~]# gluster volume set Gluster-mod quota-deem-statfs on <----开启配额查看
      [root@node3 ~]# gluster volume set Gluster-mod quota-deem-statfs on <----关闭配额查看

      3. 内存更新
      从性能角度考虑，配额缓存在客户端的目录容量里。如果发生多个客户同时都往同一个目录写数据，可能会发生一种情况，某些客户端一直写入数据到目录直到超出配额限制。
      这里就有一个误区，客户端写入的数据即使超出目录的磁盘容量限制，依然允许写入新数据，因为客户端存在缓存，而实际的缓存大小和真实的GlusterFS数据大小是不同步的。当缓存超时，则服务器会刷新缓存，进行同步，才不会允许进一步的数据写入。
      [root@node3 ~]# gluster volume set Gluster-mod features.hard-timeout 5 <----5秒刷新
      [root@node3 ~]# gluster volume set Gluster-mod features.soft-timeout 5 <----5秒刷新

      4. 设置提醒时间
      提醒时间是一个当使用信息达到软限制写入日志后的提醒频率（默认一周）
      [root@node3 ~]# gluster volume quota Gluster-mod alert-time 2d  <----修改为2天

      5.  删除磁盘限制
      [root@node3 ~]# gluster volume quota Gluster-mod remove /
      [root@node3 ~]# gluster volume quota Gluster-mod remove /quotadir
