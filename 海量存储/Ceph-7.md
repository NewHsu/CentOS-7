## Ceph-7 闲聊

- 对Ceph的硬件选型进行讨论
- 对PG的状态进行梳理和理解

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
## PG状态
- 在某个时间点上, 根据集群的内部状况, Ceph PG 可能会呈现出几种不同的状态. 要了解 PG 的状态, 可以查看 ceph status 命令的输出.

|状态|释义|
|:--|:--|
|creating| PG 正在被创建. 通常当存储池正在被创建或增加一个存储池的 PG 数目时, PG 会呈现这种状态.|
|active| PG 是活动的, 这意味着 PG 中的数据可以被读写, 对该 PG 的操作请求都将被处理.|
|clean| PG 中的所有对象都已被复制了规定的份数.|
|down| 包含 PG 必需数据的一个副本失效了, 因此 PG 是离线的.|
|replay| 某 osd 崩溃后 PG 正在等待客户端重新发起操作.|
|splitting| PG 正在被分割为多个 PG. 该状态通常在一个存储池的 PG 数增加后呈现. 比如说, 当你将 rbd 存储池的 PG 数目从 64 增加到 128 后, 已有的 PG 将会被分割, 它们的部分对象会被移动到新的 PG 上.|
|scrubbing| PG 正在做不一致性校验.|
|degraded| PG 中部分对象的副本数未达到规定数目.|
|inconsistent| PG 的副本出现了不一致. 比方说, 对象的大小不正确, 或者恢复结束后某副本出现了对象丢失的情形.|
|peering| PG 正处于 peering 过程中. peering 是由主 osd 发起的使存放 PG 副本的所有 osd 就 PG 的所有对象和元数据的状态达成一致的过程. peering 过程完成后, 主 osd 就能接受客户端写请求了.|
|repair| PG 正在被检查, 被发现的任何不一致都将尽可能地被修复.|
|recovering| PG 正在迁移或同步对象及副本. 一个 osd 停止服务后, 其内容版本将会落后于 PG 内的其他副本, 这时 PG 就会进入该状态, 该 osd 上的对象将被从其他副本迁移或同步过来.|
|backfill| 一个新 osd 加入集群后, CRUSH 会把集群现有的一部分 PG 分配给它, 该过程被称为回填. 回填进程完成后, 新 osd 准备好了后就可以对外服务.|
|backfill-wait| PG 正在等待开始回填操作.|
|incomplete| PG 日志中缺失了一关键时间段的数据. 当包含 PG 所需信息的某 osd 失效或者不可用之后, 往往会出现这种情况.|
|stale| PG 处于未知状态 - monitors 在 PG map 状态改变后还没收到过 PG 的更新. 启用一个集群后, 常常会看到在 peering 过程结束前 PG 处于该状态.|
|remapped|当 PG 的 acting set 变化后, 数据将会从旧 acting set 迁移到新 action set. 新主 osd 需要过一段时间后才能提供服务. 因此, 它会让老的主 osd 继续提供服务, 直到 PG 迁移完成. 数据迁移完成后, PG map 将使用新 acting set 中的主 osd.|