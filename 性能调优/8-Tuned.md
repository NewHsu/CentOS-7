## Tuned 
* 有没有觉得前几篇调优枯燥无味，并且入手困难？有一个动态调优的方案你可以选择，只是效果不一定那么细致。
* Tuned是一个动态调优方案，用户可以在不同的时间段内采用不同的调优方案。由于以服务进程形式存在，就可以很方便的和crontab结合！
* Tuned 是监控并收集各个系统组件用量数据的守护进程，并可使用那些信息根据需要动态调整系统设置。它可以对 CPU 和网络使用的更改作出反应，并调整设置以提高活动设备的性能或者降低不活跃设备的电源消耗。
* 伴随它的工具 ktune 结合 tuned-adm 工具提供大量预先配置的调整分析以便在大量具体使用案例中提高性能并降低能耗。编辑这些配置或者创建新配置可生成为系统定制的性能。

### Tuned 的安装和使用

1、安装tuned

    # yum install tuned

2、启动tuned服务

    # systemctl enable tuned.service
    # systemctl status tuned.service

3、列出tuned调节内容

    [root@localhost ~]# tuned-adm list
    Available profiles:
    - balanced                    - General non-specialized tuned profile
    - desktop                     - Optimize for the desktop use-case
    - latency-performance         - Optimize for deterministic performance at the cost of increased power consumption
    - network-latency             - Optimize for deterministic performance at the cost of increased power consumption, focused on low latency network performance
    - network-throughput          - Optimize for streaming network throughput, generally only necessary on older CPUs or 40G+ networks
    - powersave                   - Optimize for low power consumption
    - throughput-performance      - Broadly applicable tuning that provides excellent performance across a variety of common server workloads
    - virtual-guest               - Optimize for running inside a virtual guest
    - virtual-host                - Optimize for running KVM guests
    Current active profile: virtual-guest

    tuned-adm:提供的文件分为两类：节能和性能提升,其侧重点分别为：存储和网络的低延迟、存储和网络的高吞吐量、虚拟计算机性能、虚拟主机性能。

> CentOS 7 内置的调优方案，可进行自定义配置，参考文件夹内各个配置文件“/usr/lib/tuned” 来了解参数更改内容。

4、tuned-adm 使用
如果想要更改当前调优模式，可以在确定应用调优模型和系统模型之后，对比以上配置，选择好后，可以使用如下命令激活：

    [root@localhost tuned]# tuned-adm profile desktop
    已经活跃模式下，切换配置文件进行激活

    [root@localhost tuned]# tuned-adm off 
    停止tuned调优

    [root@localhost tuned]# tuned-adm profile desktop
    [root@localhost tuned]# tuned-adm active
    停止模式下，需要先profile选择文件，然后激活

5、自定义配置文件进行调优
有时候有些应用的模式比较特殊，内置的调优方案无法满足我们的需求，所以我们可能要结合最近的内置调优方案然后进行改进，满足调优需求，具体步骤如下：

    1、拷贝调优配置文件，在原有基础进行修改：
    # cp -R /usr/lib/tuned/balanced /etc/tuned/myserver

    2、查看新建的 Profile 结构数
    # tree /etc/tuned/myserver
        /etc/tuned/myserver
        └── tuned.conf

        0 directories, 1 file

    3、修改 tuned.conf 文件
    # vim /etc/tuned/myserver/tuned.conf 

    4、内容简介

    [main]            --> 信息汇总介绍
    summary=myserver tuned file

    [cpu]             --> CPU设置
    governor=conservative
    energy_perf_bias=normal

    [audio]           -->声音设置，如不需要可以取消
    timeout=10

    [video]           -->video设置，如不需要可以取消
    radeon_powersave=auto

    [disk]            -->磁盘参数设置
    # Comma separated list of devices, all devices if commented out.
    # devices=sda
    alpm=medium_power
    elevator=deadline

    [my_sysctl]        -->设置sysctl参数
    type=sysctl              
    fs.file-max=655350     
    更多参数，还请参考其他配置文件或者man 5 tuned.conf  或者参考 “/usr/share/doc/tuned-2.5.1/” 目录下文件.

    5、使该 profile 生效
    #  tuned-adm profile myserver

    6、验证调优效果
    # tuned-adm active
    Current active profile: myserver
    # sysctl  -a |grep 'fs.file-max'
    fs.file-max = 655350
    # cat /sys/block/sda/queue/scheduler 
    noop [deadline] cfq 
    所有调优全部生效，调优成功。

## 总结：
× 其实这个调优省事很多，省的自己去一个一个更改参数了，但是有一点，一定要记住，调优是有节制的，千万不要无休止的调优。
× 这个tuned调优可以配合crontab来去做更灵活的调优，例如，早上一个策略增加吞吐量，晚上一个策略进行节能，最大化的资源节省。