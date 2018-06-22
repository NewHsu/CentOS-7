## Ceph-7 闲聊调优

- 选对硬件事半功倍！
- 任何调优都无法超越硬件的极限！
- 调优不是万能的！

## 硬件

* CPU

  ```
  Ceph 的 metadata server会到动态分配负载，对CPU比较敏感。
  Ceph 的 OSDs运行RADOS，通过CRUSH计算存放位置，replicate 数据，维护本机的集群映射副本。
  Ceph 的 mon 维护一个集群映射的主副本。
  CPU 计算密集型： Metadata Server 和 OSDs (推荐较好CPU)
  CPU 非密集型： mon (推荐稍差一点的CPU！但是也不能太差了！对比osds稍差点即可)
  按CPU排序：Metadata server > OSDs > mon  & (2-4路(8核心以上) --> 2路(8核心以上) --> 1~2路(8核心以上))
  ```

* Memory

  ```
  多多益善！
  metadata server 和 mon 必须尽可能多的提供内存给它们，至少每进程 1GB。
  OSDs 每个进程 500M 内存
  metadata server 和 mon 建议 64~128G内存
  OSDs 建议 64~96G内存
  ```

* Disk

  ```
  成本和性能的权衡！
  SATA ： 磁盘存储空间绝对优势，但是速度差
  推荐：OSDs服务器，系统单独安装，并且单独的磁盘作为OSD存储数据，日志可以考虑ssd。成本比(2T和4T的成本对于核算每TB的数据存储的价格截然不同！)
  
  SSD：性能绝对优势、存储空间太小
  推荐：metadata server & mon ，元数据服务器和监控器不需要使用大量的存储空间，但是需要一定的性能支撑。
  	 OSDs日志，通过存储OSD日志文件在SSD上和OSD对象数据存储在普通硬盘上来提升读写速度。
  
  另外：一定要注意计算每个OSDs主机上的磁盘数量和带宽之间的关系，读写总和不要超过带宽上限。
  ```

* Network

  ```
  万万不要让网络成为瓶颈！
  推荐配置2块千兆以太网卡，分别用于public和cluster网络。建议配置万兆网络。
  如果你需要提供更多的服务对外，并且数据量会比较大，建议使用双网络进行传输。
  ```

* Bios

  ```
  1. 开启超线程，把两个逻辑内核模拟成两个物理芯片，让单个处理器都能使用线程级并行计算，进而兼容多线程操作系统和软件，减少了CPU的闲置时间，提高的CPU的运行效率。
  2. 关闭节能，不需要根据负载自动调节，直接关闭，使用全性能。
  3. 关闭NUMA，NUMA架构是将内存和cpu分区使用，区域内的CPU使用区域内的内存会非常快于访问区域外的内存，但是在某些情况下，NUMA架构会影响CEPH-OSD的运行效率，所以建议关闭，CentOS系统下，修改/etc/grub.conf文件，添加numa=off来关闭NUMA。
  ```

  ## OS优化

  * 操作系统级别的优化对于Ceph的稳定运行起到至关重要的作用，在一定程度上会为Ceph的运行带来一定的性能改观。

  * Linux核心参数设置：

    1. 磁盘的IO调度，在Linux系统中IO调度的设置十分重要，因为这影响这磁盘的读写效率，可以将SSD设置为noop模式的算法，将sata和sas磁盘设置为deadline。

       ```
       echo "deadline" > /sys/block/sd[x]/queue/scheduler
       echo "noop" > /sys/block/sd[x]/queue/scheduler
       ```

    2. pid_max，进程数量，Ceph的OSD需要大量消耗进程数，推荐设置更大的值。

       ```
       echo 4194303 > /proc/sys/kernel/pid_max
       ```

    3. read_ahead_kb











> 选择对的硬件配置，将使Ceph的性能有质和量的改变！

## Ceph层面调优

* 调优最有效的方法是增加硬件，但是出于成本考虑，硬件的增加一般都是在极限或者是通过应用调优和系统调优不能解决的情况下才会选择的最后手段。
* 对于调优而言，应用调优是一个非常有效的手段。
* Ceph的调优分为如下几个层面

