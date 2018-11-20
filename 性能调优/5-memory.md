## Memory

### 虚拟地址和物理地址
从286开始，虚拟地址空间和物理地址空间的概念已经被引入，在386时代得到了完全的发展；
在Linux系统运行时，任何一个进程都拥有4GB的虚拟内存可使用，而物理内存往往没有4GB大，但是系统不关心，因为应用程序同时使用4GB内存的概率基本为0；
Kernel一般能够访问物理内存地址，而应用程序只能访问虚拟内存地址；

在使用虚拟地址的过程中，存在虚拟地址到物理地址的转换，转换的基本单位是页帧（page frame），因此在真正物理地址上使用的是页帧。在x86架构上，不管是32bit还是64bit，页帧的最小单位为4KB。但是随着用户应用需求的变化，在当今CPU上支持非4KB的页面，即大页。
虚拟地址到物理地址翻译的工作由MMU来完成。一个虚拟内存地址进入到MMU被翻译成物理地址才能使用真正的内存。缺点是每访问一次都要花时间，且MMU很贵，翻译过程会占用时间。所以一般CPU会内嵌buffer将其缓存。
理想的例子是系统中只有一个进程，而且该进程使用完所有的内存。
但实际情况是系统中的进程在使用过程中不断申请内存和分配内存。
虚拟内存地址逻辑上是连续的，但是物理地址可以不连续（尽管很多时候我们会尽量要求其连续）。一个页面可以在内存中存在，也可以被交换出去（swap），在内存不足时发生。页帧一般会被彻底镜像到虚拟内存地址的最高空间。即假如虚拟内存是4G，那么0-3G不用，尽量将page frame镜像到最后一个G。即0-3G是进程在使用，而剩下的一个G是由kernel使用。低端物理内存是要由kernel立即访问的。

### 查看进程地址空间
进程所使用的虚拟内存地址往往可以通过一些工具来查看。
比较常用的是/proc/<pid>/statm。另外pmap命令可以显示进程所使用的虚拟地址空间。还有另外一个命令gnome-system-monitor，可以显示进程所使用的虚拟地址。
在内存中，一个进程运行时需要的页面数量叫做进程的工作集（working set）。一个进程的工作集在进程的生存时间中不断变化。为了给其他进程在物理内存中的运行提供空间，内核会不断将进程工作集中不用的页面进行调整。如果进程工作集中的某些页面包含了修改过的数据，这些页面必须被写入到磁盘中。如果进程工作集中的页面不包含数据，那么内核只是简单地为其他需要内存的应用程序重分配页面。
有时候内核在处理这些工作的时候会占用过多的资源和时间。
另外memusage命令可以查看应用程序的堆栈和其他数据，需要通过安装glibc-utils获得。

### 调节进程地址空间
通过pam_limits.so来调整系统参数：
1. Update /etc/security/limits.conf
bart hard as 15					限制用户虚拟内存空间使用：as，单位K；
@finance hard as 20
@jre hard stack 100
• Limiting resident set size (rss) is not currently implemented
2. Log out and log in
• Non-privileged users can use ulimit to:
非特权用户可以使用ulimit来实现：
• View their own limits
• Adjust their own soft limits 

但真正控制物理内存使用（RSS）在Linux系统上还未实现。用户重新登录之后方可生效。而且普通用户只能够修改soft值而不能修改hard值。

### 物理地址空间
由于通过MMU分页的过程非常昂贵，所以将所有的Page table entry（PTE），通过TLB（页表项）进行缓存。缓存的优点：第一次访问经过MMU，而第二次以及后续访问可以通过TLB缓存获得以提高速度。通过下面的命令可以查看page size：
x86info -c
dmesg
getconf -a | grep SIZE
地址翻译的过程存在于TLB中。

在内存使用过程中kernel永远不会被交换出去，而且kernel本身会跟踪内存使用。
每个页帧代表一个内存真实页，因为页帧带描述项。

每个进程都有自己的页表，页表的作用就是从虚拟地址到物理地址部分的寻址。

所以整个过程是：
内存的使用是由虚拟地址和物理地址之间映射实现，期间由CPU的MMU来进行翻译,并且可以buffer在TLB中。而应用程序只使用虚拟内存。


为了高效，计算机上的内存被划分成固定大小的空间，称为page。根据CPU的不同，page的大小也有所不同。在x86架构上，默认的page大小是4KB。但是需要注意的是一个page的数据并不一定要和内存中的一个page对应。在计算机上，内存被划分为页帧，每一个内存的页帧会包含一个页的数据。当应用程序需要访问某个位置的内存，线性地址必须被转换成内存中相应的页帧。如果所需要的页在内存中不存在，内核必须找到该页并且将其读取到页帧中。
很多处理器架构支持不同大小的页面。在32位系统上支持4KB，2MB，4MB的页大小。在64位系统上支持4KB，8KB，64KB，256KB，1MB，4MB，16MB和256MB大小的页。TLB的数量一般是固定的，但对于大页，TLB可能也会增大。所以TLB的条目指向的内存越多，意味着TLB的命中率会越高。
当运行在系统上的程序访问内存的时候会使用线性地址。在32位架构上，线性地址是32位，因此最大寻址空间是4GB，一般线性地址并不对应真实的物理内存。为了访问物理内存，线性地址被转换成PTE。


### 内存分配
在内存分配的时候基本操作方法：
在Linux每创建一个进程的时候，不会立即将父进程的内存拷贝一份。所有的进程都是从init进程派生出来（fork）的，但是在每个子进程派生出来之后，先和父进程使用同一块内存地址空间。只有当父子进程写内存的时候，即发生变化，会产生一个技术性的失败（copy on write）才会将内存复制一份。这样做是为了让内存最大限度地最晚分配出来。针对多线程的进程则优势明显，将变化的部分放到其他地址空间，速度快，开销小。
当一个进程需要内存的时候，一般kernel都会予以分配，即便物理内存可能已经不够的情况下。因为绝大多数已经存在的进程申请的内存不会立即被使用，所以kernel会将这些内存中不用的一部分释放给新的进程使用。所以原则上kernel会尽可能推迟内存的分配。
例如编写一个C语言的程序，当申请内存的时候会发现kernel立即分配，但是这只是一个假象。除非代码把申请的内存立即遍历和写入所有信息，才会将申请到的内存占用。
申请内存的时候会产生技术性的失败（page fault）：一种是严重失败，另外一种是轻量失败。
轻量失败一般指的是承诺的内存没有分配；而严重失败一般指的是产生交换，即从内存到硬盘的交换。由于硬盘的I/O很慢，所以是严重失败。
所以通过命令：
ps -o minflt,majflt <pid>
可以看到进程有多少轻量失败和严重失败。

当进程使用完内存的时候，kernel也会对其进行回收，而且回收内存也可以调优。策略性回收还是立即回收等等。

###  静态和动态内存
Static RAM (SRAM)
• Keeps data without updating
• Dynamic RAM (DRAM)
• Must be refreshed
• Synchronous DRAM (SDRAM) is synchronized to CPU clock
• Double data rate DRAM (DDR) reads on both sides of clock signal
• Rambus DRAM (RDRAM) uses a high-speed, narrow bus architecture

静态内存实际上就是CPU的cache，静态内存设计复杂，但其中的数据会一直有效；
动态内存变化性非常高，动态内存每读取一次，电压都会减少，读的次数越多电压衰减就越快，一旦电压衰减为0数据会出现丢失。但动态内存的设计比较简单，成本低廉。

### TLB 增强
Kernel每次在做context switch的时候会做一次context flush。清空所有的内容。
一般context flush的频率非常高。即TLB被清空，下次再读取进来的时候会降低性能。
因此如何提高性能？答案是尽量使用物理连续的内存区域，这样可以让TLB的开销比较少，一般该工作是由kernel来实现。Kernel发展到至今，产生了buddy system（兄弟算法），buddy预先占用一定内存，即将一些小页面都统一放到一个大的区域中，即尽量让相同的内容放到同一区域，这样连续性比较高。
一般buddy不需要干预。
而需要干预的是huge page，即大页。即一次性给足比4K大N多倍的页面，以降低TLB的访问频率和提高TLB的cache命中率，这样同时也降低了MMU的频率。
/proc/buddyinfo

### 调整TLB性能：
1.	查看系统上目前的大页大小，通过x86info或者dmesg或者cat /proc/meminfo获得；
2.	开启大页支持：修改/etc/sysctl.conf，参数：vm.nr_hugepages=integer
3.	启动系统的内核参数：huges=integer	预存大页的大小 （这种方法比较保险）
使用的方法：
函数调用中有shmat和shmget可以自动调用大页，如果使用mmap读文件，则需要建立一个虚拟文件系统，将其挂载出来，以上述方式挂载。在该目录中使用的对象实际上是大页，从硬盘中拷贝过来的数据，在内存中的物理状态是连续的，因此效率相对较高。而且这种方式也可以作为ram盘来使用。

### memory cache
除了应建的cache之外，在Linux的kernel中cache也是普遍存在的概念。这些cache都和内存有关，但主要的目的就是尽量减少kernel对磁盘的读取。在所有的cache当中，最重要的是page cache，page cache在磁盘I/O中起核心作用。

内存使用的原则：
针对小的内存对象减少开销；Kernel还有一个实现的方法：slab，也是一种buddy system。Slab设计的初衷就是有利于类似的结构体的申请。
文件系统的元数据，无论读文件和目录，都会以slab对象进行缓存buffer cache；
而disk I/O也称为page cache，page cache大小需要和page size相当；
而drop cache可以将buffer cache和page cache同时丢弃；
进程间通讯，使用的是共享内存，原因是：一、进程间会话；二、相同的内存在只读的情况下可以共享；
网络所有的I/O都可以进行buffer，例如接收和发送的buffer，arp缓存，链接状态跟踪等；

当考虑调整内存的时候，需要考虑：
什么时候丢弃cache什么时候不丢弃cache？即什么时候回收内存？如果不回收内存，会造成normal zone产生很大压力；但如果频繁回收内存，cache得不到最大的发挥。因此需要找到平衡点。
所以产生两种方法：
如果将大量的I/O分成小片，这样的话对系统的吞吐量没有明显的感觉；
如果让巨大的I/O瞬间执行完毕，可能排序会更加优秀，但有可能会让用户感觉明显的迟钝。
 
### 内核申请内存的思想：根据需要进行页面缓存
页帧的请求一般不会导致内存立即申请，只有在真正使用的时候才会将某部分内存的使用从虚拟内存空间转换成为RSS，还有一些可能是内存的交换；
因此通过这种行为，kernel可以帮助我们实现overcommit，也就是说申请超出实际物理内存的内存量。这种行为一般对科学运算等方面的程序更加有用。而真正可以使用的物理内存实际上是物理内存+SWAP，如果进程使用内存超过这个值，就会产生out of memory，并且产生oom-killer而随机杀进程；
一般来说，延迟内存的分配直到应用程序真正使用它们会对系统的性能提升带来很大好处。因为很多应用程序尽管申请大内存，但是不会在申请的同时立即使用它们。一旦开始针对一个应用程序分配内存，并不是所申请的内存所有部分都被使用，所以未被使用的部分将被拒绝分配。
另外一个需要明确的概念是kernel和用户态进程都得益于虚拟内存。所不太一样的是，当一个kernel进程请求新的内存页面的时候，这个请求一般会立即得到处理。而用户态进程则不一样，在他们请求内存的时候，只有当内存真正被需要的时候才会分配。这种设计会带来一些好处。因此在应用程序真正需要的时候才分配内存就叫做按需分配——demand paging。

### 调整页面分配：
vm.min_free_kbytes：
这个参数针对某些应用程序经常申请超大的内存然后释放，并频繁进行。由于申请超大内存有两种情况：第一是应用程序的确需要申请超大内存；第二是作为buffer；
所以指定该参数表示，表示内核在进行cache过程中，指定部分为应用程序申请内存使用，而不是被buffer。虽然应用程序在申请内存发现内存不够的时候会出现minor page fault。
对提升应用程序的性能自然有好处，因为应用程序申请内存时候都能满足要求，但是可能会对normal zone产生一些压力。
 
 ### 调节 vmcommit
 Tuning overcommit
• Set using
vm.overcommit_memory
• 0 = heuristic overcommit
• 1 = always overcommit
• 2 = commit all swap plus a percentage of RAM (may be > 100)
vm.overcommit_ratio
• View Committed_AS in /proc/meminfo
• Consequences
• Allows kernel to satisfy requests for large virtual address space
• Warning: processes will core dump if out-of-memory (OOM) occurs and memory is overcommitted

vm.overcommit_memory参数中
0：表示不提供多余内存；
1：申请多少内核就分配多少，只要不写实际数据则OK，但是一旦写入一定量实际数据，则可能会产生oom-killer随机杀进程，而且杀死的多是用户级进程；一般每个应用程序都带有oom-likely，即更倾向于被杀死的程度；
2：默认正在使用。如2+50%，表示总的交换分区的大小+50%内存的大小是总共可以承诺的内存，即物理内存的150%+交换为总共可以承诺使用内存大小；
比如物理内存为1，交换分区为2，那么可使用的值应该是1x1.5 + 2，为kernel承诺应用程序可以使用的内存的大小或者承诺应用程序可以申请的内存大小；
vm.overcommit_ratio
默认为50，但可以按照需求调整。
另外在/proc/meminfo中的Committed_AS表示还需要多少RAM就可以避免OOM的情况出现。

### Slab cache
• Monitoring:
/proc/slabinfo
slabtop
vmstat -m 
小的内核对象被保存到slab中。
对于slab的解释：
指的是内存管理单元先向伙伴系统申请一块较大的物理内存（批发），然后再将其肢解成许多小碎片分配给需要的进程（零售）。当有的进程需要分配一小块内存（一般都小于一个页面，或不是页的整数倍），用来存放某个数据结构（如vm_area_struct），都可以向slab申请零售。

### ARP cache
 ARP entries map hardware addresses to protocol addresses
• Cached in the slab (grep arp /proc/slabinfo)
• Garbage collection removes stale or older entries
• Insufficient ARP cache leads to
• Intermittent timeouts between hosts
• ARP thrashing
• Too much ARP cache puts pressure on ZONE_NORMAL
• List entries
ip neighbor list
cat /proc/net/arp
• Flush cache
ip neighbor flush dev eth0 

ARP主要用于实现IP和MAC地址对应关系：
ARP也是以slab对象缓存在/proc/slabinfo中。显示本机的ARP使用状态：arp –a。
如果ARP缓存不够的情况下，可能会造成thrashing，即不断刷新缓存。因此一般ARP缓存可调。

• Soft upper limit
net.ipv4.neigh.default.gc_thresh2	警告限制	
• Becomes hard limit after 5 seconds	（5s之后会变成硬性限制）
• Hard upper limit
net.ipv4.neigh.default.gc_thresh3	硬性限制	
（放大会对normal zone产生压力）
• Garbage collection frequency in seconds
net.ipv4.neigh.default.gc_interval 
垃圾回收的频率，默认每30s去扫描一次。

因此缓存比较大的情况下，可以将频率调低。

You should adjust the soft and hard limits on ARP cache size if you need to accommodate a large number of
simultaneous connections.
Another tunable for ARP cache is the minimum time in user-space jiffies to cache an ARP entry. Recall that there are
100 user-space jiffies in a second.
net.ipv4.neigh.default.locktime
It is usually not necessary to modify other ARP tunables, but they are described in arp(7). 

### page cache
系统内存有大部分都是在做page cache，主要是在文件读取和文件I/O的时候，例如读目录项、正规文件内容、读写设备文件、mmap函数调用、交换等都会引起page cache。任何时候，在page cache中的数据都是和文件相关。匿名page和page cache都有大量内容从内存中产生，但Page cache和文件相关，不允许被交换；而匿名page是和文件无关的，是可以被交换的。因为page cache是硬盘上已有的内容。

调整page cache的时候：

vm.lowmem_reserve_ratio	
做page cache的时候最小预留多少不做page cache，不要将所有内存都作为page cache；
vm.vfs_cache_pressure
虚拟文件系统做缓存的时候的缓存率，即VFS做缓存的时候有多么倾向于回收内存。如果该值调高，则kernel比较倾向于回收内存若调低了，kernel会比较倾向于让内容留在缓存中；
vm.page-cluster
在做页交换的时候，一次性交换多少页面，若交换频繁，可以调大该值；
vm.zone_reclaim_mode
当值为1的时候，zone normal回收打开；当值为2的时候，若系统专门做文件server，即整个内存全部用于共享文件，缓存page buffer。
 
### 匿名页
匿名配置是和文件不相关的剩余的所有内存单元，可能是程序的数据区、数字、动态分配的内存、有人专门申请的匿名memory区域，可能是mmap对象（非文件）、进程间通讯的内存。统称为匿名page。
一般匿名page的大小是非常可观的。
一般通过/proc/meminfo查看，并且匿名page可以被交换。
一般匿名page=RSS – Shared

### SysV IPC
• Potentially large consumer of memory	隐形的内存消耗因素
• Semaphores		信号令
• Message queues	消息队列
• Shared memory	共享内存
• View SysV shared memory	ipcs查询共享内存的使用状态
• Active usage
ipcs
• Limits
ipcs -l
• Use POSIX shared memory filesystem for fast storage
dd if=/dev/zero of=/dev/shm/test bs=1M count=50 	
该命令可以作为ram盘使用
Another potential consumer of memory is memory set aside for interprocess communication (IPC) mechanisms.
Red Hat Enterprise Linux supports both the older System V (SYSV) style of IPC as well as the newer POSIX IPC
mechanisms.
Semaphores allow two or more processes to coordinate access to shared resources and other behaviors. Message
queues allow processes to cooperatively function by exchanging messages. Shared memory regions allow processes to
communicate by reading and writing to and from the same region of memory.
A process wishing to use one of these mechanisms must make the appropriate system calls to allocate the desired
resources. As a system administrator, you can set limits on the number of SYSV IPC resources available to processes.
Current usage information for SYSV IPC resources can be obtained by running:
ipcs -l
Using /dev/shm for temporary storage can be an effective technique to improve service time for critical
applications. Losing power means that all data in /dev/shm is lost.
There is a corresponding ipcrm command to forcibly remove shared memory segments. Using this command should
be rare on Linux due to the way in which resources are released when a process terminates.


Tuning SysV IPC
• Number of semaphores (flags)
kernel.sem	
• Size and number of messages (non-pageable)
kernel.msgmni * kernel.msgmnb
kernel.msgmax
• Size and number of shared segments
kernel.shmmni * kernel.shmmax
kernel.shmall
• Documentation
man 5 proc
pinfo ipc
The SYSV IPC mechanisms are tuned using entries in /proc/sys/kernel/. The sysctls used are:
kernel.sem contains settings for:
The maximum number of semaphores per semaphore array, default = 250,
一个信号数组最多存储250个信号令；
The maximum number of semaphores allowed system-wide, default = 32000,
信号令的总数是32000个；
The maximum number of allowed operations per semaphore system call, default = 32,
每调取一个信号令最多可以允许多少个操作；
The maximum number of semaphore arrays, default = 128.
信号令数组的个数；

kernel.msgmnb specifies the maximum number of bytes in a single message queue, default = 16384.
一个单独的消息队列最多可以存储16384字节；
kernel.msgmni specifies the maximum number of message queue identifiers, default = 16.
消息队列最多可以有16个；
kernel.msgmax specifies the maximum size of a message that can be passed between processes. Note that this memory
cannot be swapped, default = 8192.
每个消息的最大值；

kernel.shmmni specifies the maximum number of shared memory segments system-wide, default = 4096.
系统最多可以分配多少个共享内存段；
kernel.shmall specifies the total amount of shared memory, in pages, that can be used at one time on the system. This
should be at least kernel.shmmax/PAGE_SIZE, where PAGE_SIZE is the page size on your system (4KiB on x86).
The default for this setting is 2097152.
kernel.shmmax x kernel.shmall / page size  kernel.shmall的最大值，注意：这里的单位是按照page来计算；
kernel.shmmax specifies the maximum size of a shared memory segment that can be created. The kernel supports
shared memory segment sizes up to 4GiB - 1.
一个共享内存段的最大值是4G-1；
 
### Viewing memory with free
• Use free -ltm to view a summary of memory usage in MiB
total used free shared buffers cached
Mem: 1011 615 395 0 119 398
Low: 883 488 395
High: 127 127 0
-/+ buffers/cache: 97 913
Swap: 1983 0 1983
Total: 2995 615 2379
• Calculation of totals for -/+ buffers/cache
used -/+ = used - buffers - cached
= 615 - 119 - 398 = 97
free -/+ = free + buffers + cached
= 395 + 119 + 398 = 913
• Calculation uses actual bytes even though display is MiB

In the output of the free command, the "-/+ buffers/cache" line has a formula. Note that used uses (-) while
free uses (+):
What about the missing 17 MiB of memory? The kernel reserves some memory during boot time.
grep -i memory /var/log/dmesg
Memory: 1032440k/1048512k available (2043k kernel code, 15276k reserved,
846k data, 232k init, 131008k highmem)
Freeing initrd memory: 2301k freed
Total HugeTLB memory allocated, 0
Non-volatile memory driver v1.2
Freeing unused kernel memory: 232k freed
Additionally, the BIOS in some machines maps the physical memory with holes of unusable segments. To find holes,
look for discontiguous segments of memory in dmesg. The following snippet shows a discontinuity between the
second and third segments:
grep e820 /var/log/dmesg
BIOS-e820: 0000000000000000 - 000000000009fc00 (usable)
BIOS-e820: 000000000009fc00 - 00000000000a0000 (reserved)
BIOS-e820: 00000000000e2000 - 0000000000100000 (reserved)


### Other commands to view memory usage
• System memory
/proc/meminfo
/proc/zoneinfo
• Total physical memory
• Memory being used by caches
• Active (in use) vs. inactive
• Page tables
/proc/vmstat
• Summary
vmstat -s
• IO devices
/proc/iomem

The VmallocTotal field in /proc/meminfo reflects the total amount of virtual space for vmalloc. The
VmallocChunk field reflects the largest chunk of free space within the vmalloc area.
See /proc/iomem for memory space that has been allocated to IO devices.
Another utility for monitory memory usage of an application is the memusage script. Install the glibc-utils package to
get this utility.
 
### 几种页面的状态和类型：
Free：可以立即被分配的页；
Inactive Clean：页中的内容已经被写入到磁盘，或者从磁盘读取之后一直没有改变，或者页面可以被分配；即进程使用完，已经被彻底丢弃的页；
Dirty：该页没有进程在使用以及页内容已经更改，但是还没有写入到磁盘，脏页不能够直接分配；
Active：页面正在被进程使用；
举例：
如果将u盘挂载到系统中，一些读写操作之后再umount结束进程，但此时会有很多脏页在系统中，所以需要执行sync，将inactive dirty变成inactive clean。
 
### 如何查看系统中的脏页和干净页数量
cat /proc/1/smaps | awk '
BEGIN { print "Execute before processing input"; }
/* process input */
/Shared_Clean/{ CLEAN += $2; }
/Shared_Dirty/{ DIRTY += $2; }
END {
/* execute after processing input */
print "Shared_Clean: " CLEAN;
print "Shared_Dirty: " DIRTY;
}'

### 回收脏页
内存不断在变化，因此所有脏页都需要刷到硬盘中，否则数据会丢失。在pdflush之后，页面就被free出来给其他进程。但如果瞬间pdflush大量的页面从内存到硬盘，系统会因为I/O紧张而感觉到明显的迟钝。因此要将这些集中并且打的I/O换成更多的小的I/O，则基本上体验不到系统的迟钝。

而且pdflush是kernel的线程，一般无法干预。默认pdflush线程会启动两个，如果脏页很多pdflush的数据量会增加，反之就会减少。参数vm.nr_pdflush_threads可以显示pdflush的线程数。或者用ps显示。

### 涉及脏页回收的一些参数
ps axo comm,pid,stat,psr | grep -e kswapd -e pdfush
The above example shows the relevant processes along with their state and the processor on which they are running. 

vm.dirty_background_ratio
当脏页达到什么比例的时候，系统就开始考虑将内存中的dirty page往硬盘中进行pdflush，但不是立即进行flush，默认为10%；

vm.dirty_expire_centisecs
该数值除以100得到接近30，即当一个页面，脏到什么程度，即脏页存在30s之后才允许进行pdflush；

vm.dirty_writeback_centisecs
默认情况下499/5，即每隔5s，pdflush就会激活一次；

vm.dirty_ratio
如果某个进程突然进行暴力I/O，即在物理内存中产生超过%多少的脏页的时候立即进行flush，此时会出现抢线情况，系统将明显变慢，默认该值为40%；
 
### 回收干净页面：
一般sync能够让pdflush立即工作，或者在写代码的时候调用fsync，如果在系统严重崩溃的时候开启魔术键，并用echo s > /proc/sysrq-trigger；快捷键是Alt+SysRq+S。
向/proc/sys/vm/drop_caches写入1，会导致所有page cache中的干净页面写入磁盘，但这种操作不会经常进行，因为会比较严重地影响I/O子系统。

### OOM
Out-of-memory killer
• Kills processes if
• All memory (incl. swap) is active
• No pages are available in ZONE_NORMAL
• No memory is available for page table mappings
• Interactive processes are preserved if possible
• High sleep average indicates interactive
• View level of immunity from oom-kill
/proc/pid/oom_score
• Manually invoking oom-kill
echo f > /proc/sysrq-trigger
• Does not kill processes if memory is available
• Outputs verbose memory information in /var/log/messages

前提条件：所有内存区域都是active，zone normal已经被耗尽，因此会启用oom-killer随机杀死内存，但一般杀死都是占用内存比较大的进程，有时候可能是zone high；
/prc/pid/oom_score表示某个进程多么不愿意被杀死，数字越小越不愿意被杀死，而越大则越容易被杀死；
可以通过修改oom_adj来更改oom_score；
可以通过echo f > /proc/sysrq-trigger来调用oom-killer，但如果内存可用则不会真正杀死进程；
 
Tuning OOM policy
• Protect daemons from oom-kill
echo n > /proc/pid/oom_adj
• oom_score gets multiplied by 2n
• Caution: child processes inherit oom_adj from parent
• The RHEL 5.1 SELinux targeted policy complicates setting this tunable
• Update to selinux-policy-targeted-2.4.6-106.el5_1.3 or later
• Disable oom-kill in /etc/sysctl.conf
vm.panic_on_oom=1
• oom-kill is not a fix for memory leaks!
由于一般情况下oom_score是只读的，所以我们需要通过oom_adj来变相调整oom_adj的值，但是这个更改可能需要在进程被杀之前设置：
若echo n > /proc/pid/oom_adj，则在oom_score中会获得2n的值，从刚才的理论来看，如果将oom_adj设为0则可以使某个进程免于被杀；
一般可以通过vm.panic_on_oom=1，使得在产生oom不生效；

The oom_adj sysctl was added with the Red Hat Enterprise Linux 5.0 kernel. This tunable can be problematic for
SELinux-confined services unless you update selinux-policy-targeted. For example, consider the sshd
process when using selinux-policy-targeted-2.4.6-104:
pidof sshd
2334
echo 2 > /proc/2334/oom_adj
-bash: /proc/2334/oom_adj: Permission denied
Using ausearch -c bash to search /var/log/audit/audit.log shows that comm=bash running in the
source domain unconfined_t was denied write access to the file oom_adj having tcontext=sshd_t. Using
sesearch to query the binary policy reveals that unconfined_t indeed lacks permission since the absence of an
allow rule is a lack of permission:
sesearch -as unconfined_t -t sshd_t
If you cannot update to the latest policy, you can work around it by setting oom_adj for the current shell, start
the service, then re-adjust oom_adj for the current shell. The service will start with the adjustment due to process
inheritance. Another way is to modify the service init script to set oom_adj on the PID $$ within the script's
start() function, then reset oom_adj on $$. The easiest fix is to update selinux-policy-targeted from
RHN or server1. These workarounds are then no longer necessary.
Use caution when protecting a daemon with oom_adj as child processes inherit the setting. Consider sshd,
for example. All ssh client sessions created after setting oom_adj=3 will also have oom_adj=3. This would
appear to be useful at first since the effect for the client session is productive when trying to rescue a system that is
undergoing oom-kill. However, inheritance means that any service that is restarted during an ssh session picks up the
oom_adj=3 tunable, as well. This effectively undermines the oom-kill algorithm. This setting can be useful for batch
servers running a critical process. Understand its ramifications and test appropriately.

### Detecting memory leaks
• Two types of memory leaks
• Virtual: process requests but does not use virtual address space (vsize)
• Real: process fails to free memory (rss)
• Use sar to observe system-wide memory change
sar -R 1 120
• Use watch with ps or pmap
watch -n1 'ps axo pid,comm,rss,vsize | grep httpd'
• Use valgrind
valgrind --tool=memcheck cat /proc/$$/maps

[root@stationX ~]# valgrind --tool=memcheck cat /proc/$$/statm

获得内存溢出的信息；
内存溢出（泄露）的大多数原因是因为应用程序申请内存之后而没有及时释放；
 
 ### What is swap?
• The unmapping of page frames from an active process
• Swap-out: page frames are unmapped and placed in page slots on a swap device
• Swap-in: page frames are read in from page slots on a swap device and mapped into a process address space
• Which pages get swapped?
1. Inactive pages
2. Anonymous pages
• Swap cache
• Contains unmodified swapped-in pages
• Avoids race conditions when multiple processes access a common page Frame

其中：
Swap out：
交换出去的原因是内存不足，因此将一部分进程交换到硬盘以腾出内存页（clean）来供新的进程申请；
Swap in：
当发生major page fault的时候，即严重页面失败，即一个被交换到硬盘的应用程序重新活过来的时候需要被交换到内存中；

什么样的页面会被交换？
匿名页面和不活动的页面；

Swap cache：
只是一个计数器（记录器），即上次被交换的页面会被记录。用于记录交换出去的东西是否被更改；

 
### 增加交换分区的性能的手段包括：
交换分区单独放硬盘或者分区；对虚拟机设置单独交换；设置多个交换分区（最多32个）；对不同的交换分区设置优先级（高速硬盘的优先级比低速硬盘优先级更高）；
所以一般需要大量使用交换的时候会对交换分区进行调优；

### Tuning swappiness
• Searching for inactive pages can consume the CPU
• On large-memory boxes, finding and unmapping inactive pages consumes
more disk and CPU resources than writing anonymous pages to disk
• Prefer anonymous pages (higher value)
vm.swappiness
• Linux prefers to swap anonymous pages when:
% of memory mapped into page tables + vm.swappiness >= 100
• Consequences
• Reduced CPU utilization
• Reduced disk bandwidth

一般kernel多么愿意被交换？
一般通过vm.swappiness来设置：
一般用100 – vm.swappiness所产生的值，该值如果为n则表示当%n的内存已经被占用的时候就开始考虑交换，其中n%是ps看到的rss的值；
可以通过dd一些数据到/dev/shm中消耗内存来测试；

### Tuning swap for think time
• Swap smaller amounts
vm.page-cluster
• Protect the current process from paging out
vm.swap_token_timeout
• Consequences
• Smoother swap behavior
• Enable current process to clean up its pages

The following sysctls are used to tune virtual memory performance on Red Hat Enterprise Linux systems:
vm.swappiness 0-100, The higher the value, the more the VM system will try to swap.
vm.page-cluster is used to set the number of pages the kernel reads in on a page fault. This helps reduce head
seek movement. The number of pages read in is actually 2page-cluster pages.
vm.swap_token_timeout is used to control how long a process is protected from paging when the system is
thrashing, measured in seconds.
If memory shortage is severe enough, the kernel will start killing usermode processes. The kernel tries to do this
intelligently by selecting a process based on it badness. Factors that influence badness include the amount of memory
held by a process and how recently that memory has been accessed.

交换分区的调整方法：
vm.page-cluster
表示一次性swap in以及swap out的值，如果该值越小越感觉不到被交换；
vm.swap_token_timeout
表示内存已经耗尽，交换分区在频繁进行交换过程中，一个进程在再次进行page out之前要等待多久，该值确定一个程序被swap out前要等待多少秒才再次被swap out；

### Tuning swap visit count
1. Create up to 32 swap devices
2. Make swap signatures
mkswap -L myswap /dev/sdb1
3. Assign priority in /etc/fstab
/dev/sda1 		swap 	swap 	pri=3 0 0
LABEL=myswap 	swap 	swap 	pri=3 0 0
/dev/sdc1 		swap 	swap 	pri=3 0 0
/var/swapfile 	swap 	swap 	pri=1 0 0
4. Activate
swapon -a
• View active swap devices in /proc/swaps

/dev/sda1 		swap 	swap 	pri=3 0 0
LABEL=myswap 	swap 	swap 	pri=3 0 0
/dev/sdc1 		swap 	swap 	pri=3 0 0
/var/swapfile 	swap 	swap 	pri=1 0 0

通过上例查看，可以对swap使用卷标，以及可以对同类的设备设置相同的优先级以实现交换的轮询，而显然对基于文件的swap设备的优先级比较低；
 
### Monitoring memory usage
• Memory activity
vmstat -n 1 30
sar -r 1 30
• Rate of change in memory
sar -R 1 30
• Swap activity
sar -W 1 30
• All IO
sar -B 1 30

交换的监控：
 
### 修改待补全实验！

### 参考实验
第十章实验：

实验一：控制内存使用：

建立一个叫做memuser的用户，并通过pam来设置对他使用内存量的限制：

[root@dom-0 ~]# useradd memuser; echo redhat | passwd memuser --stdin
Changing password for user memuser.
passwd: all authentication tokens updated successfully.


修改/etc/security/limits.conf文件，并增加对该用户的软硬限制：
[root@dom-0 ~]# cat /etc/security/limits.conf | grep as
#        - as - address space limit
memuser soft as 10000
memuser hard as 10000

其中as是对用户使用的寻址空间的限制。

之后安装测试程序leaky，该程序有两个参数，第一个参数表示分配内存的次数，第二个参数表示每次分配的内存量：

[memuser@dom-0 ~]$ ulimit -a ｜ grep virtual
core file size          (blocks, -c) 0
data seg size           (kbytes, -d) unlimited
scheduling priority             (-e) 0
file size               (blocks, -f) unlimited
pending signals                 (-i) 32743
max locked memory       (kbytes, -l) 32
max memory size         (kbytes, -m) unlimited
open files                      (-n) 1024
pipe size            (512 bytes, -p) 8
POSIX message queues     (bytes, -q) 819200
real-time priority              (-r) 0
stack size              (kbytes, -s) 10240
cpu time               (seconds, -t) unlimited
max user processes              (-u) 2047
virtual memory          (kbytes, -v) 10000
file locks                      (-x) unlimited


[memuser@dom-0 ~]$ memleak 25 256

Process ID is: 8334

Grabbing some memory
Grabbing some memory
Grabbing some memory
Grabbing some memory
Grabbing some memory
Grabbing some memory
Grabbing some memory
Grabbing some memory
Segmentation fault

现在假如将可使用页面增加一个数量级：

[memuser@dom-0 ~]$ ulimit -a | grep virtual
virtual memory          (kbytes, -v) 100000

[memuser@dom-0 ~]$ memleak 25 256

Process ID is: 8443

Grabbing some memory
.....................
Grabbing some memory

Press any key to exit

则该程序可以正常执行完成。

 
实验二：控制虚拟机内存使用：

建立一个只有512M内存的虚拟机：
# xm create snap memory=512

通过登录虚拟机，可以查看虚拟机内存：

# cat /proc/meminfo | grep MemTotal

或者使用free -m命令。

通过下面的命令来重设虚拟机的内存：

# virsh setmem snap 262144

之后再登录虚拟机通过free命令来查看。



 
第十一章实验：

实验一：分配超出实际物理内存大小的内存。内存overcommit：

首先查看当前在系统中的可用内存大小（RAM ＋ SWAP）：根据下面的结果，获得的值是1897 ＋ 2047。

[root@dom-0 ~]# free -m
             total       used       free     shared    buffers     cached
Mem:          1897       1175        722          0         87        680
-/+ buffers/cache:        406       1490
Swap:         2047          0       2047

查看当前关于overcommit的配置：

[root@dom-0 ~]# sysctl -a | grep overcommit
vm.overcommit_ratio = 50
vm.overcommit_memory = 0

打开内存的overcommit功能：
[root@dom-0 ~]# sysctl -w vm.overcommit_memory=1
vm.overcommit_memory = 1

现在在其中一个窗口使用下面的命令观测：

[root@dom-0 ~]# watch -n1 'grep Committed_AS' /proc/meminfo 

在另外一个窗口执行测试程序vmemleak，去每次分配50MB的虚拟内存。
[root@dom-0 pdrr]# vmemleak 40 12800

Process ID is: 10486
................
Press any key to exit

在这里vmemleak的参数表示，分配40次，每次分配12800个page，而每个page最小4KB计算，正好每次50MB。

那么通过查看/proc/meminfo中的信息，可以看到每次commit的值以及变化。


实验二：查看共享内存：

观察init进程使用了多少共享内存。

[root@dom-0 ~]# pmap -d 1 | grep share
mapped: 2076K    writeable/private: 308K    shared: 0K

以及可以使用命令# cat /proc/1/maps并观察。但问题是我使用这条命令没有找到任何有关共享内存的信息。

所以从上面的结果看，init进程没有使用共享内存。

现在需要知道page cache中有多少physical page会将被init进程用于和其他进程共享。

可以使用下面的命令查看：
[root@dom-0 ~]# top -bn1 | grep init
    1 root      15   0  2076  664  568 S  0.0  0.0   0:00.49 init  

而page cache的使用，可以通过cat /proc/pid/statm来查看。

[root@dom-0 ~]# cat /proc/1/statm 
519 166 142 8 0 71 0

通过第一条命令可以看出，有536KB在page cache中，并可能被share出去。
现在使用x86info命令来获得当前系统的page size值为4K/页，但是我实在不知道哪个值对应page size：

[root@dom-0 ~]# x86info | grep page
/dev/cpu/0/cpuid: No such file or directory
 Instruction TLB: 4x 4MB page entries, or 8x 2MB pages entries, 4-way associative
 Instruction TLB: 4K pages, 4-way associative, 128 entries.
 Data TLB: 4MB pages, 4-way associative, 32 entries
 L0 Data TLB: 4MB pages, 4-way set associative, 16 entries
 L0 Data TLB: 4MB pages, 4-way set associative, 16 entries
 Data TLB: 4K pages, 4-way associative, 256 entries.
 Instruction TLB: 4x 4MB page entries, or 8x 2MB pages entries, 4-way associative
 Instruction TLB: 4K pages, 4-way associative, 128 entries.
 Data TLB: 4MB pages, 4-way associative, 32 entries
 L0 Data TLB: 4MB pages, 4-way set associative, 16 entries
 L0 Data TLB: 4MB pages, 4-way set associative, 16 entries
 Data TLB: 4K pages, 4-way associative, 256 entries.


我猜，应该是这个值：
[root@dom-0 ~]# sysctl -a | grep mni
kernel.shmmni = 4096

现在建立一个awk的脚本，并获取一些信息：

将会获得类似下面的输出：

[root@dom-0 ~]# cat /proc/1/statm | awk '
>   BEGIN { PGSZ=4; }
>   { TOTAL = $1*PGSZ;
>     RSS    = $2*PGSZ;
>     SHARED = $3*PGSZ;
>     ANON   = RSS-SHARED;
>     TEXT   = $4*PGSZ;
>     LIBS   = $5*PGSZ;
>     DATA   = $6*PGSZ;
>     ; $7 is always zero (hard-coded)
>   }
>   END {
>     print "/proc/pid/statm (pages): " $0;
>  print "";
>     print "Convert to KiB and make sense out of it...";
>     print "Total VM Addr Space: " TOTAL;
>    print "Resident:            " RSS;
>    print "Page Cache:          " SHARED ;
>    print "Anonymous Cache:     " ANON " (rss - shared)";
>    print "Code:                " TEXT;
>    print "Libraries:           " LIBS;
>    print "Data:                " DATA;
>    print "";
>    print "ps axo pid,comm,vsize,rss | grep init";
>    system("ps axo pid,comm,vsize,rss | grep init")
> }'
/proc/pid/statm (pages): 519 166 142 8 0 71 0

Convert to KiB and make sense out of it...
Total VM Addr Space: 2076
Resident:            664
Page Cache:          568
Anonymous Cache:     96 (rss - shared)
Code:                32
Libraries:           0
Data:                284

ps axo pid,comm,vsize,rss | grep init
    1 init              2076   664


 
实验三：观察进程间通讯：

执行：ipcs -m命令来观察共享内存的使用情况：

[root@dom-0 ~]# ipcs -m

------ Shared Memory Segments --------
key        shmid      owner      perms      bytes      nattch     status      
0x00000000 0          root      644        52         2                       
0x00000000 32769      root      644        16384      2                       
0x00000000 65538      root      644        268        2                       
0x00000000 98307      root      644        36         2                      
.............................

查看当前共享内存的设置（最大和最小的共享内存片）：

[root@dom-0 ~]#  sysctl -a | grep kernel.shmmni
kernel.shmmni = 4096
[root@dom-0 ~]#  sysctl -a | grep kernel.shmmax
kernel.shmmax = 4294967295

可以将最小共享内存片临时更改为7，登出并再登入之后继续观察。

使用ipcs -l查看整体情况：

[root@dom-0 ~]# ipcs -l

------ Shared Memory Limits --------
max number of segments = 4096
max seg size (kbytes) = 4194303
max total shared memory (kbytes) = 1073741824
min seg size (bytes) = 1

------ Semaphore Limits --------
max number of arrays = 128
max semaphores per array = 250
max semaphores system wide = 32000
max ops per semop call = 32
semaphore max value = 32767

------ Messages: Limits --------
max queues system wide = 16
max size of message (bytes) = 65536
default max size of queue (bytes) = 65536

最后恢复会原来的设置，将最小共享内存片改回4096。
 
第十二章实验：

实验一：跟踪内存使用：

一般应用程序在申请和占用内存之后不能正确地释放内存的现象称为内存泄露。通过该实验我们将知道应用程序如何使用内存。

使用测试命令noleak拷贝一些信息到已经分配的内存中并正确地释放内存。该程序包含两个参数：分配内存参数的次数以及每次分配的页面。

运行该程序，以256个页面为单位（1MB），分配20次：

[root@dom-0 ~]# noleak 20 256

Process ID is: 32728

Grabbing some memory
Grabbing some memory
Grabbing some memory
............................


当程序正在运行的时候，使用watch和pmap命令来查看进程的内存使用量：

[root@dom-0 pdrr]# watch -n1 pmap 32728

Every 1.0s: pmap 32728                                                                   

32728:   noleak 20 256
003ca000   1276K r-x--  /lib/libc-2.5.so
00509000      4K --x--  /lib/libc-2.5.so
0050a000      8K r-x--  /lib/libc-2.5.so
0050c000      4K rwx--  /lib/libc-2.5.so
0050d000     12K rwx--    [ anon ]
00b01000      4K r-x--    [ anon ]
00b78000    104K r-x--  /lib/ld-2.5.so
00b92000      4K r-x--  /lib/ld-2.5.so
00b93000      4K rwx--  /lib/ld-2.5.so
08048000      4K r-x--  /usr/local/bin/noleak
08049000      4K rw---  /usr/local/bin/noleak
b7f9a000      8K rw---    [ anon ]
b7faf000      8K rw---    [ anon ]
bf90a000     88K rw---    [ stack ]
 total     1532K

最后的两到三行将告知该程序的内存使用量。

而另外一个应用程序vmemleak将模拟非正常的内存使用。

[root@dom-0 ~]# vmemleak 20 256

Process ID is: 949

Grabbing some memory
Grabbing some memory
.............................

参数方面和上面的命令一样，但是通过watch命令来监控该程序的pid，可以发现该程序在匿名页的使用量上和刚才的程序不同。
匿名页的使用量一直在增加，而且不会被释放。


Every 1.0s: pmap 949                                                            

949:   vmemleak 20 256
0034e000      4K r-x--    [ anon ]
00a8d000   1276K r-x--  /lib/libc-2.5.so
00bcc000      4K --x--  /lib/libc-2.5.so
00bcd000      8K r-x--  /lib/libc-2.5.so
00bcf000      4K rwx--  /lib/libc-2.5.so
00bd0000     12K rwx--    [ anon ]
00de5000    104K r-x--  /lib/ld-2.5.so
00dff000      4K r-x--  /lib/ld-2.5.so
00e00000      4K rwx--  /lib/ld-2.5.so
08048000      4K r-x--  /usr/local/bin/vmemleak
08049000      4K rw---  /usr/local/bin/vmemleak
b6b99000  20568K rw---    [ anon ]
b7fc2000      8K rw---    [ anon ]
bfb14000     84K rw---    [ stack ]
 total    22088K

实际上也可以使用system-config-monitor来观察。



 
实验二：内存短缺：

在该实验环境当中，我们将面对内存逐步短缺的情况。

首先确保下面两个软件包已经安装：procps和sysstat。

之后查看系统当前的负载情况：

[root@dom-0 mnt]# uptime 
 23:21:41 up 13:34,  4 users,  load average: 0.00, 0.04, 0.00

运行vmstat 2来以2s作为单位获得系统的信息。需要注意的是头两行输出信息可能不一定太有用，所以可能不一定能看到页面交换的动作（pi/po）和很少的磁盘I/O即bi/bo。这就是说，有进程处于运行队列中，但是并没有在被阻塞的队列和交换队列。因此CPU有大量的时间处于idle状态，只有很少部分的内存会由应用程序使用，而大部分内存作为buffer和cache。

当vmstat在运行状态中的时候可以同时在第二个窗口开启free，在我当前的例子中，通过free的输出可以看到可用的总内存量应该是1897MB+2047MB。但也需要注意，这个值是可用的虚拟内存量。

[root@dom-0 mnt]# free -m
             total       used       free     shared    buffers     cached
Mem:          1897       1260        636          0        145        730
-/+ buffers/cache:        385       1512
Swap:         2047          0       2047


为了模拟内存消耗，我们将建立一个大的tmpfs文件系统并在其中存储一些比较大的文件。在tmpfs文件系统上的文件实际上被存储于page cache中，或者可能会使用到swap空间。这种做法有点类似于"RAM disk"。通常情况下tmpfs文件系统最大为物理内存的一半（swap不计算在内）以防止物理内存被耗尽。但在这里处于测试的需求，我们会设法使tmpfs文件系统大一些，在这里和刚才计算的总虚拟内存量一致。因此建立一个新的挂载点，并以1897＋2047这个容量来建立和挂载tmpfs文件系统。

[root@dom-0 mnt]# mkdir /mnt/tmpfs
[root@dom-0 mnt]# mount -t tmpfs -o size=3944m tmpfs /mnt/tmpfs/

再次运行free之后的情况：

[root@dom-0 ~]# free -m
             total       used       free     shared    buffers     cached
Mem:          1897       1261        635          0        145        730
-/+ buffers/cache:        384       1512
Swap:         2047          0       2047

和刚才的结果相差无几。

现在运行几个命令：
# sar -r 2 0
以2s为频率显示内存的使用量；
# sar -R 2 0
以百分比为频率显示内存的使用量；
# sar -W 2 0
显示每秒钟从swap中读入和写入swap的page量；

在运行这些命令的同时，强制进行page。我们可以在/mnt/tmpfs中建立一个大的文件来用光可用的内存。根据上例，应该使用1512。

此时可以看到有大量的磁盘I/O，而且通过free去看，有很多的swap out。

可以通过下面的命令来产生一些页面的动作：
# cat /mnt/tmpfs/bigfile > /dev/null

在另外一个终端，使用iostat -p 2观察，我们将发现产生大量I/0的是/dev/sda10，即swap分区。

另外，如果使用dd命令以swap容量的50%作为容量写入到/mnt/tmpfs/文件系统的文件，将导致更坏的系统性能。

# dd if=/dev/zero of=/mnt/tmpfs/biggerfile bs=1024 count=1048576
 
















