# LVM-精简资源
## 1 精简资源介绍

### 1.1 精简资源调配是什么？
* 你有10个客户，有15G的存储资源，现在要求你给每个人配置2G的存储空间，按照常规的模式，恐怕是不够划分吧？可以试想，如果划分了2G的空间给用户存储数据，但是用户只用到1G，而另外的1G会慢慢填满，又或者干脆用不到。所以会不会有一种方式，随着数据量扩展，最终达到上限呢？答案就是“精简资源”配置。

* 实际生产中，我们会将LVM的存储空间分为“富卷”和“瘦卷”。富卷即是较多时间使用空间的80%，而瘦卷一般都在50%以下，所以很多瘦卷的另外50%可以超限继续划分出去使用。但是不管怎么划分和精简，一旦超出总量去划分，那么兑现的时刻就会出现麻烦（这就好比你有1亿的资产，却有2亿的外债，一旦债主都找上门，就资不抵债了）。精简资源调配中所做的是，在较大卷组中定义一个精简池，再在精简池中定义一个精简卷。这个精简卷看上去的实际空间和所需空间完全无差异。然而，这个精简卷的空间是随着数据增长而扩充。

>警告：从那15GB空间中，如果我们对资源调配超过15GB了，那就是过度资源调配了。

### 1.2 如何工作的？
* 初始化提供给客户2GB空间，但是客户可能只用了1GB，而另外的1GB还空闲着。如果客户是需要富卷，那么将不能这么做，因为它一开始就分配了整个空间，这部分被划分出去的空间无法在精简池中进行超限使用。
* 在精简资源调配中，如果为客户定义了2GB空间，它会根据你的数据写入而增长。
* 但是，必须对各个卷的增长情况进行监控，否则结局会是个灾难。在过度资源调配完成后，如果所有客户都尽量写入数据到磁盘，那么将会导致数据溢出，从而导致这些卷下线。

## 2. 精简资源 实例

### 2.1 试验环境
|系统版本|磁盘数量|ip地址|主机名称|虚拟化|
|:---|:---|:---|:---|:---|
|CentOS 7.4|4Vdisk|192.168.56.101|LVM-Host|Vbox|

### 4.2 测试内容和环境说明
1. 创建精简卷，并进行验证。

### 实例步骤
1. 确认VG使用空间
    
        [root@lvm-host ~]# vgs
        VG     #PV #LV #SN Attr   VSize    VFree
        BooK     2   1   0 wz--n-   29.99g 19.99g
2. 创建一个15G的精简卷池
    
        [root@lvm-host ~]# lvcreate -L 15G --thinpool thinthin_pool BooK
        Using default stripesize 64.00 KiB.
        Thin pool volume with chunk size 64.00 KiB can address at most 15.81 TiB of data.
        Logical volume "thinthin_pool" created.

        [root@lvm-host ~]# lvs
        LV            VG     Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
        testlv        BooK   -wi-ao---- 10.00g
        thinthin_pool BooK   twi-a-tz-- 15.00g             0.00   0.59     
        // -L 卷组大小、–thinpool 创建精简池、tthinthin_pool 精简池名称、BooK 精简池的卷组名称

3. 创建精简卷，名称为 thin_client1 

        [root@lvm-host ~]# lvcreate -V 2G --thin -n thin_client1 BooK/thinthin_pool
        Using default stripesize 64.00 KiB.
        Logical volume "thin_client1" created.

        [root@lvm-host ~]# lvs
        LV            VG     Attr       LSize  Pool          Origin Data%  Meta%  Move Log Cpy%Sync Convert
        thin_client1  BooK   Vwi-a-tz--  2.00g thinthin_pool        0.00
        thinthin_pool BooK   twi-aotz-- 15.00g                      0.00   0.61
        注意Data%使用依然是0.00，继续向下创建更多用户的精简卷。

4. 创建精简卷，名称为 thin_client2、thin_client3、thin_client4、thin_client5、thin_client6

        [root@lvm-host ~]# lvcreate -V 2G --thin -n thin_client2 BooK/thinthin_pool
        Using default stripesize 64.00 KiB.
        Logical volume "thin_client2" created.
        注意更改名称编号“thin_client2、thin_client3、thin_client4、thin_client5、thin_client6”

        [root@lvm-host ~]# lvs
        LV            VG     Attr       LSize  Pool          Origin Data%  Meta%  Move Log Cpy%Sync Convert
        thin_client1  BooK   Vwi-a-tz--  2.00g thinthin_pool        0.00
        thin_client2  BooK   Vwi-a-tz--  2.00g thinthin_pool        0.00
        thin_client3  BooK   Vwi-a-tz--  2.00g thinthin_pool        0.00
        thin_client4  BooK   Vwi-a-tz--  2.00g thinthin_pool        0.00
        thin_client5  BooK   Vwi-a-tz--  2.00g thinthin_pool        0.00
        thin_client6  BooK   Vwi-a-tz--  2.00g thinthin_pool        0.00
        thinthin_pool BooK   twi-aotz-- 15.00g                      0.00   0.73

        即使我创建在做，只要不写入数据，那么就不会占满整个磁盘，可以继续划分更多的2G，目前已经达到12G了。

5. 挂载使用
    
        [root@lvm-host ~]# for i in {1..3}; do mkdir /client$i ;done
        [root@lvm-host ~]# for i in {1..3};do mkfs.ext4 /dev/BooK/thin_client$i ; done 
        [root@lvm-host ~]# for i in {1..3};do mount  /dev/BooK/thin_client$i /client$i ; done     
        [root@lvm-host ~]# mount | grep client
        /dev/mapper/BooK-thin_client1 on /client1 type ext4 (rw,relatime,seclabel,stripe=16,data=ordered)
        ......
        [root@lvm-host ~]# df -hT
        Filesystem                    Type      Size  Used Avail Use% Mounted on
        /dev/mapper/BooK-thin_client1 ext4      2.0G  6.0M  1.8G   1% /client1
        ......
6. 写入数据

        [root@lvm-host ~]# for i in {1..3};do dd if=/dev/zero of=/client$i/$i.img bs=${i}M count=100; done
        104857600 bytes (105 MB) copied, 0.142149 s, 738 MB/s
        209715200 bytes (210 MB) copied, 0.492435 s, 426 MB/s
        314572800 bytes (315 MB) copied, 0.695932 s, 452 MB/s
    
        [root@lvm-host ~]# df -Th
        Filesystem                    Type      Size  Used Avail Use% Mounted on
        /dev/mapper/BooK-thin_client1 ext4      2.0G  106M  1.7G   6% /client1
        /dev/mapper/BooK-thin_client2 ext4      2.0G  206M  1.6G  12% /client2
        /dev/mapper/BooK-thin_client3 ext4      2.0G  306M  1.5G  17% /client3

        [root@lvm-host ~]# lvs
        LV            VG     Attr       LSize  Pool          Origin Data%  Meta%  Move Log Cpy%Sync Convert
        testlv        BooK   -wi-ao---- 10.00g
        thin_client1  BooK   Vwi-aotz--  2.00g thinthin_pool        9.65
        thin_client2  BooK   Vwi-aotz--  2.00g thinthin_pool        14.53
        thin_client3  BooK   Vwi-aotz--  2.00g thinthin_pool        19.41
        ......
        thinthin_pool BooK   twi-aotz-- 15.00g                      5.81   3.25     
        每个卷的使用大小和精简池的使用大小。 客户端分别是2G空间的9.65%/14.53%/19.41%;整体精简卷使用5.81%
7. 再次划分4G空间给client7

        [root@lvm-host ~]# lvcreate -V 4G --thin -n thin_client7 BooK/thinthin_pool
        ......
        Logical volume "thin_client7" created.
        [root@lvm-host ~]# lvs
        LV            VG     Attr       LSize  Pool          Origin Data%  Meta%  Move Log Cpy%Sync Convert
        thin_client1  BooK   Vwi-aotz--  2.00g thinthin_pool        9.65
        thin_client2  BooK   Vwi-aotz--  2.00g thinthin_pool        14.53
        thin_client3  BooK   Vwi-aotz--  2.00g thinthin_pool        19.41
        ......
        thin_client7  BooK   Vwi-a-tz--  4.00g thinthin_pool        0.00
        thinthin_pool BooK   twi-aotz-- 15.00g                      5.81   3.27

8. 对client7进行挂载使用，同时多模拟多客户写入，出现兑现风险。

        [root@lvm-host ~]# mkdir /client7
        [root@lvm-host ~]# mkfs.ext4 /dev/BooK/thin_client7
        [root@lvm-host ~]# mount /dev/BooK/thin_client7 /client7/
        [root@lvm-host ~]# dd if=/dev/zero of=/client7/7.img bs=1M count=3000
        [root@lvm-host ~]# dd if=/dev/zero of=/client1/test.img bs=1M count=1200
        [root@lvm-host ~]# dd if=/dev/zero of=/client2/test.img bs=1M count=1200
        [root@lvm-host ~]# dd if=/dev/zero of=/client3/test.img bs=1M count=1200
        [root@lvm-host ~]# lvs
        LV            VG     Attr       LSize  Pool          Origin Data%  Meta%  Move Log Cpy%Sync Convert
        testlv        BooK   -wi-ao---- 10.00g
        thin_client1  BooK   Vwi-aotz--  2.00g thinthin_pool        68.24
        thin_client2  BooK   Vwi-aotz--  2.00g thinthin_pool        99.77
        thin_client3  BooK   Vwi-aotz--  2.00g thinthin_pool        78.01
        thin_client7  BooK   Vwi-aotz--  4.00g thinthin_pool        78.00
        thinthin_pool BooK   twi-aotz-- 15.00g                      53.60  24.68   

        现在整体的精简池已经使用到53.60%，数据还在急剧的增长，预计2天后将超出精简大小，那么要如何处理呢？
9. 精简池只是一个逻辑卷，因此，如果我们需要对其进行扩展，我们可以使用和扩展逻辑卷一样的命令，但我们不能缩减精简池大小。

        [root@lvm-host ~]# vgs
         VG     #PV #LV #SN Attr   VSize    VFree
        BooK     2   9   0 wz--n-   29.99g 4.96g
        还free 4G多，模拟扩充。

        [root@lvm-host ~]# lvextend -L +4G  /dev/BooK/thinthin_pool
        Size of logical volume BooK/thinthin_pool_tdata changed from 15.00 GiB (3840 extents) to 19.00 GiB (4864 extents).
        Logical volume BooK/thinthin_pool_tdata successfully resized.
        
        [root@lvm-host ~]# lvs
        LV            VG     Attr       LSize  Pool          Origin Data%  Meta%  Move Log Cpy%Sync Convert
        testlv        BooK   -wi-ao---- 10.00g
        thin_client1  BooK   Vwi-aotz--  2.00g thinthin_pool        68.24
        thin_client2  BooK   Vwi-aotz--  2.00g thinthin_pool        99.77
        thin_client3  BooK   Vwi-aotz--  2.00g thinthin_pool        78.01
        thin_client7  BooK   Vwi-aotz--  4.00g thinthin_pool        78.00
        thinthin_pool BooK   twi-aotz-- 19.00g                      42.32  24.68

        查看的时候可以看到thinthin_pool 空间已经由15G扩充到19G了，随即百分比也下降到43.32%了。

>重要：要自动扩展thin_pool，可以通过修改配置文件来实现。对于手动扩展，我们可以使用lvextend。
        
        使用vim编辑器打开lvm配置文件。
        # vim /etc/lvm/lvm.conf
        搜索autoextend
        thin_pool_autoextend_threshold = 100
        thin_pool_autoextend_percent = 20
>修改此处的100为80，这样达到80%使用的时候，将自动扩展20%，这样，就可以自动扩容了。这将把thin_pool 从超载导致下线事故中拯救出来.
## 总结
    精简资源配置在生产中常用在承载备份的服务器或者是文件服务器，尽可能多的分配用户资源，但是这些用户都不会饱和资源。    

