# Pacemaker基础
## Pacemaker介绍
* Pacemaker是一个集群资源管理器，使用资源级别的监测和恢复来保证集群服务的最大可用性。它可以用你所擅长的基础组件(Corosync或者是Heartbeat)来实现通信和关系管理。
* Pacemaker包含的特性
    
    1. 监测并恢复节点和服务级别的故障
    2. 存储无关，并不需要共享存储
    3. 资源无关，任何能用脚本控制的资源都可以作为服务来管理
    4. 支持使用STONITH来保证数据一致性
    5. 支持大型或者小型的集群
    6. 支持quorate(法定人数) 或 resource(资源) 驱动的集群 
    7. 支持几乎所有的冗余配置，包括Active/Active, Active/Passive, N+1, N+M, N-to-1 and N-to-N
    8. 自动同步各个节点的配置文件
    9. 可以设定集群范围内的ordering, colocation , anti-colocation约束
    10. 支持更多高级服务类型: 
        * Clones:为那些要在多个节点运行的服务所准备的
        * Multi-state:为那些有多种模式的服务准备的。(比如.主从, 主备) 统一的，可控制的，cluster shell

## 集群组成部分
### 集群组成部分
* 提供消息和集群关系功能的集群核心基础组件(标红的部分)
* 集群无关的组件(蓝色的部分)。在Pacemaker架构中，这部分不仅包含有怎么样启动，关闭，监控资源的脚本，而且还有一个本地的守护进程来消除这些脚本实现的(采用的)不同标准之间的差异
* 大脑(绿色部分)处理并响应来自集群和资源的事件(比如节点的离开和加入，资源的失效) ，以及管理员对配置文件的修改。在对所有这些事件的响应中，Pacemaker会计算集群理想的状态，并规划一个途径来实现它。
<center>
    <img src="images/cluster 7/1-1.png">
</center>


### Pacemaker 层次
* 当与Corosync集成时，Pacemaker也支持常见的开源集群文件系统，根据来着集群文件系统社区的最新标准，他们用一个通用的分布式锁控制器，它靠Corosync通信并且用Pacemaker管理成员关系(哪些节点是开启或关闭的)和隔离服务。
<center>
    <img src="./images/cluster 7/1-2.png">
</center>

### Pacemaker内部组成
1. Pacemaker本身由四个关键组件组成:
2. CIB (aka. 集群信息基础)
3. CRMd (aka. 集群资源管理守护进程)
4. PEngine (aka. PE or 策略引擎)
5. STONITHd
<center>
    <img src="./images/cluster 7/1-3.png">
</center>

* CIB用XML来展示集群的配置和资源的当前状态。CIB的内容会自动地在集群之间同步，并被PEngine用来来计算集群的理想状态和如何达到这个理想状态。
* 这个指令列表然后会被交给DC(指定协调者)。Pacemaker会推举一个CRMd实例作为master来集中做出所有决策。如果推举的CRMd繁忙中，或者这个节点不够稳定... 一个新的master会马上被推举出来。
* DC会按顺序处理PEngine的指令，然后把他们发送给LRMd(本地资源管理守护进程) 或者通过集群消息层发送给其他CRMd成员(就是把这些指令依次传给LRMd)。
* 节点会把他们所有操作的日志发给DC，然后根据预期的结果和实际的结果(之间的差异)， 执行下一个等待中的命令，或者取消操作，并让PEngine根据非预期的结果重新计算集群的理想状态。
* 在某些情况下，可能会需要关闭节点的电源来保证共享数据的完整性或是完全地恢复资源。为此Pacemaker引入了STONITHd。STONITH是Shoot-The-Other-Node-In-The-Head(爆其他节点的头)的缩写，并且通常是靠远程电源开关来实现的。在Pacemaker中，STONITH设备被当成资源(并且是在CIB中配置)从而轻松地监控，然而STONITHd会注意理解STONITH拓扑，比如它的客户端请求隔离一个节点，它会重启那个机器。(译者注:就是说不同的爆头设备驱动会对相同的请求有不同的理解，这些都是在驱动中定义的。)

### Pacemaker集群类型
#### 主备模式
<center>
    <img src="./images/cluster 7/ab.png">
</center>

>主备模式是生产环境的经典架构，但是可惜的是会浪费一台主机在那随时待命，白白浪费资源，但是对于关键业务是必须有这样的保障！当主机ACTIVE出现问题，集群资源会切换到Passive主机去运行。

#### 多节点模式 N+1
<center>
    <img src="./images/cluster 7/sharef.png">
</center>

> 支持多节点集群，可以很多服务共享一个备份节点，大大节省资源，生产系统会将一个项目中需要集群的3个服务跑在4个节点的集群上，如果谁有问题，谁就先迁移到备份节点上运行，等主机恢复了，然后在切换回来或者将该主机作为其他主机的备份资源使用

#### Actice/Active  N to N
<center>
    <img src="./images/cluster 7/aa.png">
</center>

>使用共享存储配合集群文件系统OCFS或者GFS2可以同时运行多个服务，每个节点都可以用于互相切换。也可以同时启动分散一下工作量

## PCS 命令和配置简介

### 主要配置文件
* PCS 的配置文件为 corosync.conf 和 cib.xml.请勿直接编辑这些文件，而是使用pcs 或pcsd界面进行编辑。
* corosync.conf文件提供 corosync使用的集群参数，后者是 Pacema ker  所在集群管理器。
* cib.xml是一个 XML 文件，代表集群配置和集群中所有资源的当前状态。这个文件由 Pacemaker  的集群信息基地（CIB）使用。会自动在整个集群中同步 CIB 的内容。

### PCS命令行界面
* pcs 命令行界面通过为corosync.conf文件cib.xml 提供界面，从而控制和配置corosync及Pacemaker,pcs 命令一般格式如下.
    
        pvs  [- f file] [-h ] [commands]...

### PCS命令主要介绍
|选项|解释|
|:----|:---
|Cluster|	-
|Resource|	创建和管理集群资源
|Stonith|	将 fence 设备配置为与Pacemaker 一同使用
|Constraint|	管理资源限制
|Property|	设定 Pa cema ker  属性
|Status|	查看当前集群和资源状态
|Config|	以用户可读格式显示完整集群配置

总结
本章节只是讲解PCS集群的架构和基础，后续以实战的形式讲解常用的配置，学的东西能解决问题才叫有用的知识。-

