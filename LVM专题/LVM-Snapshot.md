# LVM  Snapshot

## LVM-进阶-Snapshot
我们最常用的就是基于卷管理的快照—LVM snapshot。要提醒一点是，以下内容是针对安装了LVM的系统。写时复制在文件系统和磁盘I/O之间增加了一层COW层。变成了下面这个样子：
file I/0 —&gt; filesystem — &gt;COW –&gt; block I /O
采取COW实现方式时，snapshot的大小并不需要和原始卷一样大，其大小仅仅只需要考虑两个方面：从shapshot创建到释放这段时间内，估计块的改变量有多大;数据更新的频率。一旦 snapshot的空间记录满了原始卷块变换的信息，那么这个snapshot立刻被释放，就无法使用，从而导致这个snapshot无效。所以，一定要在snapshot的生命周期里，做完你需要做得事情。

通过使用lvm的快照我们可以轻松的备份数据，由于snapshot和源lvm的关系，snapshot只能够临时使用，不能脱离源lvm而存在；因此做到数据的万无一失，我们可以在snapshot的基础上进行某时间点的备份或其他备份操作，这样既不会影响原始数据也能够达到备份的需求。

如果我们在创建快照后意外地删除了无论什么文件，我们没有必要担心，因为快照里包含了我们所删除的文件的原始文件。创建快照时，很有可能文件已经存在了。不要改变快照卷，保持创建时的样子，因为它用于快速恢复。
快照不可以用于备份选项。备份是某些数据的基础副本，因此我们不能使用快照作为备份的一个选择

## LVM snapshot原理
> LVM对LV提供的快照功能，只对LVM有效。
* 当一个snapshot创建的时候，仅拷贝原始卷里数据的元数据(meta-data)。创建的时候，并不会有数据的物理拷贝，因此snapshot的创建几乎是实时的，当原始卷上有写操作执行时，snapshot跟踪原始卷块的改变，这个时候原始卷上将要改变的数据在改变之前被拷贝到snapshot预留的空间里，因此这个原理的实现叫做写时复制(copy-on-write)。
* 在写操作写入块之前，将原始数据移动到?snapshot空间里，这样就保证了所有的数据在snapshot创建时保持一致。而对于snapshot的读操作，如果是读取数据块是没有修改过的，那么会将读操作直接重定向到原始卷上，如果是要读取已经修改过的块，那么就读取拷贝到snapshot中的块。
* 创建snapshot的大小并不需要和原始卷一样大，其大小仅仅只需要考虑两个方面：从shapshot创建到释放这段时间内，估计块的改变量有多大;数据更新的频率。一旦snapshot的空间记录满了原始卷块变换的信息，那么这个snapshot立刻被释放，从而无法使用，从而导致这个snapshot无效。

### 创建快照
在快照创建的时候，仅拷贝原始卷里数据的元数据(meta-data)，并生成位图记录原始卷的块数据变化。
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
