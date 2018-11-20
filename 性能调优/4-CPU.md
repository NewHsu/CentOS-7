## CPU

### Linux进程状态包括：
TASK_RUNNABLE：进程准备执行或者正在退出，只有当进程在该状态时才会被放到运行队列；
TASK_INTERRUPTIBLE： 进程正在等待一些事件，比如IO操作的完成；
TASK_UNINTERRUPTIBLE：进程在等待，但忽略收到的信号；
TASK_STOPPED：进程被挂起或者暂停；
TASK_ZOMBIE：僵尸进程，一般指该进程被杀死但是其父进程并没有产生相应的系统调用对其回收，该进程就称为僵尸。
僵尸进程实际上其所占用的资源已经被释放，但是因为没有被父进程回收而保留一个进程体结构而已。
那么相反，正常释放的进程实际上是子进程被杀死，然后父进程回收其资源；反过头来如果一个进程的父进程被杀死而子进程还存在，那么通常情况下init进程会成为其父进程。
如果进程请求I/O的时候会被移到TASK_INTERRUPTIBLE中，如果该进程获得了I/O并准备执行的时候他就会被移动到TASK_RUNNABLE中。

### ready run
进程运行前的准备工作包括：
在工作开始之前，数据必须存在于CPU的缓存中。若读取的数据在缓存中，称为缓存命中，若不在则称为缓存miss，对于miss的数据，内核会从内存中读取数据到缓存，这个过程称为填充缓存线，而将缓存中的数据填充到内存，包括write-rhtough和write-back。

在进程运行之前，所需要的数据需要先从CPU的缓存中读取。
Cache内的存储空间一般以线的形式体现和存在。每一个线都用来缓存一个指定的内存片。很多电脑都有不同的缓存用于缓存不同的内容，例如指令缓存和数据缓存。这种结构叫做哈佛内存架构。

在多处理器的系统上，每一个CPU都有自己单独的缓存。每一个缓存都有其关联的控制器。当一个进程访问内存的时候换从控制器会首先查看所需要的内存地址是否在缓存中并满足处理器的需求，若是则称为缓存命中。如果所需要的内存不在缓存中则称为cache miss，这时则需要读取内存并从内存中取出相应的数据，这个过程叫做cache line fill。

缓存控制器包含了一系列的缓存条目，这些缓存条目针对每一个缓存线。另外在被缓存的内存信息之外，每一个缓存条目都由一个tag和flags，这些用于描述缓存条目的状态。缓存控制器使用tag来标识哪一个内存位置被缓存为一个条目。

处理器会读写缓存。在写缓存操作进行到时候，缓存可以被配置为write-through或者write-back。如果write-through开启，那么当缓存中的一些线被更新，与之相关的主内存位置也会被更新。如果write-back开启，在缓存线被释放之前对其更改不会被立刻写入到内存中，直到缓存线被deallocated。从该角度看后者比前者更加高效。在x86架构上，每一个内存页都包含了控制位用于关闭页面缓存和write-back缓存。而Linux内核会清除在所有内存页面上的控制位所以默认情况下所有的内存访问都是通过write-back方式来缓存。

在多处理器的系统上，如果进程更新内存中的缓存线。那么其他处理器也会做同样的动作。这种情况称为cache snooping并在系统硬件上被执行。而NUMA架构系统会将内存组合成节点并将这些节点指派到不同的CPU插槽。


### CPU的缓存：
不同类型的CPU缓存会影响服务时间：
直接映射、全关联、部分关联
直接映射缓存是最一种最廉价的缓存。每一个缓存线都映射到内存中的一个指定位置上。
全关联缓存是最具灵活性并且也是最贵的一种缓存。因为其需要通过电路图执行？全关联缓存可以缓存内存中的任意位置。
而很多系统会折中地使用部分关联缓存。部分关联缓存也称为n路部分关联缓存。这里n是2的倍数。部分关联缓存可以使内存位置被读取到缓存的n个线中去。因此部分关联缓存提供了一个折中方案。

缓存线在128位内存中被映射为线。在使用P4 CPU或更好的Intel平台上，缓存线是128字节，而早期的处理器使用32字节的缓存线。
现代计算机都使用缓存来提高性能。缓存比内存快很多。一般主内存的访问时间为8ns，而缓存的访问时间和CPU的时钟频率一样小。并且很多计算机都有多级缓存。其中L1缓存很小一般集成在处理器芯片中。L2缓存会比L1大但也比L1慢。很多系统会有部署在CPU之外的L3缓存，尽管速度比L2慢但还是要比主内存快。
现代计算机使用多种不同的内存来确保CPU在工作的过程中始终有不同的内存来提供所需数据。在所有的存储器中最快的是CPU自身的寄存器。这些寄存器与CPU采用同样的时钟频率工作。但遗憾的是这些寄存器只能提供很小的空间而且一般成本极高。

缓存信息的查看可以通过命令x86info –c进行，而且一般缓存信息也会在dmesg文件中出现。

### Locality of reference
当应用程序所需要的数据大部分都可以通过对缓存的访问而不是对内存的访问获得，这个时候缓存的使用率是最高的。因此Cache stride就是指在一个cache line条目上所能够缓存的内存中的信息。

应用程序将会按照下面的方式访问数据。如果一个应用程序访问内存位置X那么在未来的几个循环中去获取X+1位置上的内容，这种行为叫做spatial locality of reference（立体定位），他对将磁盘中的数据以页面形式逐页移入内存的动作比较有效；而另外一种形式是temporal locality of reference（时间定位），即在一个时间周期内应用程序会周而复始地访问内存中的同一个位置。

缓存系统并不是在所有的时候都有用。一些程序员也可以开发不使用内存的应用程序。只有顺序访问内存的应用程序才会因cache而提升性能。

如果产生对新的内存位置的访问，进程需要清空当前的cache内容并重新缓存新的信息，这样将造成内存访问的延迟。但通常cache可以补偿这种延迟，不过应用程序就未必能够有这种优势。因此在一些程序中提供了其他的内存访问机制而不需要cache。

如果要查看缓存的使用情况，可以使用命令：
    # valgrind --tool=cachegrind program_name
该工具能够实现，模拟缓存使用情况；指定L1，L2以对应CPU缓存；但程序在valgrind下会比较慢。

如果要提高locality of reference，需要：
手动优化代码：确保数据结构能够被缓存；使应用程序可以循环读取同样的数据。
使用编译器的自动优化功能。
在对应用程序进行编译的时候可以通过给编译器传递一些选项来实现优化。默认情况下这些优化选项是关闭的，因为这些选项开启会导致更长的编译时间并且增加debug的复杂度。如果开启这些选项则会使编译器增加编译时间或者代码大小。
Gcc编译器支持很多优化选项。另外在x86架构上，-mcpu选项可以防止产生在其他架构上运行的代码，而-march选项会产生只在指定CPU上产生的代码，这样将降低兼容性但是能够提高性能。
在编译红帽系统软件包的时候其实已经开启了这两个选项。
 
###  Multitasking and the run queue
在Linux 2.4内核上，多个CPU之间只会使用一条运行队列，这样针对对称多处理器架构，在多个处理器之间以一个队列来分配任务，效率会比较低。和2.4内核不同的是在2.6内核上每一个CPU核心有两个运行队列：active和expired。最开始的时候，过期队列为空，当一个进程为可运行的时候，会被放到active队列中，但一个任务在active的运行队列中用尽他的时间片的时候，他会被计算一个新的优先级并被放到expired队列中去。当所有在active队列中的进程都耗尽CPU时间片的时候，内核只会将active队列变成expired队列，并将原来的expired队列变成active队列。在调度之前给进程指定不同的队列将有效减少竞争时间。


当进程被放到active queue中的时候，进程必须被标记为TASK_RUNNABLE，在active queue中的第一个进程会上CPU。队列按照优先级来存储。直到进程占先的时候才会运行。当进程占先之后也会被放到expired队列中，所以active和expired队列会在active队列为空的时候相互交换。

### 处理器中的占先：
标准的占先规则：CPU收到一个硬件中断，进程请求I/O，进程自动按照CPU的sched_yield处理，调度算法会决定哪个进程占先。
如果要查看当前的调度算法和优先级：
# chrt –p pid；# ps axo pid；# comm；# rtprio；# policy；# top
ps axo pid,comm,rtprio,policy

### Sorting the run queue
一般进程的优先级为140个，其中0为最高而139为最低；优先级0和实时优先级99相同，而优先级1和实时优先级98相同，以此类推。一般进程在启动的时候，如果没有对其优先级进行任何修改，一开始就会被指定优先级为120。在top命令中，PR字段会显示该进程的优先级（减去100）。
在2.4的Linux内核中，多个CPU共同使用一个单独的队列，因此对于对称多处理器来说，相对效率会比较低。而新的调度算法使用多个队列，在每一个CPU上内核会为其建立两个队列，一个是active队列而另外一个是expired队列。和2.4内核不同的是在2.6内核上每一个CPU核心有两个运行队列：active和expired。最开始的时候，过期队列为空，当一个进程为可运行的时候，会被放到active队列中，但一个任务在active的运行队列中用尽他的时间片的时候，他会被计算一个新的优先级并被放到expired队列中去。当所有在active队列中的进程都耗尽CPU时间片的时候，内核只会将active队列变成expired队列，并将原来的expired队列变成active队列。在调度之前给进程指定不同的队列将有效减少竞争时间。

初始进程从SCHED_OTHER开始，在进程建立的时候，每一个进程都会在一定时间带有其父进程的调度算法和优先级。

队列分类：
每个进程都可以按照一定的策略和优先级被调度。
静态优先级1-99：SCHED_FIFO和SCHED_RR
静态优先级0（动态100-139）：SCHED_OTHER和SCHED_BATCH

SCHED_FIFO：
这是最简单的策略，采用标准的占先规则；

SCHED_RR：
与SCHED_FIFO一样，但是增加了时间片，优先级越高（数字越小并接近1）则拥有越长的时间片。当时间片超时则会占先。并重新插入优先级队列之后；

SCHED_OTHER：
计算一个新的进程占先的内部优先级，范围为100-139；

通常情况下进程具有0-139个优先级，0最高而139最低。而优先级0相当于real time优先级99，而1则相当于实时优先级98并以此类推。动态进程无法通过nice去进行调整并从120开始初始化。如果使用top命令RR区域会显示进程优先级（减去100）。
这句话的实际意思是，整个进程的优先级范围是从0-139，其中0-99是real time优先级，这段real time的优先级是不能用nice和renice命令来调整的，而只能用chrt来调整。而能用nice和renice来调整的范围只能从100-120，实际的理论和书上的明显不一样，从0-139的优先级顺序一定是从高到低，不会像书上说的real time优先级从0-99之间从低到高。


在2.6的内核上，新的调度算法会产生多条队列。Linux对每一个CPU建立两个运行队列，一个活跃队列和一个过期队列。这两个队列实际上都是双数的已经链接的列表的集合，每个优先级都有自己的列表。一开始过期队列为空，当进程可运行的时候会被放到活跃队列中，当活跃队列中的任务用尽了属于他的时间片，则会针对他计算出一个新的优先级，并且该优先级会被放到过期队列中属于该优先级的链接列表中。当活跃列表中所有的进程用尽了他们的时间片，kernel会采用一种简单的方法就是将活跃队列变成过期队列而使旧的过期列表变成新的活跃队列。为每一个处理器指定单独的队列可以有效减少队列争用的情况。

### SCHED_OTHER
• Priority may vary
• Processes with equal priority can preempt current process every 20ms to prevent CPU starvation
• CPU bound processes receive a +5 priority penalty after preemption
• Interactive tasks spend time waiting for IO
• Scheduler tracks time spent waiting for IO for each process and calculates a sleep average
• High sleep average indicates interactive process
• Interactive processes may be re-inserted into the active queue
• If not, receive a -5 priority boost and move to expired queue

拥有相同优先级的进程会在每20ms的时候尝试使该进程占先以防止CPU出现starvation的情况，而CPU会在进程占先之后对其优先级加5作为惩罚；
交互式的任务将在等待I/O上占用时间：
调度器会检查每一个进程在等待I/O上所使用的时间并为其计算一个平均睡眠频率；较高的睡眠频率意味着是交互式的进程；交互式的进程会被重新插入到active队列，如果没有被插入active队列，其优先级则会在-5之后被移动到过期队列中；

Processes scheduled with SCHED_OTHER are said to have dynamic priority: their priority will vary over the life of
the process according to adjustments made by either the kernel or a user.
The initial priority for a dynamic process is determined by its nice value (default 0). The nice value for a process can
be set using either the nice or renice commands. This is added to the initial internal default priority of 120. Therefore
a processed launched with a nice value of +19 would get added to the run queue with an internal priority of 139.
The scheduler is designed to favor interactive processes by giving them a small priority boost. The scheduler tracks
the proportion of time a process spends sleeping to the proportion of time spent running and calculates a sleep
average. The assumption is that processes that have a high sleep average are interactive and therefore need to be more
responsive so the scheduler gives these processes a -5 priority boost. Processes which spend most of their time running
are penalized with a +5 priority decrease. The scheduler will also give a priority boost to processes that wake up other
processes, such as the X window server.

调度算法SCHED_OTHER会使进程拥有动态的优先级，其优先级完全取决于kernel和用户对其所进行的调整。开始的时候进程的优先级由nice值（通常为0）决定。同时该值可以通过命令nice和renice来指定。对于内部默认进程其优先级是120，因此一个进程在开启的时候会对其增加19，这样那个进程的优先级就是139。交互式的任务将花费时间等待I/O，因此调度器将检查每一个进程等待I/O的时间并计算出一个平均睡眠时间。如果平均睡眠时间比较高，则证明进程将插入活跃队列，否则会将优先级-5并将其移动到过期队列以进行优化。
如果使用的拥有相同优先级的进程会在每20ms之后尝试占先以防止CPU空闲。在占先动作之后CPU会对该进程的优先级+5。
对列调度器的调整策略：
针对SCHED_FIFO，使用chrt –f [1-99] /path/to/prog arguments
针对SCHED_RR，使用chrt –r [1-99] /path/to/prog arguments
针对SCHED_OTHER，使用nice和renice来调整

### Tuning scheduler policy
• SCHED_FIFO
chrt -f [1-99] /path/to/prog arguments
• SCHED_RR
chrt -r [1-99] /path/to/prog arguments
• SCHED_OTHER
nice
renice

See sched_setscheduler(2) for more details on SCHED_FIFO and SCHED_RR.
See chrt(1) for command-line options. In particular, note that options precede arguments with this command. For
example, to set the init process to run with SCHED_RR at priority 99, you would execute:
chrt -p -r 99 1
schedtool is another utility for tuning the process scheduler, but this tool is available in MRG and some versions of
Fedora.

 ### Viewing CPU performance data
• Load average: average length of run queues
• Considers only tasks in TASK_RUNNABLE and TASK_UNINTERRUPTABLE
sar -q 1 2
top
w
uptime
• CPU utilization
mpstat 1 2
sar -P ALL 1 2
iostat -c 1 2
/proc/stat

Several commands, such as top, uptime and w, return a trio of numbers referred to as the system load average. This
system load average is a measure of the number of processes that are in either the TASK_RUNNABLE state or the
TASK_UNINTERRUPTIBLE state. TASK_RUNNABLE processes are in run queue and may or may not currently
have the CPU, TASK_UNINTERRUPTIBLE processes are waiting for IO. The load averages are time-dependent
averages, that is, they are a measure of the number of processes that are runnable over a given period of time, in this
case, the averages are taken over a period of 1, 5 and 15 minutes. The sar utility can be used to obtain the 1 and 5
minute values for the system load average.
There is no set value for the load average value that indicates that a given system is overloaded. In general though, the
higher the values, the more likely it is that the system is CPU bound. The longer CPU bound processes run, the higher
the load average will be because the process will either be running, in the run queue waiting their turn on the CPU, or
waiting for their IO requests to be serviced. Given a steady state condition, the three values for the load average will
eventually converge.
/proc/stat contains information about key aspects of the operating system. The first line contains information about
the amount of time, in jiffies, all CPU's on the system have spent in various modes. The values on this line are the
totals for all of the processors on the system. This line is followed by a line for each processor on the system with the
number of jiffies that that specific processor has spent in each mode. For each CPU, /proc/stat also shows the
following counts:
It is also possible to view CPU utilization data for specific threads by using the ps command:
ps -Amo user,pid,tid,psr,pcpu,pri,vsz,rss,stat,time,comm

查看CPU性能方面数据的方法：
查看平均负载：运行队列的平均长度
需要考虑在TASK_RUNNABLE和TASK_UNINTERRUPTABLE这两个数值，使用命令：
    # sar –q 1 2 			查看队列以及load average；
    # top
    # w					
    # uptime
    而CPU使用率：
    # mpstat 1 2 			查看每秒中断数；
    # sar –P ALL 1 2 		
    # iostat –c 1 2 
    # /proc/stat
 
### 内核时钟和进程延迟
在x86架构的服务器上，硬件时钟通常有下面的几种：
实时时钟RTC：
主要用于在系统关机的时候维持时间和日期信息并可在开启的时候利用该时间设置系统时间。
其信息在/proc/driver/rtc中。

时间戳时钟：
这是一个寄存器，该寄存器会以和CPU晶振相同的频率更新。其主要功能是提供高层计数器用于和RTC一起计算时间和日期信息

高级可编程中断控制器：
APIC包括了本地CPU计时器，该计时器用于跟踪运行在CPU上的进程并使该进程从本地CPU到多CPU过程中产生中断

可编程中断计数器PIC：
可用内核中所有通用的始终保留动作，包括进程调度等


在x86架构的系统上，Linux使用PIC作为处理中断的计数器在固定的周期内产生中断。在RHEL3以及更早的使用2.4内核的系统中，频率为100Hz，这就意味着在每10ms产生一个节拍。在RHEL4以及2.6 Linux内核版本的系统上频率提高到1000Hz，意味着每1ms产生一个节拍。但实际上这个产生节拍的频率是可调的，尽管在内核编译的时候已经预定义好。我们通过在启动选项中增加内核参数来实现。更短的tick对于一些对时间比较敏感以及一些多媒体程序来说是有利的，但也可能使一些应用程序运行得比较慢，因为内核需要更多的资源来处理产生的大量中断。
 
### 调整系统节拍数
通过调整系统启动的内核参数来实现对系统tick数的指定：
参数是：tick_divider = value
其中：
2 = 500 Hz
4 = 250 Hz
5 = 200 Hz
8 = 125 Hz
10 = 100 Hz
但需要注意的是这些参数只对X86架构有效，对于XEN内核无效。

在RHEL5U3以上支持通过内核参数来调整节拍数。半虚拟化使用内嵌于硬件的tick divider，即tick divider是从其hypervisor来，因此上述参数对其无效。
使用tick_divider参数在x86_64系统上可能无效，在2.6.18-63.1.2上加入了fix。而在x86_64架构上，这个fix可能导致VMware ESX服务器产生问题。有时候由于不是所有的时钟被正确地divided，所以如果在配置了divider=10的时候，需要更多的中断。

### 调整进程速度
一般情况下进程速度由cpuspeed服务来自动调整，该服务不能在Xen内核中使用。可以通过修改/etc/sysconfig/cpuspeed文件手动定制。调整该文件之后会影响一些电源管理的功能，对笔记本的影响可能会更大一些。

The cpuspeed daemon can be useful for laptops. This daemon lowers the processor clock speed during idle periods to
help conserve battery power. Various options can be set to adjust the criteria used by cpuspeed to decide when to alter
the clock speed. Permanent options can be specified in /etc/sysconfig/cpuspeed.
You can obtain more information on cpuspeed by typing:
cpuspeed --help 2>&1 | less
If the system uses a clock tied to the CPU frequency, such as the TSC, then the cpuspeed daemon may interfere with
timekeeping functions. This can be particularly problematic on 64-bit systems.
Useful files:
/sys/devices/system/cpu/cpu*/cpufreq/scaling_available_frequencies
/sys/devices/system/cpu/cpu*/cpufreq/scaling_available_governors

一般情况下cpuspeed这个服务可能对笔记本会更加有用一些，因为该进程的启动可以通过降低处理器的时钟速度来起到节电的作用。可以通过修改/etc/sysconfig/cpuspeed来重新定制相关参数。
    # cpuspeed –help 2>&1 | less
如果系统使用和CPU频率关系比较密切的时钟源，如TSC。那么cpuspeed进程可能会影响timekeeping功能。在64bit系统上的影响可能会比较多。常用的文件包括：
/sys/devices/system/cpu/cpu*/cpufreq/scaling_available_frequencies
/sys/devices/system/cpu/cpu*/cpufreq/scaling_available_governors

### IRQ中断平衡
• Hard interrupt preempts current process
• Contributes to latency
• View activity
procinfo
cat /proc/interrupts
• irqbalance
• Requires a functional APIC for IRQ routing
• May move IRQs every 10 seconds
• Consequences
• Interrupt handlers exploit cache affinity for CPUs
• Equalize CPU visit count

A benefit of the design of the Linux 2.6 scheduler is that certain kernel processes can be preempted and scheduled
just like other processes. This can result in lower latencies for time critical tasks such as processing network IO.
For example, the kernel can be running a handler to perform disk IO for a user mode process and it may receive an
interrupt from a network card. The handler that is performing the disk IO can be preempted in favor of the interrupt
handler for the network card resulting in improved latency for network packets.
The kernel compile-time options can be viewed as follows:
grep PREEMPT /boot/config-2.6.18-53.el5
# CONFIG_PREEMPT_NONE is not set
CONFIG_PREEMPT_VOLUNTARY=y
# CONFIG_PREEMPT is not set
CONFIG_PREEMPT_BKL=y
Booting with the noapic kernel parameter prevents irqbalance from routing IRQs. If IRQs are unevenly distributed
across the CPUs, the result can be the perception of sporadic performance inconsistencies when the interrupt handlers
preempt whichever process is on the CPU.

在2.6版本的Linux内核调度器中一个比较出色的设计是一些内核集成可以像其他进程那样被占先和调度。这样对于一些要求低延迟的任务，如处理网络I/O的任务来说，来说是有好处的。例如内核可以运行一个handler并对用户态进程执行disk I/O，并且从网卡接收中断。
通过/proc/interrupts中，可以查看当前哪个CPU在负责哪个中断。CPU是需要处理中断的，IRQ balance是RHEL5中的一个服务，主要用于平衡在不同CPU上的中断数量。如果一直让一个CPU处理中断，感觉该CPU会非常繁忙。所以一般每10s，IRQ会被均衡一次。

但需要注意的是，如果在系统启动的时候加入了noapic参数，irqbalance将被禁止。
 
### Tuning IRQ affinity
• Tune irqbalance
• Configure for "one-shot" in /etc/sysconfig/irqbalance
• Disable irqbalance
1. chkconfig irqbalance off
2. Set smp_affinity for every IRQ in /etc/rc.local
echo cpu_mask > /proc/irq/<interrupt_number>/smp_affinity
• Consequence
• Shield critical CPUs from servicing IRQs
• Exploit cache affinity for interrupt handlers
对IRQ亲和度的调整包括：
修改/etc/sysconfig/irqbalance，加入”one-shot”参数，表示开机之后只进行一次IRQ中断平衡，之后再不进行中断平衡。如果要关闭irqbalance功能，可以选择chkconfig off这个服务。
或者通过下面的命令将irq中断固定在某个CPU上。

Pinning an IRQ handler to a CPU can enhance performance by exploiting cache affinity, resulting in lower service
time for the handler when it is placed at the head of the active run queue.
smp_affinity should be a bitmask expressed in hexadecimal representing valid CPUs. To assign an IRQ to the
first CPU:
echo 1 > /proc/irq/<interrupt_number>/smp_affinity
The kernel should be compiled with support for IRQ balancing:
grep -i irqbalance /boot/config-*
IRQ affinity is sometimes referred to as IRQ shielding. This emphasize the goal of shielding the CPU from handling
IRQ code. The IRQ is not shielded; it is the CPU that is shielded.
The kernel-doc package contains additional information in Documentation/IRQ-affinity.txt and
Documentation/IRQ.txt.

对IRQ亲和度的调整：
在执行
echo cpu_mask > /proc/irq/<interrupt_number>/smp_affinity
命令的时候，如果echo的是0则表示第一个CPU，1表示第二个CPU，3表示前两个CPU。
好处是，让关键的CPU避免做IRQ服务，而腾出工作时间让其专门处理进程。
CPU_MASK是二进制的表示方法。

 
### Equalizing CPU visit count
• Process moves to the expired queue when preempted
• Imposes a built-in affinity for the CPU
• Can lead to unbalanced run queues
• Scheduler rebalances run queues
• Every 100 ms if all processors are busy
• Every 1 ms if a CPU is idle
• View a specific process
watch -n.5 'ps axo comm,pid,psr | grep program_name'
• Consequences
• Lower visit count leads to higher throughput
• Moving a task to another CPU guarantees a cache miss

Each physical CPU on a multiprocessor system has its own run queue. For hyperthreaded processors, the logical
processor uses the same run queue as the physical processor. When a process uses up its timeslice on a particular CPU,
it is normally scheduled into the expired array for the same CPU on which it was running. Therefore, processes have
a natural processor affinity; they tend to remain on the same processor rather than being rescheduled to run on other
processors on the system. Normally, this is a desirable behavior. Each CPU has its own cache therefore the chances are
quite good that when a process gets its next timeslice, some of the data that it needs will still be in cache. If processes
constantly bounced from processor to processor, performance would suffer due to the need to constantly refill the
cache lines on the new CPU with data for the process.
One problem that arises from having separate run queues for each CPU on a multi-processor system is that there is
a potential for the run queues to become unbalanced. For example, one CPU on a dual processor system might wind
up with five active processes while the other CPU only has a single process. This would result in the process on the
lightly loaded CPU monopolizing half of the processing capacity of the system while the other half of the processing
capacity of the system was divided among the other five active processes. To prevent this, the scheduler will rebalance
the run queues every 100 ms. If the scheduler detects an idle processor, it will check the run queues for the other CPUs
every 1 ms looking for jobs that can be rescheduled to the idle processor.
The ps axo comm,psr command reveals which processor is running the command (program).

当一个进程被抢占（占先）之后会被移到过期队列中。当计算机运行到一定程度，可能会出现某些CPU很繁忙，而某些CPU很空闲。所以一般当所有CPU都很忙，则每100ms做一次balance，而当有一个CPU很闲，则每1s做一次balance。一般我们通过ps的psr参数知道，哪些进程运行在哪些CPU上。
总之所有的原则是，在系统运行过程当中，即让所有的任务在不同的CPU之间分散。

但分散任务会产生问题，即分散不同的任务，会导致重新cache，所以在多核心CPU的结构上一般会使用共享cache。而且在NUMA环境下，均分任务还是有好处的。

在对称多处理器架构中，每个物理CPU都有自己的运行队列。对于超线程的CPU来说，逻辑处理器使用和物理CPU一样的运行队列。当一个进程在CPU上使用完所有的时间片，则会被移动到该CPU的过期队列中。因此CPU都有一个默认的进程亲和性，即更倾向于将进程运行在某个CPU而不是其他CPU上。而且因为每个CPU都有自己的cache，所以进程运行在原来的CPU上，一旦该进程重新获得CPU的时间片就不需要重新对缓存进行初始化。否则当进程在不同的CPU之间移动的时候，会因为重新初始化缓存而对性能造成影响。
当然在这种情况下，如前所述，平衡CPU访问量的工作会默认进行。
 
### 使用taskset命令来平衡进程的亲和度：
主要的目的是将一个或者多个进程指定到固定的CPU上。例如：taskset –p 0x00001 1
这样操作的目的：
提高缓存命中率，减少等待时间，对于NUMA架构防止非本地内存的访问；

Processor affinity can be set or viewed using the taskset command. The affinity for a given process is represented
as a bitmask with the lowest order bit corresponding to the first logical CPU on the system and the highest order bit
corresponding to the last logical CPU. Below are some example bitmaps:
0x00000001 CPU #0
0x00000002 CPU #1
0x00000003 CPU#0 and CPU#1
0xFFFFFFFF all processors
As an alternate to using a bitmask to indicate which processors to assign a process to, a numerical list can be specified
using the -c or --cpu-list option.
Fedora has introduced schedtool, a command that combines the functionality of chrt and taskset. This command is
not currently included in RHEL but may be added in future releases.

命令taskset的语法：
    # taskset –p CPU_MASK 进程号

NUMA架构中，内存和CPU是分片的。NUMA会倾向于访问和CPU接近的内存。
例如：
    # taskset -p 0x00000002 27865
pid 27865's current affinity mask: 3
pid 27865's new affinity mask: 2

在Fedora中有一个叫做schedtool的工具，集合了chrt和taskset的功能，但是在RHEL中暂不支持。

### Tuning run queue length with taskset
• Restrict length of a CPU run queue
1. Isolate a CPU from automatic scheduling in /etc/grub.conf
isolcpus=cpu number,...,cpu number
2. Pin tasks to that CPU with taskset
3. Consider adjusting IRQ affinity
• Consequences
• Shorter run queue and wait time for pinned tasks
• Higher visit count for other CPUs

通过taskset来调整运行队列长度：
可以通过在grub中加启动参数来使得某个CPU在开机之后不被使用，除非使用taskset将某个进程指定到该CPU上。因此该功能一般和taskset联合使用，主要用于将一些关键业务或者严禁中断的功能固定指定到某个CPU上。

Restricting length of the run queue is an aggressive action for applications that need a somewhat deterministic wait
time. Applications that need real-time responsiveness may benefit from this technique. Be aware that you must have
multiple CPUs to exercise this option.
The isolcpus boot parameter is documented in /usr/share/doc/kernel-doc-*/Documentation/
kernel-parameters.txt.
Example entry in grub.conf to isolate the first CPU from automatic scheduling:
title Red Hat Enterprise Linux Server (Isolated CPU)
root (hd0,0)
kernel /vmlinuz-version ro root=LABEL=root rhgb quiet isolcpus=0
initrd /initrd-version.img
The drawback to using taskset to control process latency is that it fails to easily scale to multiple, different workloads
on a single machine. Scaling can be done, but it can be a tedious process.

### Hot-plugging CPUs
• Logical, run-time changes supported by cpu-hotplug
1. Determine processor number
grep processor /proc/cpuinfo
cat /proc/interrupts
2. Dynamically disable CPU 1
echo 0 > /sys/devices/system/cpu/cpu1/online
cat /proc/interrupts
3. Re-enable CPU 1
echo 1 > /sys/devices/system/cpu/cpu1/replaceable>/online
cat /proc/interrupts
• Physical hot-plug requires BIOS support
• Some CPUs cannot be disabled (e.g., the boot CPU)
• Can be useful for NUMA systems
• Kernel updates /proc/cpuinfo and other files dynamically
• See kernel-doc-*/Documentation/cpu-hotplug.txt

实现基于软件的CPU热插拔：
热拔某个CPU：
echo 0 > /sys/devices/system/cpu/cpu1/online
cat /proc/interrupts
热插某个CPU：
echo 1 > /sys/devices/system/cpu/cpu1/online
cat /proc/interrupts
而基于硬件的CPU热插拔需要BIOS的支持，多用在NUMA架构上。该功能在RHEL5中实现。

Red Hat Enterprise Linux 5 supports the cpu-hotplug mechanism, which allows for CPUs to be dynamically disabled
and re-enabled on a system without requiring a system reboot.
Current architectures that support cpu-hotplug include i386, ppc, ppc64, ia64, and x86_64. This requires kernel
compile-time options as recorded in /boot/config-*:
CONFIG_HOTPLUG
CONFIG_SMP
CONFIG_HOTPLUG_CPU
CONFIG_ACPI_HOTPLUG_CPU
This mechanism enables additional kernel boot parameters: maxcpus, additional_cpus, and
possible_cpus. However, the parameters vary by architecture. See the kernel-doc for more detail.
If a CPU cannot be dynamically plugged, its /sys/devices/system/cpu/cpuX/online will not be present.
For example, some systems use CPU0 to initialize other hardware components. Note: unmapping a CPU dynamically
makes it unavailable for any activity, including IRQ processing. By contrast, the isolcpus directive merely removes
the CPU from dynamic process scheduling.
 
### Scheduler domains
• Group processors into cpusets			将不同的进程分散到不同的cpuset
• Each cpuset represents a scheduler domain		每一个cpuset表示一个调度域；
• Supports both multi-core and NUMA architectures		支持多核和NUMA架构；
• Simple management interface through the cpuset virtual file system	基于cupset文件系统实现
• Combine with other tuning techniques	与其他的调试技术一起使用；
• Nestable hierarchy of cpusets		层次化的cpuset
• Root cpuset contains all system resources		根cpuset包含了所有系统资源；
• Child cpusets can be nested			子cpuset可以被管理；
• Each cpuset must contain at least one CPU and one memory zone	
每一个cpuset必须包含至少一个CPU和一个内存域；
• Dynamically attach tasks to a cpuset		动态将任务加到cpuset当中；
• Consequences
• Control latency due to queue length, cache, and NUMA zones
• Assign processes with different CPU characteristics to different cpusets
• Scalable for complex performance scenarios

主要的目的是将多个CPU分成不同的组，然后每个组的CPU分别执行不同的任务。这里所提及的组也叫做CPUSET，或者调度域。
每一个调度域通过一个虚拟的文件系统来实现。调度域支持相互嵌套和混合使用，即同一个CPU可以在不同的调度域中。

Scheduler domains are implemented via cpusets. Each cpuset constitutes a scheduler domain in which the scheduler
balances tasks. After grouping one or more CPUs into a cpuset and then assigning one or more tasks to that cpuset, the
scheduler restricts task scheduling of those tasks to the cpuset.
In other words, assigned tasks run only within their cpuset. This provides a flexible, elegant, and scalable technique
to control run queue length and therefore task latency. Additionally, the implementation uses very little additional
kernel code and has no extra impact on the process scheduler. It uses a new virtual file system without introducing
new system calls. Existing system calls, such as sched_setaffinity(2), continue to work transparently within scheduler
domains. Use the following command to ensure that the kernel supports cpusets:
grep -i cpuset /proc/filesystems /boot/config-*
The cpuset VFS can be mounted almost anywhere. This course assumes that it will be mounted at /cpusets.
This root VFS constitutes a root cpuset that includes all CPU cores and memory on the system. You can create
subdirectories within this VFS, and each subdirectory creates a new cpuset to which resources can be assigned. This is
a strict hierarchical ordering. A CPU can belong to multiple cpusets, but only if the CPU is in its parent cpuset:
/cpusets (4 CPUs)
|
/ \
/cpusets/set1: CPUs 0-2   /cpusets/set2: CPUs 1,3
| 					|
/cpusets/set3: CPU 1 	     /cpusets/set4: CPU 3

### Configuring the root cpuset
1. Update SELinux policy
• selinux-policy-targeted-2.4.6-106.el5_1.3 or later
2. Mount the root cpuset (persist in /etc/fstab)
mkdir /cpusets
grep cpu /proc/filesystems
mount -t cpuset nodev /cpusets
• Root cpuset contains all system resources by default
/cpusets/cpus
/cpusets/mems
/cpusets/tasks

The root cpuset is automatically created when the VFS is mounted. Technically, the VFS can be mounted nearly
anywhere. However, /dev/cpusets requires a udev rule to ensure the mountpoint is created at boot-time. A rootlevel mountpoint of /cpusets is consistent with other virtual filesystems, such as /selinux, /proc, and /sys. Mounting the cpuset filesystem automatically creates a root cpuset and assigns all CPUs as well as all existing PIDs to the cpuset. When a process forks, its children inherit the cpuset assignment. On a dual-core Intel platform:
cat /cpusets/cpus
0-1
cat /cpusets/mems
0
cat /cpusets/tasks | sort -n
1
..
32456
The SELinux policy prior to release 106 lacked the cpusetfs_t type and associated rules, thereby causing cpusets
to be unlabeled_t and unusable under SELinux. Updates from RHN or server1 fix this:
ls -lZd /cpusets
-rw-r--r-- root root system_u:object_r:cpusetfs_t /cpusets/

当VFS被挂载的时候，根cpuset被自动建立，当然VFS一定会被挂载。但是/dev/cpusets需要udev规则来确保挂载点在开机的时候被建立，此时会建立一个叫做/cpusets的文件系统，和root文件系统一样。当挂载cpuset文件系统的时候，所有的CPU和所有的PID都会被指派到该文件系统中。

### Configuring a child cpuset
1. Create a subdirectory of an existing cpuset
mkdir /cpusets/rh442
2. Assign resources as a range or comma-separated list
/bin/echo 0 > /cpusets/rh442/cpus
/bin/echo 0 > /cpusets/rh442/mems
3. Attach one task at a time
for PID in $(pidof sshd); do
/bin/echo $PID > /cpusets/rh442/tasks
done
5.	Persist in /etc/rc.local
建立子CPUSET的步骤：
1.	在cpusets目录下建立一个自定义目录，在该自定义目录中会自动建立相关系统文件；
2.	指派CPU资源到该子目录中，资源指CPU号；
3.	将某些进程附加到该CPUSET上；
4.	如果要使永久生效，更改/etc/rc.local；

Simply create a subdirectory within the cpuset VFS to create a child scheduler domain. The kernel creates the
necessary files automatically, and naming of child cpusets is arbitrary.
Each cpuset (scheduler domain) must contain at least one processor and one memory zone. For uniform memory
architectures such as the x86, there is only one memory zone (0). For NUMA architectures, there may be multiple
zones. To determine which zones are available on your system:
cat /cpusets/mems
A child cpuset can include only those processors or memory zones that belong to the parent. Be default, child cpusets
do not contain processors or memory zones. You must set these deliberately. For example, to assign processors 0 and 3
(two processors), you could use the following command:
/bin/echo "0,3" > /cpusets/rh442/cpus
To assign processors 0 through 3 (four processors), you could do the following:
/bin/echo "0-3" > /cpusets/rh442/cpus
Additionally, cpusets do not persist across reboots, so you need to establish your configuration via /etc/rc.local
or a custom SysV-style init script. See /usr/share/doc/initscripts-*/sysvinitfiles for a sample
template.
If you fail to assign at least one CPU and at least one memory zone to the cpuset, then any attempt to assign a task
(PID) to the cpuset will fail with "no space left on device".
To remove a task from its cpuset, simply attach the PID to another cpuset, such as the root cpuset. You can remove a
cpuset by removing its subdirectory, but you must first move all tasks out of its scheduler domain.

基本步骤：
在cpuset目录下建立一个子文件夹，即子调度域。内核会自动在其中建立相应的文件，子调度域的名称可以任意建立。每一个cpuset（调度域）必须包含至少一个CPU和一个内存域（0），对于NUMA架构，可能会有多个内存域，而在x86架构上一般只有一个内存域（0）。通过命令查看当前的内存域：
    # cat /cpusets/mems
子CPUSET包含的CPU域和内存域来自于其父。默认情况下，子CPUSET不包含CPU或者内存域。你必须单独设置他们。例如，要将CPU0和3指派到该CPUSET中，使用下面的命令：
/bin/echo "0,3" > /cpusets/rh442/cpus
而如果将CPU0到3指派到CPUSET中，使用命令：
/bin/echo "0-3" > /cpusets/rh442/cpus
需要注意的是，CPUSET的指定在下次重启系统的时候失效，所以想永久保存，必须将其写入到/etc/rc.local文件中。
如果要从CPUSET中删除某个进程，只需要将进程按照上述步骤指派到其他的CPUSET中就行。你可以删除一个自定义的CPUSET，但是必须将该CPUSET中的所有进程移动到其他的CPUSET。

 ### Important files for scheduler domains
• To which cpuset is the PID attached?
/proc/PID/cpuset
• To which resources can the PID be scheduled?
cat /proc/PID/status | grep allowed
• Can this CPU belong to multiple, non-nested cpusets?
/cpusets/rh442/cpu_exclusive
• Enable automatic cleanup
/cpusets/rh442/notify_on_release

调度域中的重要文件：
查看某个进程附加到哪个CPU域：/proc/pid/cpuset
查看进程可以在使用哪个CPU的资源：/proc/pid/status | grep allowed
表示某个cpu只被限定在某个cpuset中使用：/cpusets/rh442/cpu_exclusive
表示如果cpuset空了，则自动将子目录remove掉

To quickly figure out to which domain sshd has been assigned, use the following commands (but be careful that you
have only one sshd process running):
cat /proc/$(pidof sshd)/cpuset
/rh442
cat /proc/$(pidof sshd)/status | grep allowed
Cpus_allowed: 00000001
Mems_allowed: 1
If cpu_exclusive contains 1, then the processors in this scheduler domain may be assigned only to this domain or
its parents. A child in another hierarchy cannot use these processors.
To automatically clean up your scheduler domains, you can create a script at /sbin/cpuset_release_agent
and write or echo a 1 into notify_on_release. When the last PID is removed from that cpuset, the kernel
executes /sbin/cpuset_release_agent with the relative pathname of the cpuset as the first positional
argument. For example, the rh442 demo cpuset might be triggered as:
/sbin/cpuset_release_agent /rh442
It is your script's responsibility to test $1 and take appropriate actions.
 
### Virtual CPUs
• Can assign more VCPUs than there are physical CPUs
• Test applications in SMP environment
• Virtual run queues compete for physical CPUs
• All domains have equal access to CPU time by default
• Tune VCPUs both statically and dynamically from dom0
• Dedicate real CPU resources to critical domains
• Reduce latency for critical domains
• Provide domains different proportions of real CPU cycles

对于虚拟机而言，可以指定比物理CPU更多的虚拟CPU：
测试程序运行在SMP环境中；虚拟队列完成再物理CPU上；所有的domain默认情况下都有相同的对CPU的访问时间；

Each domain is assigned a certain number of virtual CPUs (VCPUs) when the domain is created. The VCPUs are
scheduled to run on real CPUs on the system by the hypervisor. By default, all domains have equal access to real CPU
time.
It is possible to configure a domain so that it has more VCPUs than there are actual CPUs on the system. However, for
reasons which should be obvious this will generally have a negative effect on domain performance. It is also possible
to force a domain to start on a certain real CPU and only allow it to run on certain real CPUs.

每一个域都可以被指派一定数量的虚拟CPU。虚拟CPU由hypervisor调度运行在真实的CPU上。默认情况下所有的域都有相同的CPU访问时间。
需要注意的是，尽管可以配置比物理CPU数量更多的虚拟CPU，但是如果这样操作会对性能产生很大的影响。同时也可以通过配置强制某些域运行在一些真实CPU上，并只允许其运行在某些CPU上。

### Tuning VCPUs at domain creation
• Static configuration in /etc/xen/domain
• Maximum and starting number of VCPUs	配置使用的vcpu的数量
vcpus=4
• Which physical CPU on which to boot	配置虚拟机运行在某个CPU上
cpu=0	
• Allowed physical CPUs for run queue balancing	
配置某些物理CPU之间进行队列负载平衡
cpus=0,2-4

Note that the Xen kernel does not distinguish between physical cores, dual cores on the same CPU socket, or
hyperthreads. Normally, Xen will search for CPUs "depth-first": first hyperthreads, then cores on the same socket,
then cores on separate sockets. So on a dual-core HT CPU, CPUs 0 and 1 might be the hyperthreads on the first core,
with CPUs 2 and 3 the hyperthreads on the second core.

### Tuning VCPUs dynamically
• Number of VCPUs cannot exceed the initial number from config
• From the command-line
virsh setvcpus domain number-of-VCPUs	命令行指定虚拟机运行在某些CPU上
• From virt-manager GUI	也可以通过GUI来指定
1. Right-click the domain and select details
2. Click the Hardware tab
3. Select Processor
• Note: paravirtual domains only	需要注意，只对半虚拟化有效
动态配置虚拟CPU：
The number of VCPUs available to a given domain can be raised or lowered "on the fly", while the domain is running.
However, the number of VCPUs cannot dynamically be raised above the number that a domain had when started.

### Tuning VCPU affinity
• Pin VCPUs to physical CPUs
virsh vcpupin domain|domID VCPU CPU,...
• Consequences
• Improve cache hits (lower service time) for domU
• Assign resources independently
• Control queue length (and therefore latency)

Normally, each virtual CPU in a domU may use cycles from all physical CPUs. The Hypervisor schedules CPU time
as needed for each domU. This also means that all domains (including dom0) are competing for the same pool of CPU
time. In some instances it may be necessary to change this behavior.
Also known as setting CPU affinity, CPU pinning allows a domU to be restricted so that it only uses one or more
designated physical CPUs. Further, each virtual CPU in a domU is independently pinned, offering flexibility. CPU
pinning may be set with either xm or virsh.
To lock the virtual CPU of domU webserver to use only the second CPU (CPU number 1), use the following
command:
[root@stationX]# virsh vcpupin webserver 0 1


上述命令可以针对虚拟机webserver将虚拟CPU 0指定到物理CPU上。

默认情况下，每一个Domain U中的虚拟CPU使用物理CPU的时钟周期。Hypervisor会按照DomainU的需求调度CPU时间。这也就意味着所有的domain，包括domain0会竞争CPU时间。所以为了提高虚拟机的性能，可能需要改变这种情况。
由于我们已经知道了CPU的亲和性，所以指定某些物理CPU运行专门的虚拟机。而且，每一个DomainU中的虚拟CPU被隔离开来。
 

###  SystemTap
• Can profile
• Any system call exposed by the kprobes subsystem
• Captures 100% of events
• Compiles a script into a kernel module
• Scripting language is similar to awk in style
• Scripts are highly portable
• Production machines usually do not have compilers
• On development machine: compile script into kernel module
• On production machines: deploy kernel module
• Ensure consistent kernel releases on devel and prod
modinfo modulename | grep vermagic

任何由kprobes在系统所产生的系统调用以及100%的CPU事件都可以被SystemTap进行profile。
主要通过将一个脚本编译到内核模块中，该脚本语言类似awk，并且非常便携。而在生产系统中通常没有编译器。所以在开发服务器上需要将脚本编译到内核模块中，在生产服务器上部署该内核模块，确保完整的内核release信息在开发和生产服务器上。

Historically, gathering information about the Linux kernel at runtime has been a highly complex task typically
requiring deep knowledge about kernel internals. Tools such as OProfile and LTT (Linux Trace Toolkit) have been
created for that purpose and usually relied on sampling mechanisms in order to determine what the Linux kernel was
doing; every 1 ms, for instance, a reading was taken and saved into a file for later examination.
SystemTap was developed as a tool that would allow system administrators, who are not usually familiar with kernel
internals, to gain a better knowledge about what the kernel executes on behalf of applications. Complexity is therefore
greatly reduced.
As opposed to other mechanisms which rely on sampling at specific intervals of time, which suffers from an obvious
lack of precision, SystemTap provides 100% reliable information about the running kernel.That means that all kernel
events, no matter how long they take to execute, end up being monitored. This is a big improvement compared to a
tool such as OProfile.
SystemTap was implemented on top of kprobes, a kernel subsystem that allows developers to attach code to any
kernel function through the use of a kernel module. Using kprobes requires kernel development experience and skills.
This is the reason why kprobes is entirely transparent from SystemTap's user interface.

曾经从实时运行中的内核中收集信息是一个非常复杂的工作，并且需要具备丰富的内核方面的知识。因此如Oprofile和LTT这样的工具就被开发出来用于探测Linux内核所执行的工作。探测会以一定的频率进行，并且会将结果保存到相关文件当中。
SystemTap则是处于这种目的被开发出来以方便对内核没有深入了解的系统管理员获得内核运行方面的信息。如内核当前在运行什么样的应用程序等，因此相关工作则被大大简化。
和其他的工具相比，SystemTap拥有显著的特点，即可以百分百准确地提供内核运行的信息，探测的精度得到了显著提高。这就意味着所有的内核事件，不管执行事件是多长，在何时结束都将被获得和监测到。这也是SystemTap优于Oprofile的地方。
SystemTap运行于kprobes的基础上，kprobes是内核的一个子系统，该子系统方便开发者通过内核模块将代码附加到任何的内核功能上。使用kprobes需要内核开发知识和技巧。因此这也是为什么kprobes完全从SystemTap的用户接口上透明的原因。

Systemtap完善了oprofile的所有缺点，他使用了kprobes这个kernel子系统。通过脚本式的方式来协助我们做性能评估。通过systemtap，我们可以书写一个模块加载到kernel中实现性能评估，任何事件都不会被遗漏，因为是基于函数调用，只要有事件发生就可以捕获。可将书写的stap脚本编译为kernel模块并插入到kernel中。

一般systemtap有两类，一种是生产环境，一种是开发环境。在开发环境需要脚本，在开发环境中编译好脚本为模块之后，在生产环境就可以启用该模块。前提是两边的版本号必须相等。

### Required packages

• On the development machine
• systemtap
• kernel-debuginfo (must match running kernel)
• kernel-devel (must match running kernel)
• gcc
• On the production machine
• systemtap-runtime

Note: Outside of class, you can obtain debuginfo versions of the Red Hat Enterprise Linux kernel by enabling /etc/
yum.repos.d/rhel-debuginfo.repo.

 ### SystemTap scripts
• Scripts use dotted notation and support wildcards
probe kernel.function("foo")
probe kernel.function("*").return
任何时候只要有人调用foo函数，则会被捕获到，并针对该事件做一些处理。在Linux下任何时候只要有函数存在kernel就会知道。整个Linux的kernel都是基于函数调用。由于函数中有功能叫做return，所以返回的时候会被捕获到。
• See /usr/share/doc/systemtap-*/examples
SystemTap使用的脚本以点编辑并支持通配符；



• Includable functions
/usr/share/systemtap/tapset  这些是已经写好的systemtap脚本；
• man -k systemtap
• Commonly used probe points are exposed to all SystemTap scripts
• Probing points related to the IO scheduler, networking, NFS, memory manager, processes, SCSI and signal subsystems are already provided
所包含的功能：
/usr/share/systemtap/tapset
man –k systemtap
经常使用的探测点都可以被SystemTap的脚本探测，与IO调度器、网络、NFS、内存管理、处理器、SCSI和信号子系统相关的探测器已经提供。

Red Hat hosts a wiki dedicated to SystemTap and the sharing of scripts at:
http://sources.redhat.com/systemtap/wiki/

The wiki also has a comparison of SystemTap versus DTrace:
http://sources.redhat.com/systemtap/wiki/SystemtapDtraceComparison

Probe points are provided for a variety of purposes. Performance monitoring and optimization is a common use for the
following examples:
探测点可基于各种目的提供。性能监测和优化可用于下面的需求：

• Detect when a request is retrieved from the request queue (for disks, a read or write)
ioscheduler.elv_next_request


• Fired when return from retrieving a request
ioscheduler.elv_next_request.return

• View when data arrives on any network device
netdev.receive

• kernel sends a tcp message
tcp.sendmsg

• View page faults (i.e., when memory is physically allocated, data retrieved from the swap device, etc)
vm.pagefault

• Process attempts to invoke a new program
process.exec

• Process is released from the kernel (completely terminated, not in zombie state)
process.release

### The stap command
• Use on the development machine
• Works in up to five passes
1. Parse script
2. Resolve symbols against matching kernel-debuginfo
3. Translate into C
4. Build kernel module
5. Load module, run, and unload (requires root privileges!)
• Example: get a list of all kernel functions
stap -p2 -e 'probe kernel.function("*") {}' | sort -u

一个重要的参数：-k     
Keep the temporary directory after all processing.  This may be useful in order to examine the generated C code, or to reuse the compiled kernel object.

-p用于指定过程是其中的第几个，完成该过程之后就停下来；
-e表示不想输入一个文件而直接带脚本；

The SystemTap scripting language provides a relatively simple interface to kernel instrumentation. Without this
language, system administrator would have to code kernel modules manually, which obviously requires much more
advanced skills.
A SystemTap script can be as simple as a single line. For example, the following script places a probepoint on the
kernel sys_open() function and prints all callers with the function's arguments:

$ stap -e 'probe syscall.open {printf("%s: %s\n", execname(), argstr)}'

The stap utility generally takes a few seconds to execute: it achieves quite a few things in the background. It first
parses the script passed on the command line or as a file, and makes sure there are no syntax issues. It then generates a
temporary binary kernel module out of the script. The next step is to load that module into the kernel. The module will
then stay loaded, until the user terminates stap (generally by pressing CTRL-C on the keyboard).
After writing enough analysis scripts for yourself, your may become known as an expert to your colleagues, who will
want to use your scripts. SystemTap makes it possible to share in a controlled manner; to build libraries of scripts that
build on each other. In fact, all of the functions (pid(), etc.) used in the scripts above come from tapset scripts like that.
A ``tapset'' is just a script that is designed for reuse by installation into a special directory.
The execname() function used in the short script above is a good example of a tapset function. It is already defined
and may be used in your own scripts.

 
The staprun command
• Use on production machines
• No compiler needed
• Works in a single pass
• Load module, run, and unload (requires root privileges!)
• Example: run a module
staprun /path/to/module.ko

在生产环境中通过staprun将编译好的模块加载进去。
 
### 特征化的进程（赋予进程特征）：
在调优的概念中，进程可以根据其特征分成I/O bound和CUP bound。I/O bound的进程会使用更多的时间来等待I/O子系统中的数据。CPU bound进程会使用更多时间来等待处理器的处理。
另外一种区分的方法是看应用程序响应时间的类型或者吞吐量。
交互式进程大多数时间都处于sleep状态，但在接收到工作信号，比如说键盘动作等，那么该进程将被快速唤醒并开始工作。一般进程被唤醒的时间都是固定的。这种类型的进程一般为I/O bound进程。一般这种进程都会存在I/O瓶颈。
相反一些需要大量计算工作的进程需要更短的但是可以保证响应的时间，例如一些机器人的控制程序。

Big-O notation（标记法）是一个用于描述在运行时间中增长率顺序或者算法中根据输入的变化内存的使用量的方法。当指定一个增长率并给出一个输入的大小N，我们就可以计算出相关的进程数量。此时可以将获得结果中的一些固定值去掉，剩下的需要分析的是一些占绝对优势的进程，这样就简化了分析的过程。例如如果给出的input size是n的话，那么一个算法需要2n+1个instructons。
Big-O notation实际上是kernel中对调度和算法的管理模式。其大概意思是说，不管一个进程需要多少个指令去执行，处理每个指令所需要的时间都应该是一样的，不会因为有更多的指令等待上CPU而导致性能下降，也不会因为有很少的指令等待上CPU而导致性能提升。后面这个公式无非也是说明这个意思。但是遗憾的是我无法理解！只能后续再说。

按特性区分进程状态：
Linux进程状态包括：
TASK_INTERRUPTIBLE：进程在等待一些事件，例如I/O；
TASK_UNINTERRUPTIBLE：进程在等待，但忽略收到的信号；
TASK_RUNNABLE：进程可以运行；
其他的进程状态包括：
TASK_STOPPED：进程被挂起；
TASK_ZOMBIE：僵尸进程，一般指该进程被杀死但是其父进程并没有对其回收，该进程就称为僵尸。
僵尸进程实际上其所占用的资源已经被释放，但是因为没有被父进程回收而保留一个进程体结构而已。
那么相反，正常释放的进程实际上是子进程被杀死，然后父进程回收其资源；反过头来如果一个进程的父进程被杀死而子进程还存在，那么通常情况下init进程会称为其父进程。
如果进程请求I/O的时候会被移到TASK_INTERRUPTIBLE中，如果该进程获得了I/O并准备执行的时候他就会被移动到TASK_RUNNABLE中。

进程运行的准备工作：
在进程运行之前，所需要的数据需要先从CPU的缓存中读取。
Cache内的存储空间一般以线的形式体现和存在。每一个线都用来缓存一个指定的内存片。很多电脑都有不同的缓存用于缓存不同的内容，例如指令缓存和数据缓存。这种结构叫做哈佛内存架构。

在多处理器的系统上，每一个CPU都有自己单独的缓存。每一个缓存都有其关联的控制器。当一个进程访问内存的时候换从控制器会首先查看所需要的内存地址是否在缓存中并满足处理器的需求，若是则称为缓存命中。如果所需要的内存不在缓存中则称为cache miss，这时则需要读取内存并从内存中取出相应的数据，这个过程叫做cache line fill。

缓存控制器有一个阵列，该阵列为每一个缓存线提供了缓存条目。另外在被缓存的内存信息之外，每一个缓存条目都由一个tag和flags，这些用于描述缓存条目的状态。缓存控制器使用tag来标识哪一个内存位置被缓存为一个条目。

处理器会读写缓存。在写缓存操作进行到时候，缓存可以被配置为write-through或者write-back。如果write-through开启，那么当缓存中的一些线被更新，与之相关的主内存位置也会被更新。如果write-back开启，在缓存线被释放之前对其更改不会被立刻写入到内存中。从该角度看后者比前者更加高效。在x86架构上，每一个内存页都包含了控制位用于关闭页面缓存和write-back缓存。而Linux内核会清除在所有内存页面上的控制位所以默认情况下所有的内存访问都是通过write-back方式来缓存。

在多处理器的系统上，如果进程更新内存中的缓存线。那么其他处理器也会做同样的动作。这种情况称为cache snooping并在系统硬件上被执行。而NUMA架构系统会将内存组合成节点并将这些节点指派到不同的CPU插槽。

CPU的缓存：
不同类型的CPU缓存会影响服务时间：
直接映射、全关联、部分关联
直接映射缓存是最一种最廉价的缓存。每一个缓存线都映射到内存中的一个指定位置上。
全关联缓存是最具灵活性并且也是最贵的一种缓存。全关联缓存可以缓存内存中的任意位置。
而很多系统会折中地使用部分关联缓存。部分关联缓存也称为n路部分关联缓存。这里n是2的倍数。部分关联缓存可以使内存位置被读取到缓存的n个线中去。因此部分关联缓存提供了一个折中方案。

缓存线在128位内存中被映射为线。在使用P4 CPU或更好的Intel平台上，缓存线是128字节，而早期的处理器使用32字节的缓存线。
现代计算机都使用缓存来提高性能。缓存比内存快很多。一般主内存的访问时间为8ns，而缓存的访问时间和CPU的时钟频率一样小。并且很多计算机都有多级缓存。其中L1缓存很小一般集成在处理器芯片中。L2缓存会比L1大但也比L1慢。很多系统会有部署在CPU之外的L3缓存，尽管速度比L2慢但还是要比主内存快。
现代计算机使用多种不同的内存来确保CPU在工作的过程中始终有不同的内存来提供所需数据。在所有的存储器中最快的是CPU自身的寄存器。这些寄存器与CPU采用同样的时钟频率工作。但遗憾的是这些寄存器只能提供很小的空间而且一般成本极高。
缓存信息的查看可以通过命令x86info –c进行，而且一般缓存信息也会在dmesg文件中出现。

当应用程序所需要的数据大部分都可以通过对缓存的访问而不是对内存的访问获得，这个时候缓存的使用率是最高的。因此Cache stride就是指在一个cache line条目上所能够缓存的内存中的信息。

应用程序将会按照下面的方式访问数据。如果一个应用程序访问内存位置X那么在未来的几个循环中去获取X+1位置上的内容，这种行为叫做spatial locality of reference（立体定位），他对将磁盘中的数据以页面形式逐页移入内存的动作比较有效；而另外一种形式是temporal locality of reference（时间定位），即在一个时间周期内应用程序会周而复始地访问内存中的同一个位置。

缓存系统并不是在所有的时候都有用。一些程序员也可以开发不使用内存的应用程序。只有顺序访问内存的应用程序才会因cache而提升性能。

如果产生对新的内存位置的访问，进程需要清空当前的cache内容并重新缓存新的信息，这样将造成内存访问的延迟。但通常cache可以补偿这种延迟，不过应用程序就未必能够有这种优势。因此在一些程序中提供了其他的内存访问机制而不需要cache。

如果要查看缓存的使用情况，可以使用命令：
# valgrind --tool=cachegrind program_name
该工具能够实现，模拟缓存使用情况；指定L1，L2以对应CPU缓存；但程序在valgrind下会比较慢。

如果要提高locality of reference，需要：
手动优化代码：确保数据结构能够被缓存；使应用程序可以循环读取同样的数据。
使用编译器的自动优化功能。
在对应用程序进行编译的时候可以通过给编译器传递一些选项来实现优化。默认情况下这些优化选项是关闭的，因为这些选项开启会导致更长的编译时间并且增加debug的复杂度。如果开启这些选项则会使编译器增加编译时间或者代码大小。
Gcc编译器支持很多优化选项。另外在x86架构上，-mcpu选项可以防止产生在其他架构上运行的代码，而-march选项会产生只在指定CPU上产生的代码，这样将降低兼容性但是能够提高性能。
在编译红帽系统软件包的时候其实已经开启了这两个选项。

和2.4内核不同的是在2.6内核上每一个CPU核心有两个运行队列：active和expired。
当进程被放到active queue中的时候，进程必须被标记为TASK_RUNNABLE，在active queue中的第一个进程会上CPU。队列按照优先级来存储。直到进程占先的时候才会运行。当进程占先之后也会被放到expired队列中，所以active和expired队列会在active队列为空的时候相互交换。

处理器中的占先：
标准的占先规则：CPU收到一个硬件中断，进程请求I/O，进程自动按照CPU的sched_yield处理，调度算法会决定哪个进程占先。

如果要查看当前的调度算法和优先级：
# chrt –p pid；# ps axo pid；# comm；# rtprio；# policy；# top

初始进程从SCHED_OTHER开始，在进程建立的时候，每一个进程都会在一定时间带有其父进程的调度算法和优先级。

队列分类：
每个进程都可以按照一定的策略和优先级被调度。
静态优先级1-99：SCHED_FIFO和SCHED_RR
静态优先级0（动态100-139）：SCHED_OTHER和SCHED_BATCH

SCHED_FIFO：
这是最简单的策略，采用标准的占先规则；
SCHED_RR：
与SCHED_FIFO一样，但是增加了时间片，优先级越高（数字越小）则拥有越长的时间片。
当时间片超时则会占先。
SCHED_OTHER：
计算一个新的进程占先的内部优先级，范围为100-139

通常情况下进程具有0-139个优先级，0最高而139最低。而优先级0相当于real time优先级99，而1则相当于实时优先级98并以此类推。动态进程无法通过nice去进行调整并从120开始初始化。如果使用top命令RR区域会显示进程优先级（减去100）。

在2.6的内核上，新的调度算法会产生多条队列。Linux对每一个CPU建立两个运行队列，一个活跃队列和一个过期队列。这两个队列实际上都是双数的已经链接的列表的集合，每个优先级都有自己的列表。一开始过期队列为空，当进程可运行的时候会被放到活跃队列中，当活跃队列中的任务用尽了属于他的时间片，则会针对他计算出一个新的优先级，并且该优先级会被放到过期队列中属于该优先级的链接列表中。当活跃列表中所有的进程用尽了他们的时间片，kernel会采用一种简单的方法就是将活跃队列变成过期队列而使旧的过期列表变成新的活跃队列。为每一个处理器指定单独的队列可以有效减少队列争用的情况。

调度算法SCHED_OTHER会使进程拥有动态的优先级，其优先级完全取决于kernel和用户对其所进行的调整。开始的时候进程的优先级由nice值（通常为0）决定。同时该值可以通过命令nice和renice来指定。对于内部默认进程其优先级是120，因此一个进程在开启的时候会对其增加19，这样那个进程的优先级就是129。交互式的任务将花费时间等待I/O，因此调度器将检查每一个进程等待I/O的时间并计算出一个平均睡眠时间。如果平均睡眠时间比较高，则证明进程将插入活跃队列，否则会将优先级-5并将其移动到过期队列以进行优化。
如果使用的拥有相同优先级的进程会在每20ms之后尝试占先以防止CPU空闲。在占先动作之后CPU会对该进程的优先级+5。
对列调度器的调整策略：
针对SCHED_FIFO，使用chrt –f [1-99] /path/to/prog arguments
针对SCHED_RR，使用chrt –r [1-99] /path/to/prog arguments
针对SCHED_OTHER，使用nice和renice来调整

查看CPU性能方面数据的方法：
查看平均负载：运行队列的平均长度
需要考虑在TASK_RUNNABLE和TASK_UNINTERRUPTABLE这两个数值，使用命令：
# sar –q 1 2 
# top
# w
# uptime
而CPU使用率：
# mpstat 1 2 
# sar –P ALL 1 2 
# iostat –c 1 2 
# /proc/stat






硬件时钟通常有下面的几种：
实时时钟RTC
主要用于在系统关机的时候维持时间和日期信息并可在开启的时候利用该时间设置系统时间。
其信息在/proc/driver/rtc中

时间戳时钟
这是一个寄存器，该寄存器会以和CPU晶振相同的频率更新。其主要功能是提供高层计数器用于和RTC一起计算时间和日期信息

高级可编程中断控制器
APIC包括了本地CPU计时器，该计时器用于跟踪运行在CPU上的进程并使该进程从本地CPU到多CPU过程中产生中断

可编程中断计数器PIT
可用内核中所有通用的始终保留动作，包括进程调度等

在X86架构的系统中Linux的PIC用于在一定的时间间隔之内产生中断。对于RHEL3和更早的系统，2.4内核会在100Hz的频率上产生1个tick，而在使用2.6内核的RHEL4上会在1000Hz的频率上产生一个1个tick。

如何调整系统的tick？
内核启动参数：tick_dirver = value 可以使用的值是2，4，5，8，10
分别对应500Hz，250Hz，200Hz，125Hz，100Hz，但这些值只针对X86和X86_64架构，不能用于Xen。
对处理器频率调整的方法：
可以通过调整处理器的时钟速度来减少能耗：cpuspeed
调整之后：
可以减少能耗，并影响timekeeping。
进程cpuspeed对笔记本电脑会比较有用，该进程可以通过在空闲期间降低处理器时钟速度来达到节省电池的目的。调整/etc/sysconfig/cpuspeed文件中的参数并开启cpuspeed服务，但不能用于xen内核
参数选项可以在/etc/cpuspeed.conf中获得。

IRQ平衡：
硬件中断会占先于当前的进程因而会使进程产生一些延迟。
在这种情况下查询中断的方法：
# procinfo以及# cat /proc/interrupts

关于irqbalance功能：
需要可用的APIC实现每10s移动一次irq。
采用2.6内核的好处之一是2.6内核的调度器可以使一些内核进程像其他普通进程一样占先并被调度。这样可以影响一些如网络I/O等低延迟的进程。例如，内核可以运行一个句柄来为用户进程执行一个磁盘I/O并且会收到网卡的中断信号。而该句柄可以占先来使网络数据包延迟得到优化。
如果使用noapic作为内核启动参数将不会使用irqbalance功能。

调整IRQ：
可以调整irqbalance，配置文件/etc/sysconfig/irqbalance
如果要关闭irqbalance，使用如下方法：
# chkconfig irqbalance off
# echo cpu_mask > /proc/irq/<interrupt_number>/smp_affinity
向CPU中传递IRQ句柄可以优化cache的性能，但是如果句柄被放到活跃队列的头部时会导致服务时间变慢。smp_affinity是一个16进制表示的掩码，如果要向第一个CPU指派IRQ，则使用命令：
# echo 1 > /proc/irq/<interrupt_number>/smp_affinity

平衡CPU的访问量：
当进程占先之后会移动到过期队列，对于CPU来说会通过他自己的算法来决定，并且会产生不平衡的运行队列。
调度器会重新平衡运行队列，如果所有进程都处于繁忙状态则100ms平衡一次，如果CPU处于idle状态则1ms平衡一次，可以通过该命令查看指定进程：
# watch –n.5 ‘ps axo comm.,pid,psr | grep program_name’
结果：
使访问量降低会导致吞吐量增大，而且将任务移动到ingwai一个CPU有可能会导致缓存命中率降低。

在多处理器系统上每一个物理CPU都有他自己的运行队列。对于超线程CPU而言，逻辑CPU使用和物理CPU相同的队列。当一个进程在固定的CPU上用完他自己的时间片时候就会进入到该CPU的超时队列中去。因此处理器都拥有其自己的亲和性，他会使得原来由自己处理的进程在更多的时候还会由自己处理。在多数情况下这是一个期望的行为。因为每个CPU都有自己的cache，因此这样做的好处是使得每个CPU都能够使用原先cache中的时间片来提高cache命中率。但如果任务经常在处理器之间来回切换，那么就会导致CPU要重新缓存信息而影响性能。

在多处理器上对不同的CPU使用不同的队列产生的典型问题是队列的不平衡。比如在不同CPU上的进程数量多少不均。在这种情况下系统会每隔100ms重新平衡队列，如果调度器发现一个空的CPU就会每隔1ms检查其上的运行队列并将任务平衡过去。
下面的命令：
# watch –n.5 ‘ps axo comm.,pid,psr 就是用于查看进程在哪个CPU上。

于是可以使用命令taskset调整处理器的亲和性：
# taskset [opts] [mask | list] [pid | command]
最终的结果：
对某些程序提高缓存命中率（减少服务时间），如果不平衡对列会产生更长的等待时间，对于NUMA架构要防止访问本地内存：

作为CPU bitmask的替代，在使用taskset的时候可以使用一个数字化的列表来指定进程在哪个CPU之上，可以使用-c或者--cup-list选项。Fedora有一个叫做schedtool的软件，可以和chrt和taskset来实现对进程在CPU之间调度的操作。

如果要用taskset命令调整运行队列的长度：
限制CPU运行队列长度：
1．	可以在/etc/grub.conf的设置中将CPU从自动调度中独立出来：
# isolcpus = cpu number, … ,cpu number
2．	使用taskset对某些任务指定固定的CPU
3．	需要斟酌是否将IRQ从CPU上转移出来
结果：对于要优化的任务可以缩短运行队列和等待时间，但是会加大其他CPU的负载

其实缩短某个运行队列的长度是一个有争议的做法。
如果要缩短运行队列的长度可以在系统启动的时候使用isolcpus将某个CPU从自动调度中孤立出来以手动对其指定队列。

使用taskset命令来控制进程延迟的缺点是对于在多个CPU上负载不同的进程将比较难控制。

调度器区域：
可以将多个进程调整到一个CPU集合（cpuset）中去：
每一个cpuset都使用同一个调度器区域；同时支持多核和NUMA架构；通过cpuset可以简化管理
默认root cpuset将包含所有的系统资源；
子cpuset：
每一个cpuset必须包含至少一个cpu和一个内存区域；子cpuset可以被嵌套；可以动态地将任务附加到cpuset中去。
结果：
可以通过队列长度、缓存和NUMA区域来控制延迟；可以根据进程的情况为其指定不同的cpuset；可以对复杂的进程进行调整

调度器区域是和cpuset一起使用的。每一个cpuset都会组成一个调度器区域，在该调度器区域中可以平衡任务。在将一个或者多个CPU指定到cpuset之后就可以将一个或者多个任务指定到该cpuset，那么调度器将会使这些任务的调度限定到该cpuset之中。

另外如果指定任务只运行在他们自己的cpuset中可以为控制运行队列的长度和任务延迟提供弹性、简洁性和便利性。同时也不会产生额外的负载。当前已经存在的系统调用，例如sched_setaffinity可以在调度器区域内透明地工作。可以使用下面的命令来确保kernel支持cpuset：
# grep –i cpuset /proc/filesystems /boot/config-*
Cpuset VFS可以在任何时候被挂载。在该课程中假设他将被挂载到/cpusets中。该root VFS包含了一个root cpuset，而且包含了所有的CPU核心和系统内存。你可以在这个VFS上建立一个子目录，这样每个子目录将代表和建立一个新的cpuset，那么资源就可以被指派到不同的cpuset上去。这是一个层次结构。

配置root cpuset：
1．	升级selinux policy：
2．	建立/cpusets
3．	修改/etc/fstab文件添加到/cpusets自动挂载
4．	系统将会自动挂载文件系统到/cpusets目录下
5．	所有的cpu和内存区域都属于root cpuset，所有的pid都被指派到root的cpuset

当VFS被挂载的时候root cpuset会自动建立。但通常会挂载到/下，如果是要建立/dev/cupsets的话则需要建立udev规则。当root cpuset文件系统被自动挂载的时候所有CPU和所有进程都被指派到root cpuset中。当一个进程产生的时候，他们也会被指派到相应的cpuset中：
# cat /cpusets/cpus		# cat /cpusets/mems		# cat /cpusets/tasks | sort –n
如果要使cpusets可以被自动删除，需要修改notify_on_release，这个文件包含了0和1两个值，决定了当cpusets中的最后一个任务中止的时候kernel是否会运行/sbin/cpuset_release_agent来自动删除cpuset。一般情况下/sbin/cpuset_release_agent不会默认存在，需要在启用notify_on_release之前手动开启。

配置子cpuset：
可以在根cpuset目录下建立一个子目录，该目录是子调度器的区域，kernel将会自动在该区域中建立响应的文件以及附加相关属性。每一个子cpuset（调度器区域）必须包含至少一个处理器和一个内存区域。对于x86架构只有一个内存区域（0），而对于NUMA架构可以有多个。如果要查看系统上哪个内存区域可用，可以执行命令：
# cat /cpusets/mems
然后开始建立子cpuset：
# mkdir /cpusets/rh442
子cpuset可以包含属于父的cpu和内存区域。默认情况下子cpuset不包含cpu和内存区域。你必须手动对其设置。如果指派一个资源的范围或者是以逗号隔开：
# /bin/echo “0,3” > /cupsets/rh442/cpus
# /bin/echo “0-3” > /cpuset/rh442/cpus
# /bin/echo 0 > /cpusets/rh442/cpus
# /bin/echo 0 > /cpusets/rh442/mems
然后将某一个任务指派到子cpuset中去：
# /bin/echo `pidof sshd` > /cpusets/rh442/cpus
当然如果需要永久生效则需要修改/etc/rc.local。

若不指派至少一个CPU和内存区域到cpuset中，那么指定任务到cpuset中会产生“no space left on device”的错误。如果要将任务从cpuset中移除，只需要将该任务指定到其他的cpuset中，例如root cpuset。也可以将cpuset移动到其他的子目录中，但是在此之前必须先将所有的任务从他的调度器区域中转移出去。

和调度器区域相关的重要文件：
查看pid在哪个cpuset中：/proc/pid/cpuset
查看进程被调度到哪一个资源上：
# cat /proc/pid/status | grep allowed
查看进程是否属于多个cpuset：
/cpusets/rh442/cpu_exclusive
确保任务可以被自动清除：
/cpusets/rh442/notify_on_release
下面是一些具体的例子：
如果要查看sshd被指派到哪一个domain使用下面的命令：
# cat /proc/$(pidof sshd)/cpuset
# cat /proc/$(pidof sshd)/status | grep allowed

如果cpu_exclusive包含1则说明在个调度器区域中的处理器只会被指派到该区域或者他的父区域中。其他子区域中的进程将无法使用该cpu。若要自动清除调度器区域，可建立一个脚本在/sbin/cpuset_release_agent，并且在notify_on_release中输入1。当最后的PID从cpuset中移除时，kernel会执行/sbin/cpuset_release_agent中的命令将其移除，例如：
# /sbin/cpuset_release_agent /rh442

对于VCPU进行的优化：
可以指派物理CPU数量以上的虚拟CPU：
需要测试程序在SMP环境下的运行情况，虚拟运行队列将会竞争物理CPU，所有的区域对CPU时间都有相同的访问权限。
可以在Dom-0上以动态或者静态的方式调整VCPU对真实CPU的资源分配，可以为关键domain分配更多的物理CPU资源，这样有助于减少关键domain上的延迟。
当虚拟机建立的时候，每一个domain都可以指派一定数量的虚拟CPU。虚拟CPU实际上是通过hypervisor运行在真实CPU上的。默认情况下所有的虚拟机域都有对真实CPU相同的访问能力。所以可以对某些关键的虚拟机domain分配更多的虚拟CPU，这样可以显著地提升虚拟机的性能。当然也可以强制一个虚拟机运行和使用特定的真实CPU。

在虚拟机建立的时候调整VCPU：
配置文件是/etc/xen/domain，包括：
启动虚拟机的时候所使用的最大的CPU数量：vcpus=4
虚拟机在哪个物理CPU上启动：cpu=0
使虚拟机在多个不同的物理CPU上运行实现队列平衡：cpus=0,2-4

如何动态调整VCPU：
VCPU的数量无法超过其初始配置的数量，通过命令行对其调整的方法：
# virsh setvcpus domain number-of-vcpus
# xm vcpu-set domain number-of-vcpus
也可以在virt-manager出现的图形界面上进行调整。

调整虚拟CPU的亲和性：
# virsh vcpupin domain | domID VCU CPU，
# xm vcpu-pin domain | domID VCPU CPU
最终的结果：
可以提高Dom-U缓存命中率并减少访问时间，可以独立地指派资源以及控制队列长度

通常情况下每一个Dom-U的虚拟CPU会以轮询方式使用物理CPU。Hypervisor会针对每一个Dom-U的需求来调度CPU时间。这也意味着所有的domain，包括domain 0会竞争物理CPU时间，在某些情况下需要对这种情况进行调整。

和设置CPU亲和性的方法类似，虚拟CPU也可以设置只使用一个或者多个指定的物理CPU。可以使用xm或者virsh命令来进行设置。

例如要使得dom-U的webserver使用第二个物理CPU，使用命令：
# virsh vcpupin webserver 0 1


### 参考实验
第四章实验：

实验一：安装systemtap：

1. SystemTap requires matching kernel, kernel-debuginfo, and kernel-devel packages. These packages
   must match your running kernel. The instructor has made the necessary packages available at
   http://server1/pub/kernel-extras. Install an appropriate set of matching kernel
   packages.
2. Make sure the systemtap package is correctly installed.
3. Confirm that SystemTap is working by creating a text file containing the name of every kernel
   function in your kernel.


SystemTap的安装需要和当前使用的内核版本一致的kernel-debuginfo，kernel-debuginfo-common和kernel-devel包。

之后确保systemtap包已经安装。

细化一下：

• On the development machine：
  • systemtap
  • kernel-debuginfo (must match running kernel)
  • kernel-devel (must match running kernel)
  • gcc
• On the production machine
  • systemtap-runtime

通过执行下面的命令确保systemtap正常工作，该命令会建立一个包含所有kernel function的文本。

[root@dom-0 ~]# stap -p2 -e 'probe kernel.function("*") {}' | sort -u > kernel_function 


[root@dom-0 ~]# less -FiX kernel_functions


 
实验二：使用systemtap监控上下文开关（context switch）：

在系统中，上下文开关无时不存在，当进程等待事件的时候，上下文开关就会被替换。

而且，由于进程一般在CPU上运行的时间只有数毫秒，因此上下文开关只有在进程不等待外部事件的时候发生。因此这会对性能产生一些影响，并且我们可以通过systemtap来监测。上下文开关一般会替换一个叫做schedule（）的kernel function。建立一个叫做csmon.stp的systemtap的脚本，可在这些功能生效的时候显示出“Scheduler invoked”。

例如：

[root@dom-0 rh442]# cat csmon.stp 
probe kernel.function("schedule").return {
        printf("Scheduler invoked")
}

[root@dom-0 rh442]# pwd
/root/rh442

注意，脚本实际上在通过stap运行的时候会产生所需要的模块，并且在stap运行的时候会自动将该模块加载上去，所以stap命令是在production server上运行。

执行stap，可以发现由于schedule()这个function普遍存在，所以在屏幕上会有大量的标记输出。
[root@dom-0 rh442]# stap csmon.stp 

但假如我们将脚本更改一下，例如改成如下内容，那么systemtap只有到context switch到达10000的时候才会计数并显示信息在console上。

[root@dom-0 rh442]# cat csmon1.stp 

global count
probe kernel.function("schedule").return {
        count++
        if ((count%1000)==0) {
                printf(".\n")
        }
        if (count==10000) {
                printf("reached 10000 context switches!\n")
                count=0
        }
}

或者可以将脚本改成如下内容，表示每5s给一个report，显示出哪个进程执行context switch最为频繁，并且所有结果由高到低排序。
[root@dom-0 rh442]# cat csmon2.stp 
global processes
function print_top () {
  cnt=0
  foreach ([name] in processes-) {
    printf("%-20s\t\t%5d\n",name, processes[name])
    if (cnt++ == 20)
     break
  }
  printf("--------------------------------------\n\n")
  delete processes
}
probe kernel.function("schedule").return {
  processes[execname()]++
}
probe timer.ms(5000) {
  print_top ()
}

这是所显示的结果：

[root@dom-0 rh442]# stap csmon2.stp 
swapper                           859
systemtap/0                       499
firefox                           195
kondemand/0                       124
Xorg                               93
scim-launcher                      49
gnome-terminal                     27
gnome-power-man                    24
escd                               17
vpngui                             10
migration/0                         7
migration/1                         7
stapio                              6
sh                                  3
modclusterd                         2
ksoftirqd/0                         1
--------------------------------------

同时也可以像下面这样修改脚本，表示将以每10s作为固定频率显示30个进程的content switch，并由高到低排序：

[root@dom-0 rh442]# cat csmon3.stp 
global processes
function print_top() {
     cnt=0
     foreach ([name] in processes-) {
        printf("%-20s\t\t%5d\n",name, processes[name])
        if (cnt++ == 30)
           break
     }
     printf("------------------------------------------\n\n")
     delete processes
}
probe kernel.function("schedule").return {
    processes[execname()]++
}
probe timer.ms(10000) {
     print_top()
}

这是所显示的结果：

[root@dom-0 rh442]# stap csmon3.stp 
swapper                           818
systemtap/0                       523
firefox                           101
Xorg                               75
gnome-power-man                    52
stapio                             43
scim-panel-gtk                     33
gnome-terminal                     26
vpngui                             15
hald-addon-stor                    11
clustat                             9
kjournald                           5
thunderbird-bin                     4
pcscd                               4
aisexec                             2
gnome-screensav                     2
rpc.idmapd                          1
kblockd/1                           1
gdm-rh-security                     1
------------------------------------------

下面的脚本配合systemtap将列出产生最多sys_open调用的进程，而且会将所有结果从高到低排序。这个脚本将有助于查看哪个进程频繁地打开文件：

[root@dom-0 rh442]# cat csmon4.stp 
global processes
function print_top () {
        cnt=0
        log ("Process\t\t\t\tCount")
        foreach ([name] in processes-) {
                 printf("%-20s\t\t%5d\n",name, processes[name])
                 if (cnt++ == 20)
                         break
        }
        delete processes
}
probe kernel.function("sys_open").return {
        processes[execname()]++
}
probe timer.ms(5000) {
        print_top ()
}

这是显示的结果：
[root@dom-0 rh442]# stap csmon4.stp 
Process                         Count
pcscd                             180
ifconfig                           18
sh                                 16
clustat                             7
modclusterd                         6
env                                 6
gpm                                 3
hald-addon-stor                     3
scim-panel-gtk                      2


### 参考实验

第八章实验：

实验一：查看缓存的命中率：

首先确保cache-lab包和x86info包已经安装：
[root@dom-0 rh442]# rpm -ql cache-lab
/root/cache1.c
/root/cache2.c
/usr/local/bin/cache1
/usr/local/bin/cache2
/usr/share/doc/cache-lab-0.1
/usr/share/doc/cache-lab-0.1/README
/usr/share/doc/cache-lab-0.1/cache1.c
/usr/share/doc/cache-lab-0.1/cache2.c

通过x86info和dmesg命令来获得CPU的L1和L2 cache的值：

需要注意到是，有时候x86info命令不一定能看到这些信息。所以这种情况下可以查看/var/log/dmesg中的值。
更关键的是通过cpuinfo看到instruction cache，associative和line size的值。

[root@dom-0 rh442]# x86info -c | grep cache
/dev/cpu/0/cpuid: No such file or directory
 L1 Instruction cache: 32KB, 8-way associative. 64 byte line size.
 L1 Data cache: 32KB, 8-way associative. 64 byte line size.
Found unknown cache descriptors: 48 
 L1 Instruction cache: 32KB, 8-way associative. 64 byte line size.
 L1 Data cache: 32KB, 8-way associative. 64 byte line size.
Found unknown cache descriptors: 48 


[root@dom-0 rh442]# cat /var/log/dmesg | grep cache
Dentry cache hash table entries: 131072 (order: 7, 524288 bytes)
Inode-cache hash table entries: 65536 (order: 6, 262144 bytes)
Mount-cache hash table entries: 512
CPU: L1 I cache: 32K, L1 D cache: 32K
CPU: L2 cache: 3072K
CPU: L1 I cache: 32K, L1 D cache: 32K
CPU: L2 cache: 3072K


这是针对双核CPU的典型输出。可知现在：
instructon cache: 32 x 1024 = 32768
associative: 8
line size: 64
即：32768，8，64。同理：Data level 1的值：32768，8，64，而Data level 2的值，根据二级缓存大小，计算出来应该为3145728，至于associative和line size的值，如果没有可以采用一个典型的值，即分别为8和64。但是事实上在书上的实验中，对于L2的值计算出来是524288，如果处以1024应该是512KB，如果我使用524288这个值在后面的valgrid的测试中是可以执行的，但是如果使用3145728在测试中会出错。

使用valgrind来获得在执行cache-lab程序的时候，I1，D1和L2的使用情况：

[root@dom-0 ~]# valgrind --tool=cachegrind --I1=32768,8,64 --D1=32768,8,64 --L2=524288,8,64 cache1

==6458== Cachegrind, an I1/D1/L2 cache profiler.
==6458== Copyright (C) 2002-2006, and GNU GPL'd, by Nicholas Nethercote et al.
==6458== Using LibVEX rev 1658, a library for dynamic binary translation.
==6458== Copyright (C) 2004-2006, and GNU GPL'd, by OpenWorks LLP.
==6458== Using valgrind-3.2.1, a dynamic binary instrumentation framework.
==6458== Copyright (C) 2000-2006, and GNU GPL'd, by Julian Seward et al.
==6458== For more details, rerun with: -v
==6458== 
--6458-- warning: Unknown Intel cache config value (0x48), ignoring
--6458-- warning: L2 cache not installed, ignore L2 results.
Starting
Finished
==6458== 
==6458== I   refs:      6,188,130,514
==6458== I1  misses:              615
==6458== L2i misses:              611
==6458== I1  miss rate:          0.00%
==6458== L2i miss rate:          0.00%
==6458== 
==6458== D   refs:      3,937,856,940  (3,375,266,094 rd + 562,590,846 wr)
==6458== D1  misses:       35,157,387  (          957 rd +  35,156,430 wr)
==6458== L2d misses:       35,157,290  (          868 rd +  35,156,422 wr)
==6458== D1  miss rate:           0.8% (          0.0%   +         6.2%  )
==6458== L2d miss rate:           0.8% (          0.0%   +         6.2%  )
==6458== 
==6458== L2 refs:          35,158,002  (        1,572 rd +  35,156,430 wr)
==6458== L2 misses:        35,157,901  (        1,479 rd +  35,156,422 wr)
==6458== L2 miss rate:            0.3% (          0.0%   +         6.2%  )


[root@dom-0 ~]# valgrind --tool=cachegrind --I1=32768,8,64 --D1=32768,8,64 --L2=524288,8,64 cache2
==6460== Cachegrind, an I1/D1/L2 cache profiler.
==6460== Copyright (C) 2002-2006, and GNU GPL'd, by Nicholas Nethercote et al.
==6460== Using LibVEX rev 1658, a library for dynamic binary translation.
==6460== Copyright (C) 2004-2006, and GNU GPL'd, by OpenWorks LLP.
==6460== Using valgrind-3.2.1, a dynamic binary instrumentation framework.
==6460== Copyright (C) 2000-2006, and GNU GPL'd, by Julian Seward et al.
==6460== For more details, rerun with: -v
==6460== 
--6460-- warning: Unknown Intel cache config value (0x48), ignoring
--6460-- warning: L2 cache not installed, ignore L2 results.
Starting
Finished
==6460== 
==6460== I   refs:      6,188,130,514
==6460== I1  misses:              615
==6460== L2i misses:              611
==6460== I1  miss rate:          0.00%
==6460== L2i miss rate:          0.00%
==6460== 
==6460== D   refs:      3,937,856,940  (3,375,266,094 rd + 562,590,846 wr)
==6460== D1  misses:      562,501,127  (          957 rd + 562,500,170 wr)
==6460== L2d misses:       35,162,914  (          868 rd +  35,162,046 wr)
==6460== D1  miss rate:          14.2% (          0.0%   +        99.9%  )
==6460== L2d miss rate:           0.8% (          0.0%   +         6.2%  )
==6460== 
==6460== L2 refs:         562,501,742  (        1,572 rd + 562,500,170 wr)
==6460== L2 misses:        35,163,525  (        1,479 rd +  35,162,046 wr)
==6460== L2 miss rate:            0.3% (          0.0%   +         6.2%  )

所以为了命令的正确性，只好将命令简化：

[root@dom-0 ~]# valgrind --tool=cachegrind --I1=32768,8,64 --D1=32768,8,64 cache1

==9691== Cachegrind, an I1/D1/L2 cache profiler.
==9691== Copyright (C) 2002-2006, and GNU GPL'd, by Nicholas Nethercote et al.
==9691== Using LibVEX rev 1658, a library for dynamic binary translation.
==9691== Copyright (C) 2004-2006, and GNU GPL'd, by OpenWorks LLP.
==9691== Using valgrind-3.2.1, a dynamic binary instrumentation framework.
==9691== Copyright (C) 2000-2006, and GNU GPL'd, by Julian Seward et al.
==9691== For more details, rerun with: -v
==9691== 
--9691-- warning: Unknown Intel cache config value (0x48), ignoring
--9691-- warning: L2 cache not installed, ignore L2 results.
Starting
Finished
==9691== 
==9691== I   refs:      6,188,130,508
==9691== I1  misses:              615
==9691== L2i misses:              611
==9691== I1  miss rate:          0.00%
==9691== L2i miss rate:          0.00%
==9691== 
==9691== D   refs:      3,937,856,938  (3,375,266,092 rd + 562,590,846 wr)
==9691== D1  misses:       35,157,387  (          957 rd +  35,156,430 wr)
==9691== L2d misses:        3,516,599  (          820 rd +   3,515,779 wr)
==9691== D1  miss rate:           0.8% (          0.0%   +         6.2%  )
==9691== L2d miss rate:           0.0% (          0.0%   +         0.6%  )
==9691== 
==9691== L2 refs:          35,158,002  (        1,572 rd +  35,156,430 wr)
==9691== L2 misses:         3,517,210  (        1,431 rd +   3,515,779 wr)
==9691== L2 miss rate:            0.0% (          0.0%   +         0.6%  )

[root@dom-0 ~]# valgrind --tool=cachegrind --I1=32768,8,64 --D1=32768,8,64 cache2

==9694== Cachegrind, an I1/D1/L2 cache profiler.
==9694== Copyright (C) 2002-2006, and GNU GPL'd, by Nicholas Nethercote et al.
==9694== Using LibVEX rev 1658, a library for dynamic binary translation.
==9694== Copyright (C) 2004-2006, and GNU GPL'd, by OpenWorks LLP.
==9694== Using valgrind-3.2.1, a dynamic binary instrumentation framework.
==9694== Copyright (C) 2000-2006, and GNU GPL'd, by Julian Seward et al.
==9694== For more details, rerun with: -v
==9694== 
--9694-- warning: Unknown Intel cache config value (0x48), ignoring
--9694-- warning: L2 cache not installed, ignore L2 results.
Starting
Finished
==9694== 
==9694== I   refs:      6,188,130,502
==9694== I1  misses:              615
==9694== L2i misses:              611
==9694== I1  miss rate:          0.00%
==9694== L2i miss rate:          0.00%
==9694== 
==9694== D   refs:      3,937,856,936  (3,375,266,092 rd + 562,590,844 wr)
==9694== D1  misses:      562,501,127  (          957 rd + 562,500,170 wr)
==9694== L2d misses:        3,516,599  (          820 rd +   3,515,779 wr)
==9694== D1  miss rate:          14.2% (          0.0%   +        99.9%  )
==9694== L2d miss rate:           0.0% (          0.0%   +         0.6%  )
==9694== 
==9694== L2 refs:         562,501,742  (        1,572 rd + 562,500,170 wr)
==9694== L2 misses:         3,517,210  (        1,431 rd +   3,515,779 wr)
==9694== L2 miss rate:            0.0% (          0.0%   +         0.6%  )



 
实验二：进程优先级：

在该实验当中，我们将对比一个进程在两个不同优先级情况下执行某个程序时候的时间。

首先建立下面的脚本counter.sh：

[root@dom-0 ~]# ll counter.sh 
-rwxr-xr-x 1 root root 233 May 30 22:57 counter.sh

[root@dom-0 ~]# cat counter.sh 
#!/bin/bash
if [ $# -ne 1 ] ; then
   echo "insufficient arguments" >&2 ; exit 1
fi
STARTVAL=$1
COUNT=$STARTVAL
ENDVAL=$[ $STARTVAL + 100000 ]
while [ $COUNT -le $ENDVAL ] ; do
   echo $COUNT
   COUNT=$[ $COUNT + 1 ]
done
read JUNK

然后建立另外一个脚本launch.sh：
[root@dom-0 ~]# ll launch.sh 
-rwxr-xr-x 1 root root 197 May 30 22:58 launch.sh

[root@dom-0 ~]# cat launch.sh 
#!/bin/bash
xterm -geometry 40x20+50+20 -title "NicePlus10" \
      -e nice -n +10 ~/counter.sh 1 &
xterm -geometry 40x20+500+20 -title "NiceMinus10" \
       -e nice -n -10 ~/counter.sh 100001 &


然后执行脚本launch.sh，观察哪一个进程先结束，并且观察一旦高优先级的进程结束，低优先级的进程有什么样的变化。


 
实验三：使用nice命令：

在该实验当中，我们将测试nice命令的有效性。我们将看到低优先级的进程如何获得比高优先级进程更少的时间片而导致运行更慢。

首先建立一个脚本：
[root@dom-0 ~]# ll busywork 
-rwxr-xr-x 1 root root 59 May 30 23:20 busywork

[root@dom-0 ~]# cat busywork 
#!/bin/bash
for i in $(seq 1 100000)
do
 j=$(($i+1))
done

另外执行命令：
# cat /dev/zero > /dev/null

因为要确保测试进程在执行的时候，另外一个程序在以同样的优先级使用CPU。

[root@dom-0 ~]# time ./busywork 

real    0m1.261s
user    0m1.206s
sys     0m0.038s

这个结果显示，busywork在运行的时候在CPU上花费的时间是1.206 ＋ 0.038秒。

而如果将程序的优先级调低：

[root@dom-0 ~]# time nice -n 19 ./busywork 

real    0m1.339s
user    0m1.208s
sys     0m0.039s

似乎在CPU上花费的时间和上个测试相同。但是按照书上的理论，这个值应该比上个值要慢。


 
实验四：关于load average的测试：

首先通过sar命令来收集一批数据：
[root@dom-0 ~]# sar -q 10 60 > load.lout

在此期间，打开一些程序并产生一些压力：

[root@dom-0 ~]# cat /dev/zero > /dev/null &
[root@dom-0 ~]# cat /dev/zero > /dev/null &
[root@dom-0 ~]# cat /dev/zero > /dev/null &

等待sar命令结束，上述sar命令要运行10分钟结束，在此期间，使用其他系统运行一些其他的任务，一旦结束，关闭cat命令。
使用gnuplot来对sar的结果进行绘图。在操作前应该先删掉一些字符，因此：
[root@dom-0 ~]# tail -n +4 load.out | awk '/^[01]/ {print $0}' > load.gplot

[root@dom-0 ~]# cat load.gplot 
11:49:20 PM         1       204      1.00      0.98      0.78
11:49:30 PM         1       204      1.00      0.98      0.78
11:49:40 PM         1       204      1.00      0.98      0.78
11:49:50 PM         1       204      1.00      0.98      0.79
.......................

似乎和未处理前的原始数据没有什么差异。

现在用gnuplot来绘图：
gnuplot> set xdata time
gnuplot> set timefmt "%H:%M:%S"
gnuplot> set xlabel "Time"
gnuplot> set ylabel "Load Average"
gnuplot> plot "load.gplot" using 1:4 title "1 minute" with lines
gnuplot> replot "load.gplot" using 1:5 title "5 minute" with lines
gnuplot> replot "load.gplot" using 1:6 title "15 minute" with lines

[root@dom-0 ~]# gnuplot -persist .gnuplot_history 
[root@dom-0 ~]# cat .gnuplot_history 
set xdata time
set timefmt "%H:%M:%S"
set xlabel "Time"
set ylabel "Load Average"
plot "load.gplot" using 1:4 title "1 minute" with lines
replot "load.gplot" using 1:5 title "5 minute" with lines
replot "load.gplot" using 1:6 title "15 minute" with lines
quit


 
第九章实验：

实验一：使用VCPU：

关闭虚拟机并建立一个8个CPU的虚拟机：

# virsh shutdown vserver

# xentop

# xm create snap vcpus=8

同时可以在domain-0上将vcpu的数量动态调整为其他值：

# virsh setvcpus snap 2


 
