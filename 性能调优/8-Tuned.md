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

4、系统中的tuned profile 的意义

    default: 尽可能不要去影响当前系统,加入一点点省电模式,default下会适当的对磁盘的耗电量降低,网络配置不动,默认算法是CFQ.  典型应用为Email 服务器

    desktop-powersave: 面向桌面, SATA 省电模式, 通过其它手段调节CPU,以太网,磁盘,都会想办法去降低.

    server-prowersave:只对SATA做降级,省电模式为环保,但是不能一直做环保,比如,磁盘,我为了省电,降低利用率,但是磁盘有一个start up time...会影响工作效率.

    laptop-ac-powersave: 插电模式下 打开SATA降低级别,省电,WIFI,以太网,进行调节,省电

    laptop-battery-powersave:  电磁模式. 高调节,一旦使用,如果恢复正常工作状态,需要很大的延时. 效率更慢,磁盘,网络都收影响..

    spindown-disk: 尽量不让磁盘使用. 适用于磁盘不要在服务器服务上使用. 非常残酷.
                writeback动作延迟.. 尽量不做disk swapping. 日志延迟写入.分区挂载成noatime,尽量不要在生产环境中使用.

    throuhtput-performance: 重点:  VT -host + 低端存储 适用...
        tuned 所有省电模式关闭. sysctl 参数调节,提高吞吐量,针对磁盘和网络.当前的算法切换成deadline, 以及4倍的 read-ahead buffers .. 预读技术,读磁盘的时候,把当前的扇区在多读一点.   可以进入查看,这个设置的省电全部都已经false了. 可以试着修改文件内的内容,进行添加虚拟机的磁盘.

    latency-performance (Database server): 电源省电全部关闭.sysctl 参数调优,让网络的I/O尽量降低latency.算法为dead-line.

    enterprise-storage(File server , VT-host with Enterprise storage)
        适用于文件服务器, VT-host + 高端存储.
        省电全部关闭, 算法为dead-line, 把所有的I/O barrier 全部关闭, 提高I/O能力,疯狂读写磁盘,如果这个时候不幸断电,可能导致系统不能恢复.