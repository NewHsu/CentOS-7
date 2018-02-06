# LVM-问题处理

## 1. LVM-数据迁移
### 1.1 为什么迁移数据
LVM数据迁移是LVM基础功能，在不用关机的情况下可以迁移逻辑卷到一个新的磁盘而不会丢失数据。该功能是将数据从旧磁盘移动到新磁盘。通常只是在一些磁盘发生错误时，才将数据从一个磁盘迁移到另外一个磁盘存储。

### 2. LVM迁移数据实例

#### 2.1 试验环境
|系统版本|磁盘数量|ip地址|主机名称|虚拟化|
|:---|:---|:---|:---|:---|
|CentOS 7.4|4Vdisk|192.168.56.101|LVM-Host|Vbox|

#### 2.2 测试内容和环境说明
1. 在不关机，不损伤数据的情况下在线更换磁盘，使用sdd1替换sdb1和sdc1。

#### 2.3 迁移数据实例
1. 确认当前设备信息.

        [root@lvm-host ~]# dd if=/dev/cdrom of=/test/cdrom-1.img
        [root@lvm-host ~]# dd if=/dev/cdrom of=/test/cdrom-2.img
        用光盘做的模拟数据。
        [root@lvm-host ~]# df -Th | grep test
        /dev/mapper/Book-testlv ext4       20G   17G  2.5G  87% /test

        [root@lvm-host ~]# lvdisplay -m /dev/Book/testlv
        --- Logical volume ---
        LV Path                /dev/Book/testlv
        LV Name                testlv
        VG Name                Book
        ......
        --- Segments ---
        Logical extents 0 to 2558:
            Type                linear
            Physical volume     /dev/sdb1
            Physical extents    0 to 2558
        Logical extents 2559 to 5119:
            Type                linear
            Physical volume     /dev/sdc1
            Physical extents    0 to 2560
        testlv这个逻辑卷大小20G，由2块磁盘支撑（sdb1和sdc1）。
2. 确认lv内的数据md5，用于迁移后验证。  

        [root@lvm-host ~]# cd /test/
        [root@lvm-host test]# ls
        cdrom-1.iso  cdrom-2.iso  lost+found
        [root@lvm-host test]# md5sum cdrom-1.iso
        d23eab94eaa22e3bd34ac13caf923801  cdrom-1.iso
        [root@lvm-host test]# md5sum cdrom-2.iso
        d23eab94eaa22e3bd34ac13caf923801  cdrom-2.iso
        md5是一样的，因为是相通光盘dd出来的。这么做只是为了让数据分布到2个磁盘上。
    
3. 添加新的磁盘到VG卷组

        [root@lvm-host test]# pvcreate /dev/sdd1
        [root@lvm-host test]# vgextend Book /dev/sdd1
        [root@lvm-host test]# vgs
        VG     #PV #LV #SN Attr   VSize    VFree
        Book     3   1   0 wz--n-  <59.99g <39.99g
        vg的pv数量已经由2变更为3.
4. 查看当前testlv的分布情况

        [root@lvm-host test]# lvs -o+devices
        LV     VG     Attr       LSize        ......           Devices
        testlv Book   -wi-ao---- 20.00g                      /dev/sdb1(0)
        testlv Book   -wi-ao---- 20.00g                      /dev/sdc1(0)

5. LVM镜像替换法，使用‘lvconvert’命令来将数据从旧逻辑卷迁移到新驱动器

        [root@lvm-host test]# lvconvert -m 1 /dev/Book/testlv /dev/sdd1
        Are you sure you want to convert linear LV Book/testlv to raid1 with 2 images enhancing resilience? [y/n]: y
        Logical volume Book/testlv successfully converted.
6. 查看镜像比例(当前完成16.08%，百分之百即完成)

        [root@lvm-host test]# lvs -o+devices
        LV     VG     Attr       LSize  ...... Cpy%Sync Convert Devices
        testlv Book   rwi-aor--- 20.00g ......  16.08   testlv_rimage_0(0),testlv_rimage_1(0)

8. 100%镜像后，移除镜像卷(sdd1 磁盘空间必须足够大)

        [root@lvm-host test]# lvconvert -m 0 /dev/Book/testlv /dev/sdb1
        Are you sure you want to convert raid1 LV Book/testlv to type linear losing all resilience? [y/n]: y
        Logical volume Book/testlv successfully converted.

        [root@lvm-host test]# lvs -o+devices
        LV     VG     Attr       LSize  .......        Devices
        testlv Book   -wi-ao---- 20.00g                /dev/sdd1(1)

9. 进行验证

        [root@lvm-host /]# umount /test/
        [root@lvm-host /]# mount /dev/Book/testlv /test/
        [root@lvm-host /]# cd /test
        [root@lvm-host test]# md5sum cdrom-1.iso
        d23eab94eaa22e3bd34ac13caf923801  cdrom-1.iso
        [root@lvm-host test]# md5sum cdrom-2.iso
        d23eab94eaa22e3bd34ac13caf923801  cdrom-2.iso
        卸载了重新挂载，严谨一点做验证。
10. 数据安全后，将sdb1和sdc1从VG卷组中移除

        [root@lvm-host test]# vgs
        VG     #PV #LV #SN Attr   VSize    VFree
        Book     3   1   0 wz--n-  <59.99g <39.99g
        查看vg还是有3个pv设备，现在可以将不用的pv从vg中进行移除。

        [root@lvm-host test]# vgreduce /dev/Book /dev/sdb1
        Removed "/dev/sdb1" from volume group "Book"
        [root@lvm-host test]# vgreduce /dev/Book /dev/sdc1
        Removed "/dev/sdc1" from volume group "Book"

        [root@lvm-host test]# vgs
        VG     #PV #LV #SN Attr   VSize    VFree
        Book     1   1   0 wz--n-  <30.00g <10.00g
        仅剩余1个PV设备。



## PVMOVE 在线更换磁盘

如果生产环境中，用于支撑lvm的磁盘损坏，但是又没有宕机的情况下，而恰巧“硬盘支持热插拔，操作系统内核支持硬盘的热插拔” 这个时候就可以进行PVMORE的磁盘更换

1. 查看原来的物理卷情况:

        [root@lvm-host test]# pvs
        PV         VG     Fmt  Attr PSize    PFree
        /dev/sdd1  Book   lvm2 a--   <30.00g <10.00g

2. 将sde1 加入到卷组中

        [root@lvm-host test]# vgextend Book /dev/sde1
        Volume group "Book" successfully extended
3. 查看状态，进行替换
        
        [root@lvm-host test]# pvs
        PV         VG     Fmt  Attr PSize    PFree
        /dev/sdd1  Book   lvm2 a--   <30.00g <10.00g
        /dev/sde1  Book   lvm2 a--   <40.00g <40.00g

        [root@lvm-host test]# pvmove /dev/sdd1
        /dev/sdd1: Moved: 0.02%
        /dev/sdd1: Moved: 5.39%
        ......
        /dev/sdd1: Moved: 84.71%
        /dev/sdd1: Moved: 100.00%
4. 可以移除原来那块硬盘(分区)了

        [root@lvm-host test]# vgreduce Book /dev/sdd1
        Removed "/dev/sdd1" from volume group "Book"

5. 将闲置硬盘(分区)从pv中删除        

        [root@lvm-host test]# pvremove /dev/sdd1
        Labels on physical volume "/dev/sdd1" successfully wiped.

## 总结
    生产环境中镜像法十分常用，LVM经常会用来替换有问题的磁盘又或者是对磁盘进行升级，例如将SAS设备升级为SSD设备，这样系统不用重新部署，数据也不用折腾搬家。
    pvmove 也是常用手段之一，该命令是在两个设备间镜像数据的最简单的一个，但是在真实环境中，镜像比pvmove使用得更为频繁。