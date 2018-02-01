# Cgroup
## Cgroup服务
* cgroup是control group的简称，它为Linux内核提供了一种任务聚集和划分的机制，通过一组参数集合将一些任务组织成一个或多个子系统。  
        * Cgroups是control groups的缩写，最初由Google工程师提出，后来编进linux内核。
        * Cgroups是实现IaaS虚拟化(kvm、lxc等)，PaaS容器沙箱(Docker等)的资源管理控制部分的底层基础
        * 子系统是根据cgroup对任务的划分功能将任务按照一种指定的属性划分成的一个组，主要用来实现资源的控制。在cgroup中， 划分成的任务组以层次结构的形式组织，多个子系统形成一个数据结构中类似多根树的结构。cgroup包含了多个孤立的子系统，每一个子系统代表单一的资源，目前，CentOS默认支持10个子系统，但默认只挂载了8个子系统。
## Cgroup功能和组成
* CGroup 是将任意进程进行分组化管理的 Linux 内核功能。CGroup 本身是提供将进程进行分组化管理的功能和接口的基础结构，I/O 或内存的分配控制等具体的资源管理功能是通过这个功能来实现的。这些具体的资源管理功能称为 CGroup 子系统或控制器。CGroup 子系统有控制内存的 Memory 控制器、控制进程调度的 CPU 控制器等。
## CGroup 相关概念解释
* 任务（task）。在 cgroups 中，任务就是系统的一个进程；
* 控制族群（control group）。控制族群就是一组按照某种标准划分的进程。Cgroups 中的资源控制都是以控制族群为单位实现。一个进程可以加入到某个控制族群，也从一个进程组迁移到另一个控制族群。一个进程组的进程可以使用 cgroups 以控制族群为单位分配的资源，同时受到 cgroups 以控制族群为单位设定的限制；
* 层级（hierarchy）。控制族群可以组织成 hierarchical 的形式，既一颗控制族群树。控制族群树上的子节点控制族群是父节点控制族群的孩子，继承父控制族群的特定的属性；
* 子系统（subsystem）。一个子系统就是一个资源控制器，比如 cpu 子系统就是控制 cpu 时间分配的一个控制器。子系统必须附加（attach）到一个层级上才能起作用，一个子系统附加到某个层级以后，这个层级上的所有控制族群都受到这个子系统的控制。
## 相互关系
* 每次在系统中创建新层级时，该系统中的所有任务都是那个层级的默认 cgroup（我们称之为 root cgroup，此 cgroup 在创建层级时自动创建，后面在该层级中创建的 cgroup 都是此 cgroup 的后代）的初始成员；

        1. 一个子系统最多只能附加到一个层级；
        2. 一个层级可以附加多个子系统；
        3. 一个任务可以是多个 cgroup 的成员，但是这些 cgroup 必须在不同的层级；
* 系统中的进程（任务）创建子进程（任务）时，该子任务自动成为其父进程所在 cgroup 的成员。然后可根据需要将该子任务移动到不同的 cgroup 中，但开始时它总是继承其父任务的 cgroup。

![](../images/cgroup/1.png)
>所示的 CGroup 层级关系显示，CPU 和 Memory 两个子系统有自己独立的层级系统，而又通过 Task Group 取得关联关系。

## CGroup 特点
* 在 cgroups 中，任务就是系统的一个进程。
* 控制族群（control group）。控制族群就是一组按照某种标准划分的进程。Cgroups 中的资源控制都是以控制族群为单位实现。一个进程可以加入到某个控制族群，也从一个进程组迁移到另一个控制族群。一个进程组的进程可以使用 cgroups 以控制族群为单位分配的资源，同时受到 cgroups 以控制族群为单位设定的限制。
* 层级（hierarchy）。控制族群可以组织成 hierarchical 的形式，既一颗控制族群树。控制族群树上的子节点控制族群是父节点控制族群的孩子，继承父控制族群的特定的属性。
* 子系统（subsytem）。一个子系统就是一个资源控制器，比如 cpu 子系统就是控制 cpu 时间分配的一个控制器。子系统必须附加（attach）到一个层级上才能起作用，一个子系统附加到某个层级以后，这个层级上的所有控制族群都受到这个子系统的控制。

## CGroup 应用架构
![](../images/cgroup/2.png)
>CGroup 技术可以被用来在操作系统底层限制物理资源，起到 Container 的作用。图中每一个 JVM 进程对应一个 Container Cgroup 层级，通过 CGroup 提供的各类子系统，可以对每一个 JVM 进程对应的线程级别进行物理限制。

## cgroup子系统介绍
* 下面对每一个子系统进行简单的介绍：
* 可以使用centOS everything 光盘，安装kernel-doc，然后在cat /usr/share/doc/kernel-doc-3.10.0/Documentation/cgroups/ 目录内查看各个子系统的详细参数说明

        blkio 设置限制每个块设备的输入输出控制。例如:磁盘，光盘以及usb等等。
        cpu 使用调度程序为cgroup任务提供cpu的访问。
        cpuacct 产生cgroup任务的cpu资源报告。
        cpuset 如果是多核心的cpu，这个子系统会为cgroup任务分配单独的cpu和内存。
        devices 允许或拒绝cgroup任务对设备的访问。
        freezer 暂停和恢复cgroup任务。
        memory 设置每个cgroup的内存限制以及产生内存资源报告。
        net_cls 标记每个网络包以供cgroup方便使用。
        net_prio--允许管理员动态的通过各种应用程序设置网络传输的优先级，类似于socket 选项的SO_PRIORITY，但它有它自身的优势
        HugeTLB--HugeTLB页的资源控制功能
            ns 名称空间子系统。
        perf_event 增加了对每group的监测跟踪的能力，即可以监测属于某个特定的group的所有线程以及             运行在特定CPU上的线程，此功能对于监测整个group非常有用，具体参见 http://lwn.net/Articles/421574/
* 当然也用户可以自定义子系统并进行挂载

        cpuset:/
        cpu,cpuacct:/
        memory:/
        devices:/
        freezer:/
        net_cls:/
        blkio:/
        perf_event:/
        hugetlb:/
## 子系统关系
1： 系统中第一个被创建的cgroup被称为root cgroup，该cgroup的成员包含系统中所有的进程 
2：一个层级中不能出现重复的子系统。 3：进程与Cgroup属于多对多的关系。 
4：一个进程创建了子进程后，该子进程默认为父进程所在cgroup的成员。 
5：一个任务不能同时属于同一个层次结构中的两个 cgroup。

## 子系统相应参数介绍 
1. tasks 属于该group的进程ID 
2. cgroup.procs 属于该group的线程ID 
3. cgroup.event_control 属于cgroup的通知API，允许改变cgroup的状态 
4. notify_on_release 布尔值 是否启用客户端通知，启用时，内核执行release_agent时，cgroup不在包含任何任务（去清空tasks内容）。提供了一个清空group的方法。 
>注意：root的group默认是0，非root的group和其父group一样,release_agent：仅适用于root group；当notify on release被触发时，执行该文件命令；当一个gorup进程全部清空，并且启用了notify_on_release。

## Cgroup配置和管理
### Cgroup-libcgroup Man Page简介
    man 1 cgclassify -- cgclassify命令是用来将运行的任务移动到一个或者多个cgroup。
    man 1 cgclear -- cgclear 命令是用来删除层级中的所有cgroup。
    man 5 cgconfig.conf -- 在cgconfig.conf文件中定义cgroup。
    man 8 cgconfigparser -- cgconfigparser命令解析cgconfig.conf文件和并挂载层级。

    man 1 cgcreate -- cgcreate在层级中创建新cgroup。
    man 1 cgdelete -- cgdelete命令删除指定的cgroup。
    man 1 cgexec -- cgexec命令在指定的cgroup中运行任务。
    man 1 cgget -- cgget命令显示cgroup参数。
    man 5 cgred.conf -- cgred.conf是cgred服务的配置文件。
    man 5 cgrules.conf -- cgrules.conf 包含用来决定何时任务术语某些  cgroup的规则。
    man 8 cgrulesengd -- cgrulesengd 在  cgroup 中发布任务。
    man 1 cgset -- cgset 命令为  cgroup 设定参数。
    man 1 lscgroup -- lscgroup 命令列出层级中的  cgroup。
    man 1 lssubsys -- lssubsys 命令列出包含指定子系统的层级。
### lssubsys –am    #查看已存在子系统
    cgclear   # 清除所有挂载点内部文件
    cgconfigparser -l /etc/cgconfig.conf    #重新挂载
    Cgroup默认挂载点（CentOS7）：/sys/fs/cgroup
    cgconfig配置文件：/etc/cgconfig.conf
### Cgroup默认挂载点(各个子系统)
    cgroup on /sys/fs/cgroup/cpuset type cgroup (……)
    …………
### Systemd-cgls  查看cgroup的资源限制
    可以使用systemctl来使用cgroup对systemctl使用的进程进行限制
    systemctl set-property httpd.service CPUShares=600
    MemoryLimit=500M
    systemctl set-property --runtime httpd.service CPUShares=600
    MemoryLimit=500M
* 设置之后可以在cat /etc/systemd/system/httpd.service.d/目录中查看到设置规则。
* 这种设置即使引用cgroup中的systemd控制。同样这种规则也适用于限制IO和内存，以及网络等。
>设置完成后需要

    systemctl daemon-reload
    systemctl restart httpd.service
    systemctl status httpd.service
    httpd.service - The Apache HTTP Server
    Loaded: loaded (/usr/lib/systemd/system/httpd.service; disabled)
    Drop-In: /etc/systemd/system/httpd.service.d
            └─90-CPUShares.conf, 90-MemoryLimit.conf
    Active: active (running) since Tue 2016-01-19 01:15:04 EST; 7min ago
    Process: 3630 ExecStop=/bin/kill -WINCH ${MAINPID} (code=exited, status=0/SUCCESS)
    Main PID: 3636 (httpd)
    Status: "Total requests: 0; Current requests/sec: 0; Current traffic:   0 B/sec"
    CGroup: /system.slice/httpd.service
            ├─3636 /usr/sbin/httpd -DFOREGROUND
            ├─3637 /usr/sbin/httpd -DFOREGROUND
            ├─3638 /usr/sbin/httpd -DFOREGROUND
            ├─3639 /usr/sbin/httpd -DFOREGROUND
            ├─3640 /usr/sbin/httpd -DFOREGROUND
            └─3641 /usr/sbin/httpd -DFOREGROUND

    Jan 19 01:15:04 kvm1 httpd[3636]: AH00558: httpd: Could not reliably determine the server's full...sage
    Jan 19 01:15:04 kvm1 systemd[1]: Started The Apache HTTP Server.
    Hint: Some lines were ellipsized, use -l to show in full.

### cat /proc/3636/cgroup 
    10:hugetlb:/
    9:perf_event:/
    8:blkio:/
    7:net_cls:/
    6:freezer:/
    5:devices:/
    4:memory:/system.slice/httpd.service
    3:cpuacct,cpu:/system.slice/httpd.service
    2:cpuset:/
    1:name=systemd:/system.slice/httpd.service
### System-cgtop
    可以使用/etc/cgconfig.conf 来修正需要挂载的子系统，
    mount {
    net_prio = /sys/fs/cgroup/net_prio;
    }
    这里如果要重新定义这个挂载点需要使用
    cgclear   # 清除所有挂载点内部文件
    cgconfigparser -l /etc/cgconfig.conf    #重新挂载
    其实没有必须自己定义，系统已经定义好，如果你需要限制多项，那么在启动的时候使用systemctl限制，或者是使用cgcreate都可以
    ============================================================
    这里有错误，需要先卸载所有已经有的cgroup挂载才能进行双挂载
    mount -t cgroup -o cpuset,memory,net_cls lab1 /dev/lab1 – EBUSY
    否则只能进行单独的挂载
    umount /sys/fs/cgroup/controller_name   进行卸载

## Cgroup常用实例
### Cgroup-CPU

补全说明

#### 限制进程的cpu占用百分比 
1. 编写耗CPU的脚本
    
        Vim /root/cpu.sh
        #!/bin/bash
        x=0
        while [ True ];do
            x=$x+1
        done;
2. 测试脚本耗cpu到100%

        Bash ~/cpu.sh
        进程top查看
        PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND                           
        3782 root      20   0  115412   3548   1200 R 100.0  0.1   6:47.98 bash                              
        ………       
3. 在默认的挂载点下创建需要控制的程序组
        
        Mkdir  /sys/fs/cgroup/cpu/while
4. 将cpu.cfs_quota_us设为50000，相对于cpu.cfs_period_us的100000是50%

        echo 50000 > /sys/fs/cgroup/cpu/while/cpu.cfs_quota_us
5. 将进程关联到控制组
        
        echo 3782 > /sys/fs/cgroup/cpu/while/tasks
6. 再次查看CPU消耗为 50%上限

        PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND                  3782 root      20   0  115632   3856   1200 R  49.5  0.1   8:13.42 bash 
#### 限制多个进程组的之间的cpu使用权重
1. 这个限制最好是在1个cpu的情况下，较为直观，因为如果你多cpu或者多核心的情况下进程分布在不同的核心或者cpu上执行，不会太明显的体现争抢资源，所以我在线OFFLINE其他CPU，只留1个CPU。

        [root@kvm1 cgroup]# cat /sys/devices/system/cpu/online 
        0-2   //虚拟机3颗vcpu
        [root@kvm1 while]# echo 0 >  /sys/devices/system/cpu/cpu2/online 
        [root@kvm1 while]# echo 0 >  /sys/devices/system/cpu/cpu1/online 
        [root@kvm1 while]# cat /sys/devices/system/cpu/online 
        0
2. 同样执行2个消耗CPU的进程，看到结果是各占50%左右                            

        PID USER      PR  NI    VIRT    RES    SHR S %CPU %MEM     TIME+ COMMAND                  
        8794 root      20   0  113428   1628   1200 R 50.0  0.1   0:05.27 bash                    8793 root      20   0  113272   1644   1200 R 49.3  0.1   0:06.57 bash                
3. 创建Cgroup目录

        cd /sys/fs/cgroup/
        mkdir while
        cd while/
4. Cpu.shares

        /cpu/cpu.shares : 1024
        /cpu/foo/cpu.shares : 2048
>那么当两个组中的进程都满负荷运行时，/foo 中的进程所能占用的 cpu 就是 / 中的进程的两倍。如果再建一个 /foo/bar 的 cpu.shares 也是 1024，且也有满负荷运行的进程，那 /、/foo、/foo/bar 的 cpu 占用比就是 1:2:1 。前面说的是各自都跑满的情况。如果其他控制组中的进程闲着，那某一个组的进程完全可以用满全部 cpu。可见通常情况下，这种方式在保证公平的情况下能更充分利用资源。

    echo 2048 > /sys/fs/cgroup/cpu/while/cpu.shares
    echo 8793 > /sys/fs/cgroup/cpu/while/tasks
5. 调节2,可以看出是CPU的权重使用差异
        
        PID USER      PR  NI    VIRT    RES    SHR S %CPU %MEM     TIME+ COMMAND                          
        8793 root      20   0  114060   2280   1200 R 66.4  0.1   0:57.28 bash                          
        8794 root      20   0  114000   2212   1200 R 33.2  0.1   0:50.30 bash              

#### 指定进程的使用的cpu和内存组（绑定cpu）
1. 还可以限定进程可以使用哪些 cpu 核心。cpuset 子系统就是处理进程可以使用的 cpu 核心和内存节点，以及其他一些相关配置。这部分的很多配置都和 NUMA 有关。其中 cpuset.cpus、cpuset.mems 就是用来限制进程可以使用的 cpu 核心和内存节点的。这两个参数中 cpu 核心、内存节点都用 id 表示，之间用 “,” 分隔。比如 0,1,2 。也可以用 “-” 表示范围，如 0-3 。两者可以结合起来用。如“0-2,6,7”。在添加进程前，cpuset.cpus、cpuset.mems 必须同时设置，而且必须是兼容的，否则会出错。例如

        [root@kvm1 cpu]# cat /sys/devices/system/cpu/online 
        0-2

2. 进程9019，使用cpu   100%

        PID USER     PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND                 
        9019 root      20   0  113276   1644   1200 R  99.7  0.1   0:06.88 bash            
3. 查看9091在哪颗CPU上运行

        [root@kvm1 cpu]# cat /proc/9019/status  | grep "_allowed_list"
        Cpus_allowed_list:	0-2
        Mems_allowed_list:	0
4. 设置内存和CPU使用

        [root@kvm1 while]# echo 0 > /sys/fs/cgroup/cpuset/while/cpuset.mems 
        [root@kvm1 while]# echo 0 > /sys/fs/cgroup/cpuset/while/cpuset.cpus
5. 写入进程进行限制并查看结果

        [root@kvm1 while]# echo 9019 > /sys/fs/cgroup/cpuset/while/tasks
        [root@kvm1 while]# cat /proc/9019/status  | grep "_allowed_list"
        Cpus_allowed_list:	0
        Mems_allowed_list:	0

### Memory
补全
#### 限制了资源的占用，达到内存以后，进程直接杀掉
1. 编写一个耗内存的脚本，内存不断增长

        x="a"
        while [ True ];do
            x=$x$x
        done;
2. top看内存占用稳步上升

        KiB Swap:  2097148 total,  2095040 free,     2108 used.   777372 avail Mem 
        PID USER     PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND                 
        4854 root      20   0  3258884  1.812g  988 R  100.0  60.9     0:23.73 bash           
3. 设置内存限制

        mkdir -p /sys/fs/cgroup/memory/while
        echo 1048576 >  /sys/fs/cgroup/memory/while/memory.limit_in_bytes   #分配1MB的内存给这个控制组
        echo 4854 > /sys/fs/cgroup/memory/while/tasks
4. 执行脚本

        [root@kvm1 ~]# bash mem.sh 
        Killed	
* 因为这是强硬的限制内存，当进程试图占用的内存超过了cgroups的限制，会触发out of memory，导致进程被kill掉。
* 实际情况中对进程的内存使用会有一个预估，然后会给这个进程的限制超配50%比如，除非发生内存泄露等异常情况，才会因为cgroups的限制被kill掉。
* 也可以通过配置关掉cgroups oom kill进程，通过memory.oom_control来实现（oom_kill_disable 1），但是尽管进程不会被直接杀死，但进程也进入了休眠状态，无法继续执行，仍让无法服务。
* 实际内存控制还有如下选项，同时包含虚拟内存控制和权重控制等等。
    
        [root@kvm1 ~]# ls /sys/fs/cgroup/memory/while/

### Blkio-控制io设备的读写速度
1. 跑一个耗io的脚本
        
        dd if=/dev/sda of=/dev/null 
2. 通过iotop看io占用情况，磁盘速度到了301.88 M/s
        
        TID  PRIO  USER     DISK READ  DISK WRITE  SWAPIN     IO>    COMMAND                             
        5536 be/4 root      301.88 M/s    0.00 B/s  0.00 %  0.00 % dd if=/dev/sda of=/dev/null
3. 下面用cgroups控制这个进程的io资源

        mkdir -p /sys/fs/cgroup/blkio/dd
        echo '8:0  1048576' >  /sys/fs/cgroup/blkio/dd/blkio.throttle.read_bps_device
        #8:0对应主设备号和副设备号，可以通过ls -l /dev/sda查看
        echo 5536  > /sys/fs/cgroup/blkio/dd/tasks
4. 再通过iotop看，确实将读速度降到了1M/s

        TID  PRIO  USER     DISK READ  DISK WRITE  SWAPIN     IO>    COMMAND                              
        5536 be/4 root      975.12 K/s    0.00 B/s  0.00 %  0.00 % dd if=/dev/sda of=/dev/null
5. 其他参数

        blkio 子系统里东西很多。不过大部分都是只读的状态报告，可写的参数就只有下面这几个：
        blkio.throttle.read_bps_device
        blkio.throttle.read_iops_device
        blkio.throttle.write_bps_device
        blkio.throttle.write_iops_device
        blkio.weight
        blkio.weight_device
>这些都是用来控制进程的磁盘 io 的。很明显地分成两类，其中带“throttle”的，顾名思义就是节流阀，将流量限制在某个值下。而“weight”就是分配 io 的权重。

>再看看 blkio.weight 。blkio 的 throttle 和 weight 方式和 cpu 子系统的 quota 和 shares 有点像，都是一种是绝对限制，另一种是相对限制，并且在不繁忙的时候可以充分利用资源，权重值的范围在 10 – 1000 之间。

### Blkio-控制io设备的读写权重
1. 测试权重方式要麻烦一点。因为不是绝对限制，所以会受到文件系统缓存的影响。如在虚拟机中测试，要关闭虚机如我用的 VirtualBox 在宿主机上的缓存。如要测试读 io 的效果，先生成两个几个 G 的大文件 /tmp/file_1，/tmp/file_2 ，可以用 dd 搞。然后设置两个权重

        [root@kvm1 ~]# dd if=/dev/cdrom of=./dd1.img 
        8419328+0 records in
        8419328+0 records out
        4310695936 bytes (4.3 GB) copied, 162.412 s, 26.5 MB/s
        [root@kvm1 ~]# dd if=/dev/cdrom of=./dd2.img 
        8419328+0 records in
        8419328+0 records out
        4310695936 bytes (4.3 GB) copied, 150.477 s, 28.6 MB/s
2. 创建Cgroup目录和设置权重

        [root@kvm1 ~]# mkdir -p /sys/fs/cgroup/blkio/dd1
        [root@kvm1 ~]# mkdir -p /sys/fs/cgroup/blkio/dd2
        # echo 500 >/sys/fs/cgroup/blkio/dd1/blkio.weight
        # echo 100 >/sys/fs/cgroup/blkio/dd2/blkio.weight
3. 测试前清空文件系统缓存，以免干扰测试结果

        #sync
        #echo 3 >/proc/sys/vm/drop_caches
4. 在这两个控制组中用 dd 产生 io 测试效果。

        [root@kvm1 ~]# cgexec -g "blkio:dd1" dd if=./dd1.img of=/dev/null &
        [1] 6200
        [root@kvm1 ~]# cgexec -g "blkio:dd2" dd if=./dd2.img of=/dev/null &
        [1] 6201

5. 还是用 iotop 看看效果

        TID  PRIO  USER    DISK READ  DISK WRITE  SWAPIN     IO>    COMMAND                               
        6200 be/4 root    71.20 M/s    0.00 B/s   0.00 % 81.98 % dd if=./dd1.img of=/dev/null
        6201 be/4 root    23.09 M/s    0.00 B/s  0.00  % 81.24 % dd if=./dd2.img of=/dev/null
        两个进程每秒读的字节数虽然会不断变动，但是大致趋势还是维持在 1:5 左右，和设定的 weight 比例一致。blkio.weight_device 是分设备的。写入时，前面再加上设备号即可。

### devices
devices子系统是通过提供device whilelist 来实现的，devices子系统通过在内核对设备访问的时候加入额外的检查来实现；而devices子系统本身只需要管理好可以访问的设备列表就行了。 

### freezer
该文件可能读出的值有三种，其中两种就是前面已提到的FROZEN和THAWED，分别代表进程已挂起和已恢复（正常运行），还有一种可能的值为FREEZING，显示该值表示该cgroup中有些进程现在不能被frozen。当这些不能被frozen的进程从该cgroup中消失的时候，FREEZING会变成FROZEN，或者手动将FROZEN或THAWED写入一次。  
	freezer.state:（仅对非root的group有效）           
	FROZEN：挂起进程 
      FREEZING：显示该值表示有些进程不能被frozen；当不能被挂起的进程从cgroup消失时，变成FROZEN，或者受到改为FROZEN或THAWED 
      THAWED ：恢复进程 
net_cls
perf_event
hugetlb
systemd
总结

