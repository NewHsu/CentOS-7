## Process & CPU

### 特征化的进程（赋予进程特征）：
* 在调优的概念中，进程可以根据其特征分成I/O bound和CUP bound。I/O bound的进程会使用更多的时间来等待I/O子系统中的数据。CPU bound进程会使用更多时间来等待处理器的处理。
* 另外一种区分的方法是看应用程序响应时间的类型或者吞吐量。
* 交互式进程大多数时间都处于sleep状态，但在接收到工作信号，比如说键盘动作等，那么该进程将被快速唤醒并开始工作。一般进程被唤醒的时间都是固定的。这种类型的进程一般为I/O bound进程。一般这种进程都会存在I/O瓶颈。
* 相反一些需要大量计算工作的进程需要更短的但是可以保证响应的时间，例如一些机器人的控制程序。

### Linux进程状态包括：
* TASK_RUNNABLE：进程准备执行或者正在退出，只有当进程在该状态时才会被放到运行队列；
* TASK_INTERRUPTIBLE： 进程正在等待一些事件，比如IO操作的完成；
* TASK_UNINTERRUPTIBLE：进程在等待，但忽略收到的信号；
* TASK_STOPPED：进程被挂起或者暂停；
* TASK_ZOMBIE：僵尸进程，一般指该进程被杀死但是其父进程并没有产生相应的系统调用对其回收，该进程就称为僵尸。
> 僵尸进程实际上其所占用的资源已经被释放，但是因为没有被父进程回收而保留一个进程体结构，那么相反的逻辑，正常释放的进程实际上是子进程被杀死，然后父进程回收其资源；打你是有一些情况是如果一个进程的父进程被杀死而子进程还存在，那么通常情况下init进程会成为其父进程。

### 运行之前
* 进程运行前的准备工作包括：在工作开始之前，数据必须存在于CPU的缓存中。若读取的数据在缓存中，称为缓存命中，若不在则称为缓存miss，对于miss的数据，内核会从内存中读取数据到缓存，这个过程称为填充缓存线，而将缓存中的数据填充到内存，包括write-rhtough和write-back。

* 在进程运行之前，所需要的数据需要先从CPU的缓存中读取。Cache内的存储空间一般以线的形式体现和存在。每一个线都用来缓存一个指定的内存片。很多电脑都有不同的缓存用于缓存不同的内容，例如指令缓存和数据缓存。这种结构叫做哈佛内存架构。

* 在多处理器的系统上，每一个CPU都有自己单独的缓存。每一个缓存都有其关联的控制器。当一个进程访问内存的时候换从控制器会首先查看所需要的内存地址是否在缓存中并满足处理器的需求，若是则称为缓存命中。如果所需要的内存不在缓存中则称为cache miss，这时则需要读取内存并从内存中取出相应的数据，这个过程叫做cache line fill。

* 缓存控制器包含了一系列的缓存条目，这些缓存条目针对每一个缓存线。另外在被缓存的内存信息之外，每一个缓存条目都由一个tag和flags，这些用于描述缓存条目的状态。缓存控制器使用tag来标识哪一个内存位置被缓存为一个条目。


### 补全 CPU snoop的架构和查找图

* 处理器会读写缓存。在写缓存操作进行到时候，缓存可以被配置为write-through或者write-back。如果write-through开启，那么当缓存中的一些线被更新，与之相关的主内存位置也会被更新。如果write-back开启，在缓存线被释放之前对其更改不会被立刻写入到内存中，直到缓存线被deallocated。从该角度看后者比前者更加高效。在x86架构上，每一个内存页都包含了控制位用于关闭页面缓存和write-back缓存。而Linux内核会清除在所有内存页面上的控制位所以默认情况下所有的内存访问都是通过write-back方式来缓存。

* 在多处理器的系统上，如果进程更新内存中的缓存线。那么其他处理器也会做同样的动作。这种情况称为cache snooping并在系统硬件上被执行。




### 补全 CPU cache类型图片


### CPU的缓存：
* 不同类型的CPU缓存会影响服务时间：直接映射、全关联、部分关联
* 直接映射缓存是最一种最廉价的缓存。每一个缓存线都映射到内存中的一个指定位置上。
* 全关联缓存是最具灵活性并且也是最贵的一种缓存。因为其需要通过电路图执行，全关联缓存可以缓存内存中的任意位置。
* 而很多系统会折中地使用部分关联缓存。部分关联缓存也称为n路部分关联缓存。这里n是2的倍数。部分关联缓存可以使内存位置被读取到缓存的n个线中去。因此部分关联缓存提供了一个折中方案。

* 缓存线在128位内存中被映射为线。在使用P4 CPU或更好的Intel平台上，缓存线是128字节，而早期的处理器使用32字节的缓存线。
* 现代计算机都使用缓存来提高性能。缓存比内存快很多。一般主内存的访问时间为8ns，而缓存的访问时间和CPU的时钟频率一样小。并且很多计算机都有多级缓存。其中L1缓存很小一般集成在处理器芯片中。L2缓存会比L1大但也比L1慢。很多系统会有部署在CPU之外的L3缓存，尽管速度比L2慢但还是要比主内存快。
* 现代计算机使用多种不同的内存来确保CPU在工作的过程中始终有不同的内存来提供所需数据。在所有的存储器中最快的是CPU自身的寄存器。这些寄存器与CPU采用同样的时钟频率工作。但遗憾的是这些寄存器只能提供很小的空间而且一般成本极高。
* 缓存信息的查看可以通过命令x86info –c进行，而且一般缓存信息也会在dmesg文件中出现。


### 补全3个CPU的映射类型图片




### 缓存定位
* 当应用程序所需要的数据大部分都可以通过对缓存的访问而不是对内存的访问获得，这个时候缓存的使用率是最高的。因此Cache stride就是指在一个cache line条目上所能够缓存的内存中的信息。
* 应用程序将会按照下面的方式访问数据,如果一个应用程序访问内存位置"X"那么在未来的几个循环中去获取X+1位置上的内容，这种行为叫做spatial locality of reference（立体定位），他对将磁盘中的数据以页面形式逐页移入内存的动作比较有效；而另外一种形式是temporal locality of reference（时间定位），即在一个时间周期内应用程序会周而复始地访问内存中的同一个位置。
* 缓存系统并不是在所有的时候都有用。一些程序员也可以开发不使用内存的应用程序。只有顺序访问内存的应用程序才会因cache而提升性能。
* 如果产生对新的内存位置的访问，进程需要清空当前的cache内容并重新缓存新的信息，这样将造成内存访问的延迟。但通常cache可以补偿这种延迟，不过应用程序就未必能够有这种优势。因此在一些程序中提供了其他的内存访问机制而不需要cache。
* 如果要查看缓存的使用情况，可以使用命令：valgrind --tool=cachegrind program_name，该工具能够实现，模拟缓存使用情况；指定L1，L2以对应CPU缓存；但程序在valgrind下会比较慢。


#### 如果要提高缓存定位
* 手动优化代码：确保数据结构能够被缓存；使应用程序可以循环读取同样的数据。
* 使用编译器的自动优化功能。
* 在对应用程序进行编译的时候可以通过给编译器传递一些选项来实现优化。默认情况下这些优化选项是关闭的，因为这些选项开启会导致更长的编译时间并且增加debug的复杂度。如果开启这些选项则会使编译器增加编译时间或者代码大小。
* Gcc编译器支持很多优化选项。另外在x86架构上，-mcpu选项可以防止产生在其他架构上运行的代码，而-march选项会产生只在指定CPU上产生的代码，这样将降低兼容性但是能够提高性能。

### 调度
* 1个时间只有一个进程占着cpu在运行.多任务实际是单个cpu下,将CPU划分时间片来让大家轮询使用.看起来像多任务.
* 多核的多线程的多任务的可以更加好的表现.
* CentOS-5 调度算法是O1算法.最好的比较优秀的算法.O1算法:优先级 0--139,140个优先级.我们可以调节的是100-139 最后40个,0-99为时时优先级,内核控制.

        * 在Linux 2.4内核上，多个CPU之间只会使用一条运行队列，这样针对对称多处理器架构，在多个处理器之间以一个队列来分配任务，效率会比较低。
        * 和2.4内核不同的是在2.6内核上每一个CPU核心有两个运行队列：active和expired。最开始的时候，过期队列为空，当一个进程为可运行的时候，会被放到active队列中，但一个任务在active的运行队列中用尽他的时间片的时候，他会被计算一个新的优先级并被放到expired队列中去。当所有在active队列中的进程都耗尽CPU时间片的时候，内核只会将active队列变成expired队列，并将原来的expired队列变成active队列。在调度之前给进程指定不同的队列将有效减少竞争时间。
        * 当进程被放到active queue中的时候，进程必须被标记为TASK_RUNNABLE，在active queue中的第一个进程会上CPU。队列按照优先级来存储。直到进程占先的时候才会运行。当进程占先之后也会被放到expired队列中，所以active和expired队列会在active队列为空的时候相互交换。    
* CentOS-6 & 7以后,引入CFS调度算法.

        * CFS使用红黑树..自平衡的二叉查找树.  完全公平. 最后一级没有叶子.. 树根为黑书.每个树根有2个子….不能再有.右边的值永远大于左边的值.搜索效率提高.
        * CFS 搜索的时候用的是O1的技术, 插入的时候用的是Ologn. 这样做是为了解决写的比较差的程序,(高优先级,,但是工作效率差……)…只要等待的时候够久,就会绝对为你服务,Virtual time.一旦被CPU执行,那么Virtual time 时间就会减少…

### 优先级
* 一般进程的优先级为140个，其中0为最高而139为最低；优先级0和实时优先级99相同，而优先级1和实时优先级98相同，以此类推。一般进程在启动的时候，如果没有对其优先级进行任何修改，一开始就会被指定优先级为120。
* 在top命令中，PR字段会显示该进程的优先级（减去100）。
* 初始进程从SCHED_OTHER开始，在进程建立的时候，每一个进程都会在一定时间带有其父进程的调度算法和优先级。
* 队列分类：
        每个进程都可以按照一定的策略和优先级被调度。
        静态优先级1-99：SCHED_FIFO和SCHED_RR
        静态优先级0（动态100-139）：SCHED_OTHER和SCHED_BATCH

        SCHED_FIFO：
        这是最简单的策略，采用标准的占先规则；
        
        SCHED_RR：
        与SCHED_FIFO一样，但是增加了时间片，优先级越高（数字越小并接近1）则拥有越长的时间片。当时间片超时则会占先。并重新插入优先级队列之后；
        
        SCHED_OTHER：
        计算一个新的进程占先的内部优先级，范围为100-139；

        SCHED_BATCH : 批量,大的进程,大量操作. 例如数据整理,压缩. 比较倾向与不被抢断
	SCHED_IDLE: 空闲. 只有空闲的时候执行.

* 通常情况下进程具有0-139个优先级，0最高而139最低。而优先级0相当于real time优先级99，而1则相当于实时优先级98并以此类推。动态进程无法通过nice去进行调整并从120开始初始化。如果使用top命令RR区域会显示进程优先级（减去100）。
* 整个进程的优先级范围是从0-139，其中0-99是real time优先级，这段real time的优先级是不能用nice和renice命令来调整的，而只能用chrt来调整。而能用nice和renice来调整的范围只能从100-120，实际的理论和书上的明显不一样，从0-139的优先级顺序一定是从高到低，不会像书上说的real time优先级从0-99之间从低到高。

### SCHED_OTHER
* 拥有相同优先级的进程会在每20ms的时候尝试使该进程占先以防止CPU出现starvation的情况，而CPU会在进程占先之后对其优先级加5作为惩罚；
* 交互式的任务将在等待I/O上占用时间：
* 调度器会检查每一个进程在等待I/O上所使用的时间并为其计算一个平均睡眠频率；较高的睡眠频率意味着是交互式的进程；交互式的进程会被重新插入到active队列，如果没有被插入active队列，其优先级则会在-5之后被移动到过期队列中；
* 调度算法SCHED_OTHER会使进程拥有动态的优先级，其优先级完全取决于kernel和用户对其所进行的调整。开始的时候进程的优先级由nice值（通常为0）决定。同时该值可以通过命令nice和renice来指定。对于内部默认进程其优先级是120，因此一个进程在开启的时候会对其增加19，这样那个进程的优先级就是139。交互式的任务将花费时间等待I/O，因此调度器将检查每一个进程等待I/O的时间并计算出一个平均睡眠时间。如果平均睡眠时间比较高，则证明进程将插入活跃队列，否则会将优先级-5并将其移动到过期队列以进行优化。
* 如果使用的拥有相同优先级的进程会在每20ms之后尝试占先以防止CPU空闲。在占先动作之后CPU会对该进程的优先级+5。
* 对列调度器的调整策略：
        针对SCHED_FIFO，使用chrt –f [1-99] /path/to/prog arguments
        针对SCHED_RR，使用chrt –r [1-99] /path/to/prog arguments
        针对SCHED_OTHER，使用nice和renice来调整

 ### Viewing CPU performance data
* 查看CPU性能方面数据的方法：
* 查看平均负载：运行队列的平均长度
* 需要考虑在TASK_RUNNABLE和TASK_UNINTERRUPTABLE这两个数值，使用命令：

    sar –q 1 2 查看队列以及load average；top；w；uptime

    而CPU使用率：

    mpstat 1 2 查看每秒中断数；sar –P ALL 1 2；iostat –c 1 2；/proc/stat

### 内核时钟和进程延迟
* 在x86架构的服务器上，硬件时钟通常有下面的几种：
* 实时时钟RTC：主要用于在系统关机的时候维持时间和日期信息并可在开启的时候利用该时间设置系统时间,其信息在/proc/driver/rtc中。
* 时间戳时钟：这是一个寄存器，该寄存器会以和CPU晶振相同的频率更新。其主要功能是提供高层计数器用于和RTC一起计算时间和日期信息
* 高级可编程中断控制器：APIC包括了本地CPU计时器，该计时器用于跟踪运行在CPU上的进程并使该进程从本地CPU到多CPU过程中产生中断
* 可编程中断计数器PIC：可用内核中所有通用的始终保留动作，包括进程调度等
* 在x86架构的系统上，Linux使用PIC作为处理中断的计数器在固定的周期内产生中断。在RHEL3以及更早的使用2.4内核的系统中，频率为100Hz，这就意味着在每10ms产生一个节拍。在RHEL4以及2.6 Linux内核版本的系统上频率提高到1000Hz，意味着每1ms产生一个节拍。但实际上这个产生节拍的频率是可调的，尽管在内核编译的时候已经预定义好。我们通过在启动选项中增加内核参数来实现。更短的tick对于一些对时间比较敏感以及一些多媒体程序来说是有利的，但也可能使一些应用程序运行得比较慢，因为内核需要更多的资源来处理产生的大量中断。

### IRQ中断平衡
* 在2.6版本的Linux内核调度器中一个比较出色的设计是一些内核集成可以像其他进程那样被占先和调度。这样对于一些要求低延迟的任务，如处理网络I/O的任务来说，来说是有好处的。例如内核可以运行一个handler并对用户态进程执行disk I/O，并且从网卡接收中断。
* 通过/proc/interrupts中，可以查看当前哪个CPU在负责哪个中断。CPU是需要处理中断的，IRQ balance是RHEL5中的一个服务，主要用于平衡在不同CPU上的中断数量。如果一直让一个CPU处理中断，感觉该CPU会非常繁忙。所以一般每10s，IRQ会被均衡一次。
* 但需要注意的是，如果在系统启动的时候加入了noapic参数，irqbalance将被禁止。
* cat /proc/interrupts

### 调节 IRQ affinity

* 对IRQ亲和度的调整包括：修改/etc/sysconfig/irqbalance，加入”one-shot”参数，表示开机之后只进行一次IRQ中断平衡，之后再不进行中断平衡。如果要关闭irqbalance功能，可以选择chkconfig off这个服务。

* 或者通过下面的命令将irq中断固定在某个CPU上。

* 对IRQ亲和度的调整：

  ```	
  echo cpu_mask > /proc/irq/<interrupt_number>/smp_affinity
  
  命令的时候，如果echo的是0则表示第一个CPU，1表示第二个CPU，3表示前两个CPU。
  
  好处是，让关键的CPU避免做IRQ服务，而腾出工作时间让其专门处理进程。
  
  CPU_MASK是二进制的表示方法。
  
  ```
### Equalizing CPU visit count

* 当一个进程被抢占（占先）之后会被移到过期队列中。当计算机运行到一定程度，可能会出现某些CPU很繁忙，而某些CPU很空闲。所以一般当所有CPU都很忙，则每100ms做一次balance，而当有一个CPU很闲，则每1s做一次balance。一般我们通过ps的psr参数知道，哪些进程运行在哪些CPU上。
* 总之所有的原则是，在系统运行过程当中，即让所有的任务在不同的CPU之间分散。
* 但分散任务会产生问题，即分散不同的任务，会导致重新cache，所以在多核心CPU的结构上一般会使用共享cache。而且在NUMA环境下，均分任务还是有好处的。
* 在对称多处理器架构中，每个物理CPU都有自己的运行队列。对于超线程的CPU来说，逻辑处理器使用和物理CPU一样的运行队列。当一个进程在CPU上使用完所有的时间片，则会被移动到该CPU的过期队列中。因此CPU都有一个默认的进程亲和性，即更倾向于将进程运行在某个CPU而不是其他CPU上。而且因为每个CPU都有自己的cache，所以进程运行在原来的CPU上，一旦该进程重新获得CPU的时间片就不需要重新对缓存进行初始化。否则当进程在不同的CPU之间移动的时候，会因为重新初始化缓存而对性能造成影响。
* 当然在这种情况下，如前所述，平衡CPU访问量的工作会默认进行。

### 使用taskset命令来平衡进程的亲和度：
* 主要的目的是将一个或者多个进程指定到固定的CPU上。例如：taskset –p 0x00001 1
* 这样操作的目的：提高缓存命中率，减少等待时间；
* 命令taskset的语法：taskset –p CPU_MASK 进程号

### Tuning run queue length with taskset
* 通过taskset来调整运行队列长度：可以通过在grub中加启动参数来使得某个CPU在开机之后不被使用，除非使用taskset将某个进程指定到该CPU上。因此该功能一般和taskset联合使用，主要用于将一些关键业务或者严禁中断的功能固定指定到某个CPU上。

### 实现基于软件的CPU热插拔：
```
热拔某个CPU：

echo 0 > /sys/devices/system/cpu/cpu1/online

cat /proc/interrupts

热插某个CPU：

echo 1 > /sys/devices/system/cpu/cpu1/online

cat /proc/interrupts

而基于硬件的CPU热插拔需要BIOS的支持，多用在NUMA架构上。该功能在RHEL5中实现。

```

###  SystemTap
* 任何由kprobes在系统所产生的系统调用以及100%的CPU事件都可以被SystemTap进行profile。
* Kprobe机制是内核提供的一种调试机制，它提供了一种方法，能够在不修改现有代码的基础上，灵活的跟踪内核函数的执行。它的基本工作原理是：用户指定一个探测点，并把一个用户定义的处理函数关联到该探测点，当内核执行到该探测点时，相应的关联函数被执行，然后继续执行正常的代码路径。
* Kprobe提供了三种形式的探测点，
        
        1、一种是最基本的kprobe，能够在指定代码执行前、执行后进行探测，但此时不能访问被探测函数内的相关变量信息；
        2、一种是jprobe，用于探测某一函数的入口，并且能够访问对应的函数参数；
        3、一种是kretprobe，用于完成指定函数返回值的探测功能。其中最基本的就是kprobe机制，
        jprobe以及kretprobe的实现都依赖于kprobe，

* 主要通过将一个脚本编译到内核模块中，该脚本语言类似awk，并且非常便携。而在生产系统中通常没有编译器。所以在开发服务器上需要将脚本编译到内核模块中，在生产服务器上部署该内核模块，确保完整的内核release信息在开发和生产服务器上。
* 曾经从实时运行中的内核中收集信息是一个非常复杂的工作，并且需要具备丰富的内核方面的知识。因此如Oprofile和LTT这样的工具就被开发出来用于探测Linux内核所执行的工作。探测会以一定的频率进行，并且会将结果保存到相关文件当中。
* SystemTap则是处于这种目的被开发出来以方便对内核没有深入了解的系统管理员获得内核运行方面的信息。如内核当前在运行什么样的应用程序等，因此相关工作则被大大简化。
* 和其他的工具相比，SystemTap拥有显著的特点，即可以百分百准确地提供内核运行的信息，探测的精度得到了显著提高。这就意味着所有的内核事件，不管执行事件是多长，在何时结束都将被获得和监测到。这也是SystemTap优于Oprofile的地方。
* SystemTap运行于kprobes的基础上，kprobes是内核的一个子系统，该子系统方便开发者通过内核模块将代码附加到任何的内核功能上。使用kprobes需要内核开发知识和技巧。因此这也是为什么kprobes完全从SystemTap的用户接口上透明的原因。
* Systemtap完善了oprofile的所有缺点，他使用了kprobes这个kernel子系统。通过脚本式的方式来协助我们做性能评估。通过systemtap，我们可以书写一个模块加载到kernel中实现性能评估，任何事件都不会被遗漏，因为是基于函数调用，只要有事件发生就可以捕获。可将书写的stap脚本编译为kernel模块并插入到kernel中。
* 一般systemtap有两类，一种是生产环境，一种是开发环境。在开发环境需要脚本，在开发环境中编译好脚本为模块之后，在生产环境就可以启用该模块。前提是两边的版本号必须相等。
* Required packages: rhel-debuginfo.repo.

 ### SystemTap scripts

* 任何时候只要有人调用foo函数，则会被捕获到，并针对该事件做一些处理。在Linux下任何时候只要有函数存在kernel就会知道。整个Linux的kernel都是基于函数调用。由于函数中有功能叫做return，所以返回的时候会被捕获到。

* See /usr/share/doc/systemtap-*/examples

* SystemTap使用的脚本以点编辑并支持通配符；

* 所包含的功能：

  ```
  /usr/share/systemtap/tapset
  man –k systemtap
  经常使用的探测点都可以被SystemTap的脚本探测，与IO调度器、网络、NFS、内存管理、处理器、SCSI和信号子系统相关的探测器已经提供。
  ```

* The stap command

  - 一个重要的参数：-k     
  - -p用于指定过程是其中的第几个，完成该过程之后就停下来；
  - -e表示不想输入一个文件而直接带脚本；
  - $ stap -e 'probe syscall.open {printf("%s: %s\n", execname(), argstr)}'
  - 在生产环境中通过staprun将编译好的模块加载进去。
  - staprun /path/to/module.ko 


## 参考实验 --进程优先级：

1、对比一个进程在两个不同优先级情况下执行某个程序时候的时间，首先建立下面的脚本counter.sh：

```
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
```

2、然后建立另外一个脚本launch.sh：

```
[root@dom-0 ~]# ll launch.sh 
-rwxr-xr-x 1 root root 197 May 30 22:58 launch.sh
[root@dom-0 ~]# cat launch.sh 
#!/bin/bash
xterm -geometry 40x20+50+20 -title "NicePlus10" \
-e nice -n +10 ~/counter.sh 1 &
xterm -geometry 40x20+500+20 -title "NiceMinus10" \
-e nice -n -10 ~/counter.sh 100001 &
```

3、然后执行脚本launch.sh，观察哪一个进程先结束，并且观察一旦高优先级的进程结束，低优先级的进程有什么样的变化。



## 参考实验 --进程优先级：使用nice命令：

测试nice命令的有效性。我们将看到低优先级的进程如何获得比高优先级进程更少的时间片而导致运行更慢。

1、首先建立一个脚本：
```
[root@dom-0 ~]# ll busywork 
-rwxr-xr-x 1 root root 59 May 30 23:20 busywork

[root@dom-0 ~]# cat busywork 
#!/bin/bash
for i in $(seq 1 100000)
do
j=$(($i+1))
done
```

2、另外执行命令：
```
# cat /dev/zero > /dev/null

因为要确保测试进程在执行的时候，另外一个程序在以同样的优先级使用CPU。
```
3、执行脚本
```
[root@dom-0 ~]# time ./busywork 

real 0m1.261s
user 0m1.206s
sys 0m0.038s

这个结果显示，busywork在运行的时候在CPU上花费的时间是1.206 ＋ 0.038秒。
```

4、而如果将程序的优先级调低：
```
[root@dom-0 ~]# time nice -n 19 ./busywork 

real 0m1.339s
user 0m1.208s
sys 0m0.039s

似乎在CPU上花费的时间和上个测试相同。但是按照书上的理论，这个值应该比上个值要慢。
```

## 参考实验：安装systemtap：
1、 SystemTap的安装需要和当前使用的内核版本一致的kernel-debuginfo，kernel-debuginfo-common和kernel-devel包。之后确保systemtap包已经安装。
２、 通过执行下面的命令确保systemtap正常工作，该命令会建立一个包含所有kernel function的文本。
```
[root@dom-0 ~]# stap -p2 -e 'probe kernel.function("*") {}' | sort -u > kernel_function 

[root@dom-0 ~]# less -FiX kernel_functions
```

３、使用systemtap监控上下文开关（context switch）：在系统中，上下文开关无时不存在，当进程等待事件的时候，上下文开关就会被替换。而且，由于进程一般在CPU上运行的时间只有数毫秒，因此上下文开关只有在进程不等待外部事件的时候发生。因此这会对性能产生一些影响，并且我们可以通过systemtap来监测。上下文开关一般会替换一个叫做schedule（）的kernel function。建立一个叫做csmon.stp的systemtap的脚本，可在这些功能生效的时候显示出“Scheduler invoked”。

３、编写脚本
```
[root@dom-0 rh442]# cat csmon.stp 
probe kernel.function("schedule").return {
printf("Scheduler invoked")
}

[root@dom-0 rh442]# pwd
/root/rh442

注意，脚本实际上在通过stap运行的时候会产生所需要的模块，并且在stap运行的时候会自动将该模块加载上去，所以stap命令是在production server上运行。
```

4、执行stap，可以发现由于schedule()这个function普遍存在，所以在屏幕上会有大量的标记输出。
```
[root@dom-0 rh442]# stap csmon.stp 
```

5、但假如我们将脚本更改一下，例如改成如下内容，那么systemtap只有到context switch到达10000的时候才会计数并显示信息在console上。
```
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
```

6、或者可以将脚本改成如下内容，表示每5s给一个report，显示出哪个进程执行context switch最为频繁，并且所有结果由高到低排序。
```
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
swapper 859
systemtap/0 499
firefox 195
kondemand/0 124
Xorg 93
scim-launcher 49
gnome-terminal 27
gnome-power-man 24
escd 17
vpngui 10
migration/0 7
migration/1 7
stapio 6
sh 3
modclusterd 2
ksoftirqd/0 1
--------------------------------------
```

7、同时也可以像下面这样修改脚本，表示将以每10s作为固定频率显示30个进程的content switch，并由高到低排序：
```
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
swapper 818
systemtap/0 523
firefox 101
Xorg 75
gnome-power-man 52
stapio 43
scim-panel-gtk 33
gnome-terminal 26
vpngui 15
hald-addon-stor 11
clustat 9
kjournald 5
thunderbird-bin 4
pcscd 4
aisexec 2
gnome-screensav 2
rpc.idmapd 1
kblockd/1 1
gdm-rh-security 1
------------------------------------------
```

8、下面的脚本配合systemtap将列出产生最多sys_open调用的进程，而且会将所有结果从高到低排序。这个脚本将有助于查看哪个进程频繁地打开文件：
```
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
Process Count
pcscd 180
ifconfig 18
sh 16
clustat 7
modclusterd 6
env 6
gpm 3
hald-addon-stor 3
scim-panel-gtk 2
```

