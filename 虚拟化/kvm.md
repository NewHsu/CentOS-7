# 虚拟化（KVM）

虚拟化概念很早就已出现，是指通过虚拟化技术将一台计算机虚拟为多台逻辑计算机。（例如，一台计算机可以同时运行多个Linux和Windows）。

## KVM服务介绍
KVM是(Kernel-based Virtual Machine)的简写，是一个开源的系统虚拟化软件，基于硬件虚拟化扩展（Intel VT-X 和 AMD-V）和 QEMU 的修改版，是基于硬件的完全虚拟化。

KVM 中，虚拟机被实现为常规的 Linux 进程，由标准 Linux 调度程序进行调度；KVM 本身不执行任何硬件模拟，需要客户空间程序通过 /dev/kvm 接口设置一个客户机虚拟服务器的地址空间，向它提供模拟的 I/O，并将它的视频显示映射回宿主的显示屏。目前这个应用程序是 QEMU。

逻辑图如下：

![](..\images\KVM\1.jpg)

重点理解：

```
Guest OS：客户机操作系统，也称为虚拟机（VM）。这些 VM 都是一些相互隔离的操作系统，将底层硬件平台视为自己所有。但是实际上，是系统管理程序为它们制造了这种假象。涵盖vCPU、内存、驱动（Console、网卡、I/O 设备驱动等），被 KVM 置于一种受限制的 CPU 模式下运行。
KVM：以模块的形式运行在 Linux 的内核空间层，提供 CPU 和内存的虚级化，对客户机进行I/O拦截，转交给QEMU处理。
QEMU：运行在用户空间层，提供硬件 I/O 虚拟化。
```

* 其实虚拟化这个技术已经是很老的技术了，现在这个技术已经很少会单独的使用了，企业中大多作为云的基础实现技术之一，这里不对原理做太多的介绍了，有兴趣的朋友自行参考一下虚拟化家族史和KVM源码资料会更透彻。
* 本书的重点是虚拟化是要结合CEPH以及OpenStack来使用。

## Kvm使用
### KVM安装
* KVM 需要有 CPU 的支持（Intel VT 或 AMD SVM）

        [root@CentOS7 ~]# egrep '(vmx|svm)' /proc/cpuinfo
        flags : fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx lm constant_tsc arch_perfmon pebs bts rep_good nopl aperfmperf pni dtes64 monitor ds_cpl vmx smx est tm2 ssse3 cx16 xtpr pdcm sse4_1 lahf_lm dts tpr_shadow vnmi flexpriority
* 关闭selinux

        [root@kvm network-scripts]# setenforce 0
        [root@kvm network-scripts]# getenforce
        Permissive
        [root@kvm network-scripts]#vi /etc/selinux/config
        ******************************************
        SELINUX=permissive                                           #修改配置文件使其永久生效
        ******************************************
* 所需要安装软件包

        qemu-kvm 主要的KVM程序包
        python-virtinst 创建虚拟机所需要的命令行工具和程序库
        virt-manager GUI虚拟机管理工具
        virt-top 虚拟机统计命令
        virt-viewer GUI连接程序，连接到已配置好的虚拟机
        libvirt C语言工具包，提供libvirt服务
        libvirt-client 为虚拟客户机提供的C语言工具包
        virt-install 基于libvirt服务的虚拟机创建命令
        bridge-utils 创建和管理桥接设备的工具
        
        # yum install qemu-kvm libvirt virt-install bridge-utils virt-manager virt-top virt-viewer libvirt-client 
* 启动和查看

        [root@localhost ~]# systemctl start libvirtd;systemctl enable libvirtd
        [root@localhost ~]# systemctl list-unit-files|grep libvirtd
        libvirtd.service                            enabled 
        libvirtd.socket                             static  

### KVM网络设置
* Kvm虚拟机需要和外部网络通讯，那么需要借助于本地的物理网卡来进行桥接，然后才可以和外部网络通讯，让其他主机正常的访问该虚拟机。
* 修改网卡文件，制作网络桥接

        #cd /etc/sysconfig/network-scripts/
        #echo "BRIDGE=br0" >> ifcfg-enp0s3  //修改为当前主机网卡
        ￥vim ifcfg-br0
            DEVICE=br0 
            TYPE="Bridge" 
            BOOTPROTO="dhcp"   //实例为自动获取IP，可以设置为固定ip
            ONBOOT="yes"
            DELAY="0"
        #systemctl restart NetworkManager
        #systemctl restart network
        #ip a
        br0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP 
            link/ether 08:00:27:45:0b:ad brd ff:ff:ff:ff:ff:ff
        inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic br0
        …………………
        #brctl show
        bridge name	bridge id		STP enabled	interfaces
        br0		8000.080027450bad	no		enp0s3

### 创建KVM虚拟机
    #mkdir -p /var/kvm/images
    #qemu-img create -f qcow2 /var/kvm/images/centos7.img 120G
    #virt-install  --name centos7.0 --ram 1024 --cdrom=/root/CentOS-7-x86_64-DVD-1503-01.iso --disk path=/var/kvm/images/centos7.img,size=120,format=qcow2 --network bridge=br0 --graphics vnc,listen=0.0.0.0 --noautoconsole --os-type=linux --os-variant=rhel7
>参数表

|参数|解释|
|:---|:---|
|-n|--name= 客户端虚拟机名称
|-r |--ram= 客户端虚拟机分配的内存
|-u |--uuid= 客户端UUID 默认不写时，系统会自动生成
|--vcpus= |客户端的vcpu个数
|-v --hvm |全虚拟化
|-p --paravirt |半虚拟化
|-l --location=localdir |安装源，有本地、nfs、http、ftp几种，多用于ks网络安装
|--vnc |使用vnc ，另有--vnclient＝监听的IP  --vncport ＝VNC监听的端口
|-c --cdrom= |光驱 安装途径
|--disk= |使用不同选项作为磁盘使用安装介质
|-w NETWORK, --network=NETWORK |连接客户机到主机网络 
|-s --file-size= |使用磁盘映像的大小 单位为GB
|-f --file= |作为磁盘映像使用的文件
|--cpuset= |设置哪个物理CPU能够被虚拟机使用
|--os-type=OS_TYPE |针对一类操作系统优化虚拟机配置（例如：‘linux’，‘windows’）
|--os-variant=OS_VARIANT |针对特定操作系统变体（例如’rhel6’, ’winxp’,'win2k3'）进一步优化虚拟机配置
|--host-device=HOSTDEV |附加一个物理主机设备到客户机。HOSTDEV是随着libvirt使用的一个节点设备名（具体设备如’virsh nodedev-list’的显示的结果）
|--accelerate |KVM或KQEMU内核加速,这个选项是推荐最好加上。如果KVM和KQEMU都支持，KVM加速器优先使用。
|-x EXTRA, --extra-args=EXTRA |当执行从"--location"选项指定位置的客户机安装时，附加内核命令行参数到安装程序
|--nographics "virt-install" |将默认使用--vnc选项，使用nographics指定没有控制台被分配给客户机

>可以使用virt-manager或者在Applications > system tools > virtual machine manager 来启动图形界面进行安装
>至于使用图形界面安装就不多说了，简单的很，点来点去的就行了。

## KVM热迁移

* KVM 虚拟化的热迁移需要有NFS或者是glusterfs等共享文件系统的支持，将vm虚拟化磁盘文件放到共享文件上，然后主机节点只负责计算，存储在文件系统上，迁移的时候另外一台kvm host主机直接读取共享文件系统的文件即可。
* 双侧主机互相添加kvm节点链接，Kvm管理器中点击：File > Add Connection 

![](./images/KVM/2.png)

>如果未安装软件还请确认并安装必备的kvm软件包

* 添加成功后

![](./images/KVM/4.png)

### Nfs share 设置
* 修改配置并挂载

        #vim /etc/exports
        /kvm1 *(rw,sync,no_root_squash)
        # systemctl restart nfs-server.service
        然后2个节点 kvm1 和kvm2 主机分别挂载到/kvm文件夹下
        mount -t nfs 192.168.56.101:/kvm1 /kvm
        一定要关闭selinux
* 系统安装

        virt-install  --name centos7.0 --ram 1024 --cdrom=/root/CentOS-7-x86_64-DVD-1503-01.iso --disk path=/var/kvm/images/centos7.img,size=120,format=qcow2 --network bridge=br0 --graphics vnc,listen=0.0.0.0 --noautoconsole --os-type=linux --os-variant=rhel7
* KVM1主机查看

        virsh # list
        Id    Name                           State
        ----------------------------------------------------
        11    centos7.0                      running

* 迁移
        
        # migrate --live centos7.0 qemu+ssh://kvm2/system  --unsafe
        root@kvm2's password: 
* KVM2主机查看
        virsh # list
        Id    Name                           State
        ----------------------------------------------------
        12    centos7.0                      running

## 常用指令
* kvm克隆一个虚拟机 
        
        [root@nfs data]# virt-clone -o win2003 -n xp1 -f /home/data/xp1.img 
        如果要想克隆虚拟机，原虚拟机必须处于关闭状态
* 显示所有的虚拟机 

        [root@nfs data]# virsh list       ##只显示运行状态下的虚拟机
        [root@nfs data]# virsh list --all##所有的虚拟机，无论是否在工作
* 启动虚拟机
        
        [root@nfs ~]# virsh start vm01          
* 强制关掉宿主机导致宿主机开机后不能启动vm 

        解决方法： 
        [root@nfs ~]# virsh undefine vm01 
        [root@nfs ~]# virsh managedsave-remove  vm01 
        [root@nfs ~]# virsh start vm01
* 删除一个虚拟机vm01 

        [root@nfs qemu]# virsh undefine  vm01 
        [root@nfs qemu]# rm -f /home/data/vm01.img 
* 暂停一个虚拟机，挂起的虚拟机无法正常工作 

        Virsh suspend vm01
        Virsh resume vm01  //恢复一个主机
* 执行一个guest的快照 

        Virsh snapshot-create-as vm01 vm01.snap
        注意vm01的文件格式不能是raw，否则是不支持快照的！ 
* 显示快照 
        
        [root@nfs web01]# virsh snapshot-list web01 
* 删除一个快照： 
        
        [root@nfs web01]# virsh snapshot-delete web01  web01.snap4 
* 启动虚拟机的两种方式： 

        # virsh start MyNewVM
        # virsh create /path/to/MyNewVM.xml
* 关闭和重启

        # virsh shutdown 
        # virsh reboot 
* 查看某个guest的信息： 
        
        [root@nfs init.d]# virsh dominfo nodeA  
* 查看物理机的相关信息： 
        
        [root@nfs init.d]# virsh nodeinfo 
* 生成一个domain的xml文件(配置文件) 
        
        [root@nfs data]# virsh dumpxml nodeA >nodeAback.xml  
* 当前状态保存
        
        Virsh save vm01 vm01_bak.img 
* restore a guest 
        
        Virsh restore vm01_bak.img
* 查看网络配置

        virsh # domiflist centos7.0
        Interface  Type       Source     Model       MAC
        -------------------------------------------------------
        vnet0      bridge     br0        virtio      52:54:00:6c:4d:d8
* 查看磁盘配置

        virsh # domblklist centos7.0
        Target     Source
        ------------------------------------------------
        vda        /kvm/centos7.img
        hda       


## KVM调优
针对于不同的应用，需要对KVM虚拟机进行调优，达到最大化的性能使用。
### CPU Tuning
* 对于物理 CPU，同一个 core 的 threads 共享 L2 Cache，同一个 socket 的 cores 共享 L3 cache，所以虚拟机的 vcpu 应当尽可能在同一个 core 和 同一个 socket 中，增加 cache 的命中率，从而提高性能。
* 实现策略：虚拟机 vcpu 尽可能限定在一个 core 或者一个 socket 中。例如：当 vcpu 为 2 时，2 个 vcpu 应限定在同一个 core 中，当 vcpu 大于 2 小于 12 时，应限定在同一个 socket 中。
        
        <vcpu placement='static' cpuset='0-5'>4</vcpu>       # cpuset 限定 vcpu
### Disk IO Tuning
* kvm 支持多种虚拟机多种 IO Cache 方式：writeback, none, writethrough 等。性能上：writeback > none > writethrough，安全上 writeback < none < writethrough

        <disk type='file' device='disk'>
        
        <driver name='qemu' type='qcow2' cache='none'/>  # cache 可为 writeback, none, writethrough，directsync，unsafe 等
        ...
        </disk>
### Memory Tuning
* 打开KSM(Kernel Samepage Merging) 
* 页共享早已有之,linux中称之为COW(copy on write)。内核2.6.32之后又引入了KSM。KSM特性可以让内核查找内存中完全相同的内存页然后将他们合并,并将合并后的内存页打上COW标 记。KSM对KVM环境有很重要的意义,当KVM上运行许多相同系统的客户机时,客户机之间将有许多内存页是完全相同的,特别是只读的内核代码页完全可以 在客户机之间共享,从而减少客户机占用的内存资源,从而可以同时运行更多的客户机。 

        Debian系统中KSM默认是关闭的,通过以下命令来开启KSM 
        # echo 1 > /sys/kernel/mm/ksm/run 
        关闭KSM 
        # echo 0 > /sys/kernel/mm/ksm/run 
* 这样设置后,重新启动系统KSM会恢复到默认状态,尚未找个哪个内核参数可以设置在/etc/sysctl.conf中让KSM持久运行。 

        可以在/etc/rc.local中添加 
        echo 1 > /sys/kernel/mm/ksm/run 

* 让KSM开机自动运行 
        
        通过/sys/kernel/mm/ksm目录下的文件来查看内存页共享的情况,pages_shared文件中记录了KSM已经共享的页面数。
### KVM Huge Page Backed Memory 
* 通过为客户机提供巨页后端内存,减少客户机消耗的内存并提高TLB命中率,从而提升KVM性能。x86 CPU通常使用4K内存页,但也有能力使用更大的内存页,x86_32可以使用4MB内存页，x86_64和x86_32 PAE可以使用2MB内存页。x86使用多级页表结构,一般有三级,页目录表->页表->页,所以通过使用巨页,可以减少页目录表和也表对内 存的消耗。当然x86有缺页机制,并不是所有代码、数据页面都会驻留在内存中。
* 允许某个 Guest 开启透明大页

        Guest XML Format
        <memoryBacking>
        <hugepages/>
        </memoryBacking>
        
        echo 25000 > /pro c/sys/vm/nr_hugepages
        mount -t hugetlbfs hugetlbfs /dev/hugepages
        service libvirtd restart
* 允许 Host 中所有 Guest 开启透明大页和内存碎片整理

        透明大页的开启：
        echo always > /sys/kernel/mm/transparent_hugepage/enabled
        
        内存碎片整理的开启：
        echo always> /sys/kernel/mm/transparent_hugepage/defrag

### Network IO Tuning
* 半虚拟化io设备，针对cpu和内存，kvm全是全虚拟化设备，而针对磁盘和网络，则出现了半虚拟化io设备，目的是标准化guest和host之间数据交换接口，减少交互流程和内存拷贝，提升vm io效率。
* 更改虚拟网卡的类型，由全虚拟化网卡e1000、rtl8139，转变成半虚拟化网卡virtio，virtio需要qemu和vm内核virtio驱动的支持



## 总结：
    1. 以上虚拟机创建和迁移步骤都可以通过图形界面去完成，自行尝试一下，不浪费篇幅截图了。
    2. KVM的虚拟机是企业里较为常用的虚拟化技术，配合openstack使用。
    3. 调优部分深入掌握，有助于在将来生产环境中进行有针对行的系统调节。
    4. 配文文件详解参考附录-KVM配置文件详解


