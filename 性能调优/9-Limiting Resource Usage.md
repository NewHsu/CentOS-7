Limit Resource 
posix 的 pam_limits 对用户资源进行限制. 如果没有用户这套机制无法实现,必须知道用户是谁,很多程序都是root在运行,所以限制root没有任何意义.

回忆pam: system-auth
注意session, 用户登录成功之后怎么控制你.找到 pam_limits. 用户必须登录有交互.
找到 limits.conf . 要么写子文件,要么写主文件.

限制CPU:
    limits.conf  限制cpu 以分钟.占用cpu时间.最少1分钟.
	可以top查看占用cpu时间.
      
zhangsan    hard    cpu   2
zhangsan    soft     cpu    1    软限制可以自己使用 ulimit -t 进行时间调节
ulimit -a 查看限制... 要用zhangsan登录.
多进程也是弊端. 每个进程是单计时.


可以写用户名或者 uid   如果是 :500：就是大于500以上的.
@root  为分组.


内存限制: RSS 以及  AS 
    RSS :　驻留内存.  程序真的使用内存多少.  无法实现RSS控制.
    AS:虚存地址空间，代表程序希望得到多少内存空间． 只能使用AS.  单位KB.
按需延时分配.一个承诺而已.不一定预先分配给你.


限制进程数:
     默认企业版6是 1024.
	bomb(){ bomb|bomb& };bomb
	:(){ :|:& };:    出现资源临时不可用.

        设置:
           zhangsan     hard     noproc   100
ulimit 不能控制 磁盘I/O...控制CPU 和内存 比较简单的手段.

cgroup
 所有子系统分类,称为不同的controllers. 应用程序的质量管理.
  带限制,带管理的进程分配到这些controllers之下的目录之中.
   具有一定的继承性,做好限制之后,将进程放进去将被限制.
   树形结构,儿子会继承父亲的限制.而且儿子的限制的可以更严厉一些.
   同一时刻,一个controllers只能为一个单独的目录服务.
RedHat是将每个控制分来设计的,CPU就是CPU.内存就是内存.
但是也可以调节一个controlers控制CPU和内存.
   修改 /etc/cgconfig.conf 可以将2个子系统放在一个目录里.
   从新启动的时候,要离开这个目录.

Cpuset = /cgroup/cm;
Memory = /cgroup/cm;
原来的要注释掉


cgconfig 服务负责: 挂载controllers.    创建cgroups. 开启cgroup 配置
cgred 服务负责:  把想管理和控制的程序放到cgroup内.
cgroup在内核空间实现.

lssubsys -m 查看当前挂载的子系统.

controller 理解为子系统.
CPU限制:
	1: 创建CPUgroup组.

	vi /etc/cgconfig.conf
		group lsesscpu {
		cpu {
			}
}
		group morecpu{
		cpu{	
			}
}

启动以后可以在/cgroup的cpu中看到,并且可以看到内部数据继承与父亲.

vi /etc/cgconfig.conf
		group lsesscpu {
		cpu {
			cpu.shares = 100;  (大于10之一的CPU)
			}
}
		group morecpu{
		cpu{	
			cpu.shares = 200;  (大于20分之一的CPU)
			}
}

重新启动,在查看 less为100.. more为200
如果是多CPU,最好关闭一些然后进行实验:
echo 0 > /sys/devices/system/cpu/cpu[1-?]/online

指令捆绑进程,临时.
cgexec -g cpu:/esscpu time dd if=/dev/zero of=/dev/null bs=1M count=20000000
cgexec -g cpu:/morecpu time dd if=/dev/zero of=/dev/null bs=1M count=20000000

使用top监控,效果非常明显.  看cpu的使用率..多核心要注意计算,无法直观看到.
这里的是一个相对的关系，2个一起dd可以看出倍数的关系。

内存控制:
	创建内存的group
		vi /etc/cgconfig.conf
		group poormem {
		memory {
			memory.limit_in_bytes=xxxxxx;   未来在这个cgroup内的进程可使用的物理内存 (KB)  
			menory.memsw.limit_in_bytes= xxxxx;  物理内存加交换可以使用的数量.
			}
}
	256MB举例:   256 * 2^20	写到

实验使用:
制作内存盘来使用内存.
	mkdir /mnt/tmpfs
	mount -t tmpfs none /mnt/tmpfs

可以先写200M到内存盘看看是否内存减少

cgexec -g memory:/poormem dd if=/dev/zero of=/mnt/tmpfs/bigfile  bs=1M count=300

这个实验结果是成功的,但是要注意交换分区被使用了...交换分区被使用.
所以限制并不是很完美.

menory.memse.limit_in_bytes= xxxxx;  物理内存加交换可以使用的数量.
加入这条以后将不在成功.   

物理内存必须先限制,才能限制物理内存+交换.

限制I/O:
建立cgroup

	vi /etc/cgconfig.conf
		group iolow {
		blkio {
			blkio.weight = 100;
			}
}
		group highio{
		blkio{	
			blkio.weight = 200;
			}
}
		group ddio{
		blkio{	
			blkio.throttle_read_bps_device = “252:0 1000000”;
		针对某设备进行读限制,该例子为1M字节,每秒, 设置是252:0 虚拟VDA,真实设备要去查看主从设备号.
			}
}

权重控制,需要CFQ的调度算法来支持,必须.
查看   cat /sys/block/vda......... 

测试:
	1: 创建2个 2G的大文件.   (SSD测试没有效果.)
	2: 丢掉缓存: echo 3 > /proc/sys/vm/drop_caches
	3: cgexec -g blkio:/iolow time cat /bigfile1 > /dev/null
	    cgexec -g blkio:/highio time cat /bigfile2 > /dev/null
	4: iotop 监控,查看读取比例.
	
使用cgred进行编辑文件限制.

vi /etc/cgreules.conf
zhangsan:dd     blkio ddio/
*:dd		blkio  ddio/
zhangsan:*    blkio   ddio/

只能是可执行文件的名称, 进程名称.
一旦定义冲突,最小值生效.
张三执行任何指令无限制,但是只要执行DD 就会收到bklio的dd约束.
使用DD 进行测试,iostat查看,发现zhangsan只有1M的读取速度.

冻结: freeze
vi /etc/cgconfig.conf
		group stst {
		freezer {
						}
}

重启服务.  top...  然后找到 top的pid..
echo  pid >/cgroup/freezer/stst/tasks

echo FROZEN > /cgroup/freezer/stst/freezer.state  冻结
echo  THAWED > /cgroup/freezer/stst/freezer.state　解冻

可以使用IOTOP 或者 top来进行试验。


指定CPU给虚拟机
virsh dumpxml vvmname | grep cpu
virsh vcpuinfo vmname   虚拟CPU会随机使用CPU.

指定CPU.
echo 1 > /cgroup/cpuset/libvirt/qemu/vmname/cpuset.cpu
指定单个的CPU 给虚拟机使用
也可以
echo 0-3 > /cgroup/cpuset/libvirt/qemu/vmname/cpuset.cpu

cpu.share,  优先级.CPU的权重. 900的时候,要低于其它基本的进程.
默认系统的所有进程的cpu权重都是1024..所以一旦发生争抢,这个时候这个900的程序就要先暂时的退下来.
 
实例：
利用cgroup了来确定单独使用cpu
vi /etc/cgconfig.conf
	group 2ndcpu { cpuset { cpuset.cpus=1; cpuset.mems=0;} }
然后使用 cgexec 将程序放入
单独程序使用固定的CPU。