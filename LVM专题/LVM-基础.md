# LVM 逻辑卷1
## LVM介绍
* 每台服务器空间都会因为我们的需求增长而不断扩展，传统分区使用固定大小分区，重新调整大小十分麻烦。逻辑卷管理（LVM）是一个非常实用的硬盘系统工具。在Linux系统和其它系统都有着广泛的用途。但是，LVM可以创建和管理“逻辑”卷，而不是直接使用物理硬盘。可以弹性的管理卷的扩大或者缩小，十分简单，而不损坏已存储的数据。可以随意将新的硬盘添加到LVM，并扩展到已经存在的逻辑卷。LVM甚至不需要重新启动系统就可以让内核知道卷的存在。
* 逻辑卷可以用于RAID，SAN。单个物理卷将会被加入逻辑卷组中，在卷组中切割空间并创建逻辑卷。在使用逻辑卷时，可以使用某些命令来跨磁盘、跨逻辑卷扩展，或者减少逻辑卷大小，而不用重新格式化和重新对当前磁盘分区。卷可以跨磁盘抽取数据，这会增加I/O数据量。

![](../images/lvm/1.png)

逻辑卷管理器（LVM）让磁盘空间管理更为便捷。如果一个文件系统需要更多的空间，可以在它的卷组中将空闲空间添加到其逻辑卷中，而文件系统可以根据你的意愿调整大小。如果某个磁盘启动失败，用于替换的磁盘可以使用卷组注册成一个物理卷，而逻辑卷扩展可以将数据迁移到新磁盘而不会丢失数据。

## LVM特性
    1. 可以在任何时候灵活地扩展空间。
    2. 可以安装和处理任何文件系统。
    3. 可以通过迁移来恢复错误磁盘。
    4. 可以使用快照功能恢复文件系统到先前的阶段。等等……

## LVM基本术语
* 前面谈到，LVM是在磁盘分区和文件系统之间添加的一个逻辑层，来为文件系统屏蔽下层磁盘分区布局，提供一个抽象的盘卷，在盘卷上建立文件系统。首先我们讨论以下几个LVM术语：

1. 物理存储介质（The physical media）
    
        这里指系统的存储设备：硬盘，如：/dev/hda、/dev/sda等等，是存储系统最低层的存储单元。

2. 物理卷（physicalvolume）

        物理卷就是指硬盘分区或从逻辑上与磁盘分区具有同样功能的设备(如RAID)，是LVM的基本存储逻辑块，但和基本的物理存储介质（如分区、磁盘等）比较，却包含有与LVM相关的管理参数。

3. 卷组（Volume Group）

        LVM卷组类似于非LVM系统中的物理硬盘，其由物理卷组成。可以在卷组上创建一个或多个“LVM分区”（逻辑卷），LVM卷组由一个或多个物理卷组成。

4. 逻辑卷（logicalvolume）

        LVM的逻辑卷类似于非LVM系统中的硬盘分区，在逻辑卷之上可以建立文件系统(比如/home或者/usr等)。

5. PE（physical extent）

        每一个物理卷被划分为称为PE(Physical Extents)的基本单元，具有唯一编号的PE是可以被LVM寻址的最小单元。PE的大小是可配置的，默认为4MB。

6. LE（logical extent）
        逻辑卷也被划分为被称为LE(Logical Extents) 的可被寻址的基本单位。在同一个卷组中，LE的大小和PE是相同的，并且一一对应。

## LVM原理

![](../images/lvm/2.png)

从图中可以看出，最底层依然是物理磁盘设备，然后通过PV化将底层的屋里磁盘和分区整合到一个VG当中，在逻辑上形成一个较大的存储资源池，在vg中通过lv的形式进行输出。

物理卷（PV）被由大小等同的基本单元PE组成

![](../images/lvm/3.jpg)

一个卷组由一个或多个物理卷组成

![](../images/lvm/4.jpg)

从上图可以看到，PE和LE有着一一对应的关系。逻辑卷建立在卷组上。逻辑卷就相当于非LVM系统的磁盘分区，可以在其上创建文件系统。


## LVM 管理和使用

### 卷管理常用命令集合：

|名称|创建|激活|扩容|查找|查看|删除|
|:--|:--|:--|:--|:--|:--|:--|
|PV|pvcreate|pvchange|  |pvscan|pvdisplay|pvremove|
|VG|vgcreate|vgchange|vgextend|vgscan|vgdisplay|vgremove|
|LV|lvcreate|lvchange|lvextend|lvscan|lvdisplay|lvremove|

![](../images/lvm/5.png)

## LVM 创建
* LVM创建顺序是从下至上的，首先要PV化磁盘，然后形成VG的池，最后在VG的池中划分出lv进行输出,根据以上的顺序我们进行如下操作：
1. 首先找到可以pv化的存储设备

        [root@bogon ~]# lsblk -a
        NAME            MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
        sda               8:0    0   128G  0 disk 
        ├─sda1            8:1    0   500M  0 part /boot
        └─sda2            8:2    0 127.5G  0 part 
        ├─centos-root 253:0    0    50G  0 lvm  /
        ├─centos-swap 253:1    0     2G  0 lvm  [SWAP]
        └─centos-home 253:2    0  75.5G  0 lvm  /home
        sdb               8:16   0    10G  0 disk 
        sdc               8:32   0    20G  0 disk 
        sdd               8:48   0    10G  0 disk 
        sde               8:64   0    20G  0 disk 
        sr0              11:0    1  56.5M  0 rom  
        可以看出，当前的sda已经进行了pv化，并且已经输进行了lv输出，而sdb、sdc、sdd、sde没有进行任何划分，所以这里我们使用sdb和sdc来初始化pv。
2. 如果想要初始化pv，最好先对磁盘进行分区并选择“8e”的分区code来使用分区的lvm格式（建议）。利用fdisk划分出sdb1和sdc1，共计约29~30G大小。

        再次查看存储信息如下：
        [root@bogon ~]# lsblk -a
        NAME            MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
        ……
        sdb               8:16   0    10G  0 disk 
        └─sdb1            8:17   0    10G  0 part 
        sdc               8:32   0    20G  0 disk 
        └─sdc1            8:33   0    20G  0 part 
        ……

        然后进行pv化操作：
        [root@bogon ~]# pvcreate /dev/sd{b,c}1
        Physical volume "/dev/sdb1" successfully created
        Physical volume "/dev/sdc1" successfully created
        查看结果如下：
        [root@bogon ~]# pvs
        PV         VG     Fmt  Attr PSize   PFree 
        /dev/sda2  centos  lvm2 a--  127.51g 64.00m
        /dev/sdb1         lvm2 ---   10.00g 10.00g
        /dev/sdc1         lvm2 ---   20.00g 20.00g
        可以看到磁盘名称，所属卷组（但是sdb1和sdc1没有加入vg卷组，所以此处为空），lvm版本格式，属性，pv化以后的大小，以及free的空间大小。
3. 创建vg卷组，并将sdb1和sdc1加入卷组

        [root@bogon ~]# vgcreate Book /dev/sdb1
        Volume group "Book" successfully created
        [root@bogon ~]# vgextend Book /dev/sdc1
        Volume group "Book" successfully extended
        创建Book卷组将sdb1加入，然后将sdc1添加进Book卷组。

        查看结果如下：（vg大小29.99g）
        [root@bogon ~]# vgs
        VG     #PV #LV #SN Attr   VSize   VFree 
        Book     2   0   0 wz--n-  29.99g 29.99g
        centos   1   3   0 wz--n- 127.51g 64.00m
4. 划分20g大小的lv来使用

        [root@bogon ~]# lvcreate -n lvtest -L +20G Book
        Logical volume "lvtest" created.
        查看结果如下：（20g lv使用空间，名称为lvtest）
        [root@bogon ~]# lvs 
        LV    VG   Attr   LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
        lvtest Book   -wi-a----- 20.00g   
        [root@bogon ~]# vgs （vg的free空间相对减少20g）
        VG     #PV #LV #SN Attr   VSize   VFree 
        Book     2   1   0 wz--n-  29.99g  9.99g

5. lv划分出来以后，还不能即刻使用，需要在lv逻辑卷上make文件系统，然后在挂载。

        [root@bogon ~]# mkfs.ext4 /dev/Book/lvtest 
        [root@bogon ~]# mkdir /test
        [root@bogon ~]# mount /dev/Book/lvtest /test
        [root@bogon test]# mount
        ……
        /dev/mapper/Book-lvtest on /test type ext4 (rw,relatime,seclabel,data=ordered)
        [root@bogon ~]# cd /test
        [root@bogon test]# touch filetest
        [root@bogon test]# ls
        filetest  lost+found
        如果需要自动挂载，别忘记写到/etc/fstab中哦~

### Lvm扩容
* 在生产环境中，我们经常会出现磁盘空间不足的情况，针对这样的情况如果是普通的磁盘分区，将没有办法进行扩容，唯一的办法就是数据搬家，然后换更大的存储空间。但是如果是lv的情况，我们可以在线扩展lv的空间，来满足生产系统更大的存储需求。

1. lv扩容为2种情况，vg内有free空间可以扩容和vg中没有free的空间可以扩容

2. vg中有空间可以扩容，可以按如下操作进行

        [root@bogon test]# vgs（剩余9.99g）
        VG     #PV #LV #SN Attr   VSize   VFree 
        Book     2   1   0 wz--n-  29.99g  9.99g
        [root@bogon test]# lvextend /dev/Book/lvtest -L +9G 
        Size of logical volume Book/lvtest changed from 20.00 GiB (5120 extents) to 29.00 GiB (7424 extents).
        Logical volume lvtest successfully resized.
        [root@bogon test]# vgs 
        VG     #PV #LV #SN Attr   VSize   VFree   
        Book     2   1   0 wz--n-  29.99g 1016.00m
        [root@bogon test]# resize2fs /dev/Book/lvtest 
        [root@bogon test]# lvs
        lvtest Book   -wi-ao---- 29.00g  
        [root@bogon test]# df -h（实际大小在重新计算完扩展空间后会生效）
        /dev/mapper/Book-lvtest   29G   44M   27G   1% /test
3. 如果vg卷组中不足所需要的扩展控件，需要先对卷组进行扩容，然后在对lv进行扩充

        [root@bogon test]# pvcreate /dev/sdd1
        Physical volume "/dev/sdd1" successfully created
        [root@bogon test]# vgextend Book /dev/sdd1
        Volume group "Book" successfully extended
        [root@bogon test]# pvs
        PV         VG     Fmt  Attr PSize   PFree   
        /dev/sdd1  Book   lvm2 a--   10.00g   10.00g
        [root@bogon test]# vgs  （查看到vg卷组中已经扩充了10g可用控件）
        VG     #PV #LV #SN Attr   VSize   VFree 
        Book     3   1   0 wz--n-  39.99g 10.99g
        然后可以重复步骤2进行lv扩充

## Lvm缩减
* Lv缩减这是个有风险的动作，而且在生产环境中也很少使用缩减的动作，简单说一下缩减的步骤和操作：
1. 先确认当前磁盘使用的空间大小，免得缩减太多导致文件系统崩溃。

        [root@bogon ~]# df -h （使用2.1G，可用25G，也就是说我们缩减必须在25G之内）
        Filesystem               Size  Used Avail Use% Mounted on
        /dev/mapper/Book-lvtest   29G  2.1G   25G   8% /test
        [root@bogon ~]# md5sum /test/1.img (为了验证缩减后文件可用，先做了一下md5校验)
        ffe3915bd77fde9dd5dc8077ced09c10  /test/1.img
2. 缩减的动作必须要先将lvm逻辑卷卸载之后才能进行

        [root@bogon ~]# umount /dev/Book/lvtest
3. 检查文件系统错误

        [root@bogon ~]# e2fsck -ff /dev/Book/lvtest 
        e2fsck 1.42.9 (28-Dec-2013)
        Pass 1: Checking inodes, blocks, and sizes
        Pass 2: Checking directory structure
        Pass 3: Checking directory connectivity
        Pass 4: Checking reference counts
        Pass 5: Checking group summary information
        /dev/Book/lvtest: 13/1900544 files (0.0% non-contiguous), 687619/7602176 blocks	
        注意：必须通过所有文件系统检查的5个步骤，若未完全通过，则你的文件系统可能存在问题。
4. 从新计算文件系统各大小空间 （保留10G）

        [root@bogon ~]# resize2fs /dev/Book/lvtest 10G
        resize2fs 1.42.9 (28-Dec-2013)
        Resizing the filesystem on /dev/Book/lvtest to 2621440 (4k) blocks.
        The filesystem on /dev/Book/lvtest is now 2621440 blocks long.

5. 缩减文件系统（缩减18G）

        [root@bogon ~]# lvreduce -L -18G /dev/Book/lvtest 
        WARNING: Reducing active logical volume to 11.00 GiB
        THIS MAY DESTROY YOUR DATA (filesystem etc.)
        Do you really want to reduce lvtest? [y/n]: y
        Size of logical volume Book/lvtest changed from 29.00 GiB (7424 extents) to 11.00 GiB (2816 extents).
        Logical volume lvtest successfully resized.
        [root@bogon ~]# mount /dev/Book/lvtest /test/
        [root@bogon ~]# ls /test/
        1.img  lost+found
        [root@bogon ~]# md5sum /test/1.img 
        ffe3915bd77fde9dd5dc8077ced09c10  /test/1.img
        [root@bogon ~]# df -h
        Filesystem               Size  Used Avail Use% Mounted on
        /dev/mapper/Book-lvtest  9.8G  2.1G  7.3G  23% /test
        上述是缩减成功的情况，如果缩减过量，那么就完蛋了，如果还是非常重要的数据，那么你就惹大麻烦了，所以，缩减需谨慎！

## LVM 删除 （ 待补全） 


## 总结
	以上的这个lvm仅仅是基础的操作，在下一篇中我们将进行lvm的一些故障排除和高级功能使用，最后在学习如何对lvm进行调优。
