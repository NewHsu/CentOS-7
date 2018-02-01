# LVM进阶篇-高速缓存
* 现在的服务器大多数搭配SSD的磁盘，而SSD的磁盘也是总所周知的要比普通磁盘快很多，所以通常将SSD作为安装系统的磁盘来使用，然后数据还是要写入物理磁盘，外围系统和数据的响应依然要等待慢如牛的物理磁盘做出回复。瓶颈所在的原因是“系统加速不等于应用的数据读取和写入加速”，除非你将应用也放到ssd磁盘上来运行，但是ssd的设备还是相当昂贵的，所以必须找到一种折中的方案来利用ssd磁盘，达到整体加速的效果。
* 现在的lvm已经支持使用缓存来提升读写速度，所以我们何不将ssd磁盘作为lvm的缓存来使用呢？这样就可以对整个lvm加速，换句话说，可以对整个系统lv和数据lv进行加速，这样的利用要远比单纯的给系统使用更有价值！

* Cache & SSD
    1. 在计算机系统中，cache几乎无处不在，CPU、LINUX、MYSQL、IO等系统中均能见到cache的身影。Cache是容量与性能之间取平衡的结果，以更低的成本，获得更高的收益。
    2. 在计算机硬件发展的几十年来，传统的机械硬盘逐步成为整个系统的瓶颈，性能增长十分缓慢。对于依赖IO性能的应用Flashdisk(SSD/FusionIO等)的出现，改变了这一切。
    3. Flash disk将硬盘从机械产品变成了电气产品，功耗更小，性能更好，时延更优。但新的技术还存在一些问题，价格以及稳定性

##  LVM SSD缓存

* 这里是有的选择的，要么使用默认的DM-cache，要可以使用FlashCache等等，由于CentOS自身是支持LVM使用DM-cache，所以就用CentOS自带的来配置缓存的SSD设备；当然FlashCache也是很好的选择。
### LVM 缓存实例（DM-cache）
dm-cache 的原理是使用 device mapper 核心，并在上面增加一个策略层。这个策略层“非常类似”一个插件接口，可以实现不同的策略。这些策略（以及缓存的内容）决定了缓存是否可以命中，是否需要进行数据迁移（在原始设备与缓存设备之间进行某个方向的数据移动）。目前已经实现了包括最近最少用（LRU）、最常使用（MFU）等策略，但目前只有缺省的“mq”策略合并到内核中了，以便减少起初需要测试到的策略数量。文件系统可以为策略提供 hints，比如某些块脏了，或是某些块已经被放弃了。这些信息有助于策略更好地决定块要存储到的位置。-


### 试验环境
		CentOS 7.2 + Vbox + 4Vdisk
### Lvm SSD缓存创建（DM-cache）
1. 确认设备

        [root@bogon /]# lsblk 
        NAME            MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
        sdc               8:32   0    20G  0 disk 
        └─sdc1            8:33   0    20G  0 part 
        sdd               8:48   0    10G  0 disk 
        └─sdd1            8:49   0    10G  0 part 
        sde               8:64   0    20G  0 disk 
        └─sde1            8:65   0    20G  0 part
        上例中，sdc和sde为普通物理磁盘20G，sdd为SSD磁盘10G
2. 理解Lvm cache的相关术语

        lvmcache(7) ：
        origin LV           OriginLV      large slow LV
        cache data LV       CacheDataLV   small fast LV for cache pool data
        cache metadata LV   CacheMetaLV   small fast LV for cache pool metadata
        cache pool LV       CachePoolLV   CacheDataLV + CacheMetaLV
        cache LV            CacheLV       OriginLV + CachePoolLV
        -1：真实的LV卷，很大的慢速设备LV
        -2：cache 数据卷  可以很小，但是必须很快，用来缓存数据
        -3：Cache 元数据卷 可以很小，但是必须很快，用来缓存元数据
        -4：Cache Pool LV ：缓存池，包含 data+meta
        -5： Cache LV ：    缓存卷，包含 真实的LV卷+缓存池
        实际的创建顺序也就是 1到5的步骤。
3. 创建VG和LVs（慢速设备的VG卷组合LV卷）

        [root@bogon ~]# vgcreate CacheTestVG /dev/sd{c,e}1
        Volume group "CacheTestVG" successfully created
        [root@bogon ~]# lvcreate -L +30G -n Originlv CacheTestVG
        Logical volume "Originlv" created.
4. SSD设备加入慢速VG卷组

        所有的必须在一个卷组中，实际上就是一个VG卷组既包含慢速设备同时也要包含快速设备，所以必须将SSD设备加入到先前创建的卷组中
        [root@bogon ~]# vgextend CacheTestVG /dev/sdd1
        Volume group "CacheTestVG" successfully extended
5. 创建SSD的LV缓存

        我创建了快速的SSD两个LVs 。一个是CacheDataLV ，这就是缓存发生。另一个是用于存储被高速缓存在CacheDataLV的数据块的索引的CacheMetaLV 。该文件说， CacheMetaLV应该是千分之一的CacheDataLV的大小，但最少为8MB 。由于我的总可用空间快是232GB ，而我希望有一个1000:1的分裂，我大方的选择一个1GB的CacheMetaLV ， 229G的CacheDataLV ，而且会留下一些遗留下来的空间（我最终的分割结果是229:1 ） 。
        [root@bogon ~]# lvcreate -L +2G -n lv_cache_meta CacheTestVG /dev/sdd1
        Logical volume "lv_cache_meta" created.
        [root@bogon ~]# lvcreate -L +6G -n lv_cache_data CacheTestVG /dev/sdd1
        Logical volume "lv_cache_data" created.
        [root@bogon ~]# lvs
        LV            VG          Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
        Originlv      CacheTestVG -wi-a----- 30.00g                                                    
        lv_cache_data CacheTestVG -wi-a-----  6.00g                                                    
        lv_cache_meta CacheTestVG -wi-a-----  2.00g                                                                                                   
        [root@bogon ~]# pvs
        PV         VG          Fmt  Attr PSize   PFree 
        /dev/sdc1  CacheTestVG lvm2 a--   20.00g     0 
        /dev/sdd1  CacheTestVG lvm2 a--   10.00g  2.00g
        /dev/sde1  CacheTestVG lvm2 a--   20.00g  9.99g
6. 把 CacheDataLV和CacheMetaLV 放到“缓存池”

        [root@bogon ~]# lvconvert --type cache-pool --poolmetadata CacheTestVG/lv_cache_meta CacheTestVG/lv_cache_data
        WARNING: Converting logical volume CacheTestVG/lv_cache_data and CacheTestVG/lv_cache_meta to pool's data and metadata volumes.
        THIS WILL DESTROY CONTENT OF LOGICAL VOLUME (filesystem etc.)
        Do you really want to convert CacheTestVG/lv_cache_data and CacheTestVG/lv_cache_meta? [y/n]: y
        Converted CacheTestVG/lv_cache_data to cache pool.
        [root@bogon ~]# lvs
        LV            VG          Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
        Originlv      CacheTestVG -wi-a----- 30.00g                                                    
        lv_cache_data CacheTestVG Cwi---C---  6.00g     #注意Attr属性部分已经标识为C
7. 对接缓存池和Originlv 慢设备物理卷

        [root@bogon ~]# lvconvert --type cache --cachepool CacheTestVG/lv_cache_data CacheTestVG/Originlv
        Logical volume CacheTestVG/Originlv is now cached.
        [root@bogon ~]# lvs
        LV       VG          Attr       LSize  Pool            Origin           Data%  Meta%  Move Log Cpy%Sync Convert
        Originlv CacheTestVG Cwi-a-C--- 30.00g [lv_cache_data] [Originlv_corig] 0.00   0.04            100.00        
8. 格式化并挂载使用

        [root@bogon ~]# mkfs.ext4 /dev/CacheTestVG/Originlv 
        [root@bogon ~]# mount /dev/CacheTestVG/Originlv /test/
9. 现在写入的数据都是经过Cache写入的，相对来讲速度得到一定的提升，比SSD略差
10. 一定要注意认真读取“LVM磁盘更换章节”！！因为SSD的写入是有寿命的。


## 总结
	LVM的DM-cache原生的支持使得LVM层面的加速得到了可能，大大提高了系统的IO能力，实际上我们也可以使用FlashCache来进行加速，只是DM-cache让加速变得更加Easy.
