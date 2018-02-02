# LVM Cache & Snapshot
## 1. LVM Cache
### 1.1 Cache介绍 
* 现在的服务器大多数搭配SSD的磁盘，而SSD的磁盘也是总所周知的要比普通磁盘快很多，所以通常将SSD作为安装系统的磁盘来使用，然后数据还是要写入物理磁盘，外围系统和数据的响应依然要等待慢如牛的物理磁盘做出回复。瓶颈所在的原因是“系统加速不等于应用的数据读取和写入加速”，除非你将应用也放到ssd磁盘上来运行，但是ssd的设备还是相当昂贵的，所以必须找到一种折中的方案来利用ssd磁盘，达到整体加速的效果。

* 现在的LVM已经支持使用缓存技术来提升读写速度，为何不将ssd磁盘作为lvm的缓存来使用呢？这样就可以对整个lvm加速，换句话说，可以对整个系统lv和数据lv进行加速，这样的利用要远比单纯的给系统使用更有价值！

### 1.2 Cache & SSD
1. 在计算机中，无论是基础硬件设备，还是操作系统，以及应用软件中均能见到cache的身影。Cache是容量与性能之间取平衡的结果，以更低的成本，获得更高的收益。
2. 在计算机硬件发展的历程中，传统的机械硬盘逐步成为整个系统的瓶颈，性能增长十分缓慢。现金能够提升IO性能的Flashdisk(SSD/FusionIO等)出现，改变了这一切。
3. Flash disk将硬盘从机械产品变成了电气产品，功耗更小，性能更好，时延更优。但Flash disk技术还存在一些问题，昂贵的价格以及稳定性，最主要的是磁盘的`使用寿命`。

### 1.3 LVM SSD缓存
* 为了最有性价比的利用SSD设备来加速整个系统，可以使用默认的DM-cache。当然也可以使用FlashCache等技术，由于CentOS 7 自身是支持LVM使用DM-cache，所以就用CentOS 7 自带的来配置缓存；当然FlashCache也是很好的选择。
>flashcache 技术参考GlusterFS章节

### 1.4 DM-cache 原理简介
* dm-cache 使用 device mapper 核心，并在上面增加一个策略层。这个策略层很像一个插件接口，可以实现不同的策略。这些策略（以及缓存的内容）决定了缓存是否可以命中，是否需要进行数据迁移（在原始设备与缓存设备之间进行某个方向的数据移动）。
* 目前已经实现了包括最近最少用（LRU）、最常使用（MFU）等策略，但目前只有缺省的“mq”策略合并到内核中了，以便减少起初需要测试到的策略数量。文件系统可以为策略提供 hints，比如某些块脏了，或是某些块已经被放弃了。这些信息有助于策略更好地决定块要存储到的位置。

### 1.5 理解Lvm cache的相关术语

        lvmcache(7) ：
        origin LV           OriginLV      large slow LV
        cache data LV       CacheDataLV   small fast LV for cache pool data
        cache metadata LV   CacheMetaLV   small fast LV for cache pool metadata
        cache pool LV       CachePoolLV   CacheDataLV + CacheMetaLV
        cache LV            CacheLV       OriginLV + CachePoolLV

        1：真实的LV卷，很大的慢速设备LV
        2：cache 数据卷  可以很小，但是必须很快，用来缓存数据
        3：Cache 元数据卷 可以很小，但是必须很快，用来缓存元数据
        4：Cache Pool LV ：缓存池，包含 data+meta
        5：Cache LV ：    缓存卷，包含 真实的LV卷+缓存池

        实际的创建顺序也就是 1到5的步骤。

## 2. DM Cache 实例

### 2.1 试验环境
|系统版本|磁盘数量|ip地址|主机名称|虚拟化|
|:---|:---|:---|:---|:---|
|CentOS 7.4|4Vdisk|192.168.56.101|LVM-Host|Vbox|

### 2.2 测试内容和环境说明
1. 利用sdb1模拟ssd磁盘分区，为Originlv添加Cache。

### 2.3 Lvm SSD缓存创建（DM-cache）
1. 确认设备

        [root@LVM-Host ~]# lsblk
        NAME            MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
        sdb               8:16   0   10G  0 disk
        └─sdb1            8:17   0   10G  0 part
        sdc               8:32   0   20G  0 disk
        └─sdc1            8:33   0   20G  0 part
        上例中，sdc为普通物理磁盘20G，sdb为SSD磁盘10G（模拟）

2. 创建VG和LVs

        [root@LVM-Host ~]# vgcreate CacheTestVG /dev/sdc1

        [root@LVM-Host ~]# lvcreate -L +15G -n Originlv CacheTestVG
        WARNING: ext4 signature detected on /dev/CacheTestVG/Originlv at offset 1080. Wipe it? [y/n]: y
        Wiping ext4 signature on /dev/CacheTestVG/Originlv.
        Logical volume "Originlv" created.
        创建真实卷，大小15G，真实的LV卷，很大的慢速设备LV

3. SSD设备加入慢速VG卷组

        所有的必须在一个卷组中，实际上就是一个VG卷组既包含慢速设备同时也要包含快速设备，所以必须将SSD设备加入到先前创建的卷组中
        [root@LVM-Host ~]# vgextend CacheTestVG /dev/sdb1
        Volume group "CacheTestVG" successfully extended

4. 创建SSD的LV缓存

        SSD设备需要创建2个LVs 。
        1. CacheDataLV ，数据缓存
        2. CacheMetaLV，是用于存储被高速缓存在CacheDataLV的数据块的索引
        3. CacheMetaLV  应该是千分之一的CacheDataLV的大小，但最少为8MB。可用空间快是10GB，按照1000:1的分裂比例，10M的CacheMetaLV，大方点给100M， 9G多的CacheDataLV。
        [root@LVM-Host ~]# lvcreate -L +100M -n lv_cache_meta CacheTestVG /dev/sdb1
        Logical volume "lv_cache_meta" created.
        [root@LVM-Host ~]# lvcreate -L +9.5G -n lv_cache_data CacheTestVG /dev/sdb1
        Logical volume "lv_cache_data" created.

5. 把 CacheDataLV和CacheMetaLV 放到“缓存池”

        [root@LVM-Host ~]# lvconvert --type cache-pool --poolmetadata CacheTestVG/lv_cache_meta CacheTestVG/lv_cache_data

        CacheTestVG/lv_cache_meta? [y/n]: y
        Converted CacheTestVG/lv_cache_data_cdata to cache pool.

        [root@LVM-Host ~]# lvs
        LV            VG          Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
        Originlv      CacheTestVG -wi-a----- 15.00g
        lv_cache_data CacheTestVG Cwi---C---  9.50g   （注意Attr属性部分已经标识为C，标识Cache）
6. 对接缓存池和Originlv 慢设备物理卷

        [root@LVM-Host ~]# lvconvert --type cache --cachepool CacheTestVG/lv_cache_data CacheTestVG/Originlv

        Do you want wipe existing metadata of cache pool CacheTestVG/lv_cache_data? [y/n]: y
        Logical volume CacheTestVG/Originlv is now cached.

        [root@LVM-Host ~]# lvs
        LV       VG          Attr       LSize  Pool            Origin           Data%  Meta%  Move Log Cpy%Sync Convert
        Originlv CacheTestVG Cwi-a-C--- 15.00g [lv_cache_data] [Originlv_corig] 0.00   1.27            0.00

8. 格式化并挂载使用

        [root@LVM-Host ~]# mkfs.ext4 /dev/CacheTestVG/Originlv 
        [root@LVM-Host ~]# mount /dev/CacheTestVG/Originlv /test/
9. 现在写入的数据都是经过Cache写入的，相对来讲速度得到一定的提升，比SSD略差

## 总结
LVM的DM-cache原生的支持使得LVM层面的加速得到了可能，大大提高了系统的IO能力，实际上我们也可以使用FlashCache来进行加速，只是DM-cache让加速变得更加Easy.
一定注意SSD的磁盘寿命。


## 3. LVM Snapshot
### 3.1 LVM Snapshot介绍
* lvm的快照可以让我们轻松的“备份数据”或者“历史回溯”，由于源lvm和snapshot的关系，snapshot只能够临时使用，不能脱离源lvm而存在；
* 可以在snapshot的基础上进行某时间点的备份或其他操作，这样既不会影响原始数据也能够达到备份的需求。
* 如果在创建snapshot后意外地删除了文件，可以在快照里找到所删除的文件的原始文件。
* 不要改变快照卷，保持创建时的样子，因为它用于快速恢复。
* 快照不可替代生产中的“备份”工具。备份是某些数据的基础副本，因此我们不能使用快照作为备份的一个选择。

### 3.2 LVM snapshot原理
> LVM对LV提供的快照功能，只对LVM有效。
* snapshot创建时，仅仅是拷贝原始卷里数据的元数据(meta-data)，并不会有数据的物理拷贝。所以创建几乎是实时的。当原始卷上有写操作执行时，snapshot跟踪原始卷块的改变，这个时候原始卷上将要改变的数据在改变之前被拷贝到snapshot预留的空间里，因此这个原理的实现叫做写时复制(COW，copy-on-write)。
* 在写操作写入块之前，将原始数据移动到snapshot空间里去，这样就保证了所有的数据在snapshot创建时保持一致。而对于snapshot的读操作，如果是读取数据块是没有修改过的，那么会将读操作直接重定向到原始卷上，如果是要读取已经修改过的块，那么就读取拷贝到snapshot中的块。
* 创建snapshot的大小并不需要和原始卷一样大，其大小仅仅只需要考虑两个方面：从shapshot创建到释放这段时间内，估计块的改变量有多大;数据更新的频率。一旦snapshot的空间记录满了原始卷块变换的信息，那么这个snapshot立刻被释放，从而无法使用，从而导致这个snapshot无效。

### 创建快照
创建快照时，仅拷贝原始卷里数据的元数据(metadata)，并生成位图记录原始卷的块数据变化。
![](../images/lvm/6.png)

### 读写原始卷
在创建完快照后，对原始卷的读写请求处理流程如下。
1，写原始卷 在原始卷的写入数据 
1）	检查Chunk位图中要写入数据所在的Chunk所对应的bitmap是否被置位；
2）	 如果已被置位，直接写入该Chunk；如果未被置位，将拷贝该Chunk的数据到快照备份卷； 
3）	将Chunk位图中对应的bitmap置位。
4）	 将数据写入原始卷。 
![](../images/lvm/7.png)

读原始卷 
直接从原始卷对应的Chunk中读取数据。
![](../images/lvm/8.png)

### 读写快照 
1，读快照 
在处理快照的读请求时，检查Chunk位图是否置位，如果置位从快照读取数据；如果未置位，则从原始卷读取数据。如下图所示：
![](../images/lvm/9.png)

### 写快照 
在处理快照的写请求时， 
1） 检查Chunk位图是否置位，如果置位直接写快照； 
2） 如果未置位，则从原始卷读取该Chunk的数据，拷贝到快照卷；
3） 将Chunk位图中对应的位图置位； 
4） 将数据写入快照卷。
![](../images/lvm/10.png)

## 试验环境
	CentOS 7.2 + Vbox + 4Vdisk

### Lvm snapshot创建
>理论上，您所建立的快照卷的大小应该是原始卷的1.1倍大小 
1. vgs; # 看看卷组VG够不够空间创建快照;

        [root@bogon ~]# vgs
        VG     #PV #LV #SN Attr   VSize   VFree 
        centos   1   3   0 wz--n- 127.51g 64.00m
        vgtest   4   1   0 wz--n-  59.98g 49.98g
        目前卷组vgtest还有大概50G的空间，足以建立快照;
2. 创建快照

        [root@bogon ~]# lvcreate -L 12G -s -n lvtest-sanpshot vgtest/lvabc
        Reducing COW size 12.00 GiB down to maximum usable size 10.04 GiB.
        Logical volume "lvtest-sanpshot" created.
        参数：-s 为 snapshot的缩写
3. 查看快照lv

        [root@bogon ~]# lvs
        LV              VG     Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert                                                  
        lvabc           vgtest owi-aos--- 10.00g                                                    
        lvtest-sanpshot vgtest swi-a-s--- 10.04g      lvabc  0.00     

        [root@bogon ~]# dmsetup ls --tree
        vgtest-lvtest--sanpshot (253:6)
        ├─vgtest-lvtest--sanpshot-cow (253:5)
        │  └─ (8:33)
        └─vgtest-lvabc-real (253:4)
            ├─ (8:65)
            ├─ (8:49)
            ├─ (8:33)
            └─ (8:17)
        非常清晰的逻辑关系，vgtest-lvtest—snapshot 由vgtest-lvabc-real 和 vgtest-lvtest--sanpshot-cow 这2部分组成，并且明确表示了物理卷的硬件位置，COW的区域上面已经解释过了。 
4. 快照卷无需做格式化等步骤，可以直接对快照卷进行挂载，卸载等操作，而且操作完成之后，就应该立即删除快照，以减轻系统的I/O负担。 快照不会自动更新，长久保留是没有意义的。

        [root@bogon ~]# dd if=/dev/zero of=/test/2.img bs=10M count=100
        [root@bogon ~]# lvs
        LV              VG     Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert                                                 
        lvtest-sanpshot vgtest swi-a-s--- 10.04g      lvabc  9.08  
        快照控件已经使用了9.08%，当达到100%的时候，这个快照将会废弃无法再使用，一定要注意！

        [root@bogon ~]# lvdisplay 
        --- Logical volume ---
        LV Path                /dev/vgtest/lvtest-sanpshot
        LV Name                lvtest-sanpshot
        VG Name                vgtest
        LV UUID                w7T7XB-MBJV-YaCw-20SR-QH8T-mWsw-3fz65r
        LV Write Access        read/write
        LV Creation host, time bogon, 2016-08-31 17:29:09 +0800
        LV snapshot status     active destination for lvabc
        LV Status              available
        # open                 0
        LV Size                10.00 GiB
        Current LE             2560
        COW-table size         10.04 GiB
        COW-table LE           2571
        Allocated to snapshot  9.08%
        Snapshot chunk size    4.00 KiB
        Segments               1
        Allocation             inherit
        Read ahead sectors     auto
        - currently set to     8192
        Block device           253:6
   
5. 挂载查看快照空间内的数据

        [root@bogon ~]# ls /test/
        1.img  2.img  lost+found
        [root@bogon ~]# mkdir /snapshot 
        [root@bogon ~]# mount /dev/vgtest/lvtest-sanpshot /snapshot/
        挂载之后可以使用dump和tar进行备份
        [root@bogon ~]# ls /snapshot/
        1.img  lost+found
        可以看到快照内的数据并未更改，后续针对快照会出现2种情况，一是保留数据修改后的状态，二是回溯到快照时的状态。
6. 保留数据修改后状态，只需要删除快照即可

        [root@bogon ~]# lvremove /dev/vgtest/lvtest-snapshot

        保留现有状态，备份快照状态这个是备份数据库时候的常用手段，因为想要不停机备份数据库，就需要数据库的数据不会修改，所以快照出来以后进行备份，然后删除快照即可。
        而新增的数据依然可以正常的写入到数据库中。流程是先做一个flush操作，并锁定表，任何创建snapshot，任何解锁，然后备份数据，最后释放snapshot。这样，MySQL几乎不会中断其运行。
7. 回溯到快照状态，通常是在修改数据之前，做快照，当修改错误，可以利用快照回溯

        [root@bogon /]# umount /dev/vgtest/lvabc  (回溯先要卸载lv)
        [root@bogon /]# lvconvert --merge /dev/vgtest/lvsnapshot

>千万注意！！！！

        [root@bogon /]# lvs
        LV     VG  Attr    LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert                                              
        lvsnapshot vgtest swi-a-s--- 10.04g      lvabc  20.00             
        已经使用20%的snapshot空间，如果超过100%将无法使用                     
        [root@bogon /]# lvs （如下状态）
        LV      VG   Attr     LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert                                           
        lvsnapshot vgtest swi-I-s---  1.00g      lvabc  100.00 
        [root@bogon /]# lvdisplay 
        --- Logical volume ---
        LV Path                /dev/vgtest/lvsnapshot
        LV Name                lvsnapshot
        VG Name                vgtest
        ……
        LV snapshot status     INACTIVE destination for lvabc
        …….
        如果数据超过LV snapshot空间大小，将会失效，镜像卷将会无法使用。
        [root@bogon /]# mount /dev/vgtest/lvsnapshot /snapshot/
        mount: /dev/mapper/vgtest-lvsnapshot: can't read superblock

## 总结
	产环境中，快照通常是用于数据某一时间点的备份，用完之后删除快照即可，至于回溯很少使用。
