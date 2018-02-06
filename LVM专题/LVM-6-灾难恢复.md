# LVM-灾难恢复

## 1. 灾难的划分
对于文件系统灾难常规来讲一般可分为两类：
1. 人为灾难，主要是人为操作导致的分区损坏，数据丢失等等。
2. 自然灾难，主要是由于意外事件或者自然损耗导致，例如，磁盘坏道，非法断电导致磁盘损坏，其它硬件损坏，插拔磁盘导致位置调整等等。

LV卷的文件系统和普通的分区文件系统环境并没有什么区别，所以所面对的灾难也是一样的。由于LVM是在硬分区和文件系统之间的一个逻辑层，所以通过LVM逻辑卷管理带来分区容量动态调整便利的同时，也带来了一些LVM特有的灾难。LVM 将所有磁盘创建为物理卷包含与统一的卷组中进行管理，然后创建逻辑卷供操作系统调用，这也就可能出现卷组损坏，逻辑卷损坏，物理卷损坏等情况的发生。

## 2. 如何预防
针对企业而言，通常会指定严格的操作流程和规章制度，以及完备的备份策略来预防此类时间的发生，规模大的企业也会采用二地三中心的架构来抵抗自然灾难。
对于个人用户而言，需要提高备份意识，尽可能的勤备份。建议备份2份数据，一份在移动硬盘，一份在独立的NAS。
但是单就 LVM 而言，有一些灾难是可以修复和抢救的，因为LVM自身提供了较为完备的数据备份和配置信息备份还原的工具，充分利用这些工具，在发生灾难导致物理卷顺坏，逻辑卷错误和卷组错误时，利用备份恢复的特性，尽可能的减少丢失数据损失。

## 3. LVM 逻辑卷故障-灾难恢复实例

逻辑损坏的原因往往是多种多样的，例如认为的误操作，机房或者主机的不正常掉电，或者是病毒造成。然而这些损坏并非是不可逆的（大多数可修复），为了宝贵的数据无论如何也要尝试一下。

### 3.1 试验环境
|系统版本|磁盘数量|ip地址|主机名称|虚拟化|
|:---|:---|:---|:---|:---|
|CentOS 7.4|4Vdisk|192.168.56.101|LVM-Host|Vbox|

### 3.2 测试内容和环境说明
1. 模拟逻辑卷故障进行灾难恢复。
2. PV的损坏和修复。

### 3.3 逻辑卷（标签丢失）
>Device for PV qtE2Lf-Uj1W-HoWf-lMsy-5CFK-lhpa-Nw1JEq not found or rejected by a filter.
1. 测试环境的磁盘及文件系统状况

        [root@lvm-host ~]# pvs
        PV         VG     Fmt  Attr PSize    PFree
        /dev/sdb1  Book   lvm2 a--   <10.00g <10.00g
        /dev/sdc1  Book   lvm2 a--   <20.00g <10.00g
        [root@lvm-host ~]# vgs
        VG     #PV #LV #SN Attr   VSize    VFree
        Book     2   1   0 wz--n-   29.99g 19.99g
        [root@lvm-host ~]# lvs
        LV     VG     Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
        testlv Book   -wi-ao---- 10.00g
2. 模拟删除LVM2标签，pv查看报错（仅清除lvm lable）

        [root@lvm-host ~]# dd if=/dev/zero of=/dev/sdb1 bs=512 count=1 seek=1
        [root@lvm-host ~]# pvs --partial
        PARTIAL MODE. Incomplete logical volumes will be processed.
        WARNING: Device for PV qtE2Lf-Uj1W-HoWf-lMsy-5CFK-lhpa-Nw1JEq not found or rejected by a filter.
        PV         VG     Fmt  Attr PSize    PFree
        /dev/sdc1  Book   lvm2 a--   <20.00g <10.00g
        [unknown]  Book   lvm2 a-m   <10.00g <10.00g
        由此看出pvs的时候已经出现unknown设备。

3. 查看逻辑卷信息，并尝试备份数据

        [root@lvm-host ~]# lvs
        WARNING: Device for PV qtE2Lf-Uj1W-HoWf-lMsy-5CFK-lhpa-Nw1JEq not found or rejected by a filter.
        LV     VG     Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
        testlv Book   -wi-ao---- 10.00g
        lvs查看的时候，逻辑卷还存在，尝试是否可以挂载抢救数据。

        [root@lvm-host ~]# mount -o ro -o remount  /dev/Book/testlv /test
        使用tar或者其他备份手段进行备份。

4. 尝试进行恢复 （原磁盘修复）

        进行pv修复
        [root@lvm-host test]# pvcreate -ff --uuid qtE2Lf-Uj1W-HoWf-lMsy-5CFK-lhpa-Nw1JEq --restorefile /etc/lvm/backup/Book /dev/sdb1
        Couldn't find device with uuid qtE2Lf-Uj1W-HoWf-lMsy-5CFK-lhpa-Nw1JEq.
        WARNING: Device for PV qtE2Lf-Uj1W-HoWf-lMsy-5CFK-lhpa-Nw1JEq not found or rejected by a filter.
        Physical volume "/dev/sdb1" successfully created.
        
        [root@lvm-host test]# pvs
        PV         VG     Fmt  Attr PSize    PFree
        /dev/sda2  centos lvm2 a--  <127.00g   4.00m
        /dev/sdb1  Book   lvm2 a--   <10.00g <10.00g
        /dev/sdc1  Book   lvm2 a--   <20.00g <10.00g
        PV修复后可以成功查看。

        恢复成功，对卷组进行恢复
        [root@lvm-host test]# vgcfgrestore -f /etc/lvm/backup/Book Book
        Restored volume group Book
        [root@lvm-host test]# vgchange -ay Book
        1 logical volume(s) in volume group "Book" now active

        [root@lvm-host test]# mount -o remount  /dev/Book/testlv /test
        .......
        [root@lvm-host test]# touch 123file
        可以查看到以前的数据，并且写入新数据成功。

5. 尝试进行恢复 （替换磁盘修复）

        [root@lvm-host /]# pvcreate /dev/sde1
        [root@lvm-host test]# pvcreate -ff --uuid qtE2Lf-Uj1W-HoWf-lMsy-5CFK-lhpa-Nw1JEq --restorefile /etc/lvm/backup/Book /dev/sde1
        使用sde1替换sdb1，然后还原vg信息....

>重要：

    默认情况下是在 /etc/lvm/backup 文件中保存元数据备份，在 /etc/lvm/archive 文件中保存元数据归档。可使用 vgcfgbackup 命令手动将元数据备份到 /etc/lvm/backup 文件中。vgcfrestore 命令使用归档在所有物理卷中恢复卷组元数据。 
    建议备份/etc/lvm 目录，并且保存在其他归档主机，如果lvm有改动，及时更新备份。
    备份命令可以使用：vgcfgbackup 也可以使用 lvmdump，推荐使用lvmdump。


