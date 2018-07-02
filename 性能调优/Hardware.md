## Hardware Tun

- 硬件为计算机之根本，足够了解硬件将使得你在调优过程中拥有更大的优势
- 了解硬件的构造和工作原理，以及各个硬件的常用调节参数，这些知识可以让你的调优视野更加宽泛
- 软件和系统调优的极限是绝对不可能超过硬件的极限限制的
- 梳理和记录硬件信息，描述硬件模型

### CPU

- 中央处理器（CPU，Central Processing Unit）是一台计算机的运算核心（Core）和控制核心（ Control Unit）。它的功能主要是解释计算机指令以及处理计算机软件中的数据。
- 整个计算机中最关键的部分，性能的好坏直接影响系统的使用效率，所以我们需要认识CPU，充分了解CPU的工作原理以及可调节的方法。

##### 查看并认识CPU

```
# grep CPU /proc/cpuinfo 
# lscpu

[root@bogon ~]# grep CPU /proc/cpuinfo 
model name	: Intel(R) Core(TM) i5-7300U CPU @ 2.60GHz   <--CPU型号
[root@bogon ~]# lscpu
Architecture:          x86_64                            <--架构
CPU op-mode(s):        32-bit, 64-bit				    <--模式
Byte Order:            Little Endian
CPU(s):                2							<--数量	
On-line CPU(s) list:   0,1							<--在线工作列表
Thread(s) per core:    1							<-- 每核心超线程数
Core(s) per socket:    2							<-- 每物理CPU核心数
Socket(s):             1							<-- 物理CPU数量
NUMA node(s):          1
Vendor ID:             GenuineIntel
CPU family:            6
Model:                 142
Model name:            Intel(R) Core(TM) i5-7300U CPU @ 2.60GHz
Stepping:              9
CPU MHz:               2711.998
BogoMIPS:              5423.99
Hypervisor vendor:     KVM                                
Virtualization type:   full                             
L1d cache:             32K                           <-- 1级数据缓存
L1i cache:             32K						   <-- 1级指令缓存	
L2 cache:              256K						   <-- 2级缓存	
L3 cache:              3072K					   <-- 3级缓存	
NUMA node0 CPU(s):     0,1
Flags:                 fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx rdtscp lm constant_tsc rep_good nopl xtopology nonstop_tsc pni pclmulqdq ssse3 cx16 pcid sse4_1 sse4_2 x2apic movbe popcnt aes xsave avx rdrand hypervisor lahf_lm abm 3dnowprefetch fsgsbase avx2 invpcid rdseed clflushopt

Flags: 
LM:64为指令集
pae:物理地址扩展, 为CPU 询址增加4位,就是36位,可以询址64G

<<几核几线程就是指有多少个“Core per Socket”多少个“Thread per Core”,当后者比前者多时，
说明启用了超线程技术>>
```

常用的CPU通信手段有哪几种？

1. Desktop & Laptop
  主要使用FSB技术，前端总线——Front Side Bus（FSB），是将CPU连接到北桥芯片的总线。前端总线是处理器与主板北桥芯片或内存控制集线器之间的数据通道，其频率高低直接影响CPU访问内存的速度。

2. PC-Server
  Inter (QPI)：Intel的QuickPath Interconnect技术缩写为QPI，译为快速通道互联。事实上它的官方名字叫做CSI，Common System Interface公共系统界面，用来实现芯片之间的直接互联，而不是在通过FSB连接到北桥。

  AMD (Hyper Transport)：HyperTransport技术是一种高速、低延时、点对点的连接，旨在提高电脑、服务器、嵌入式系统，以及网络和电信设备的集成电路之间的通信速度。HyperTransport有助于减少系统之中的布线数量，从而能够减少系统瓶颈，让当前速度更快的微处理器能够更加有效地在高端多处理器系统中使用系统内存。

选择CPU ：

​	同系列的情况下，Ghz越高，性能越好，但是散热越大、耗电越高！ 

### memory

- 内存是计算机中重要的部件之一，它是与CPU进行沟通的桥梁。计算机中所有程序的运行都是在内存中进行的，因此内存的性能对计算机的影响非常大。内存(Memory)也被称为[内存储器]，其作用是用于暂时存放CPU中的运算数据，以及与[硬盘]等[外部存储器]交换的数据。只要计算机在运行中，CPU就会把需要运算的数据调到内存中进行运算，当运算完成后CPU再将结果传送出来，内存的运行也决定了计算机的稳定运行。 内存是由[内存芯片]、电路板、[金手指]等部分组成的。 

##### 查看认识内存

```
[root@bogon ~]# free -m
              total        used        free      shared  buff/cache   available
Mem:            991         171         518          13         301         624
Swap:          2047           0        2047

total ： 表示系统的总内存
used ： 表示应用程序已经使用的内存
free ： 表示当前还没有被使用的内存
shared ：表示共享链接库使用的内存
buff/cache ： 表示系统的page cache和buffer使用到的内存
available ： 表示应用程序还可以申请到的内存 

1. 系统当前使用到的内存是：used + buff/cache，used中包含了shared。
2. 所以total = used + buff/cache + free = 28995804 +20791812 + 15909532 = 65697148。
3. available（32578364） <= free + buff/cache（15909532 + 20791812 = 36701344），为什么是小于呢？因为系统的一些page或cache是不能回收的。
```

内存关注点：

 1. 新技术强于老技术，DDR4 要强于 DDR3 

    容量：DDR4理论上每根DIMM模块能达到512GiB > DDR3每个DIMM模块的理论最大容量仅128GiB。速度：DDR3的最高速率为2133MT/s < DDR4的数据传输率也从2133MT/s起步。

    能耗：DDR3的工作电压是1.5V，而DDR4是1.2V，并且能源节省高达40%。

	2. 内存中的ECC 是什么？

    ECC：动态内存故障,可用ECC内存校验解决,发现内存某一位失效,然后纠正.但是速度会降低,可以更安全. 只针对1位纠正,发现多位错误就系统挂起.

	3. 如果都是DDR4，那么依据什么选择？

    例如：DDR4 2133 和 DDR4 2400，如果主板支持2400，那么一定要选2400，2400和2133代表的是运行频率 ， 2400的内存，全速工作时，提供的数据带宽比2133的更大，所以理论上性能也更好。 

