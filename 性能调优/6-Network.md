## NetWork
### Linux中的网络收发模型
* 发送数据的模型:输出/写入: 

        A．	用户数据将被写入到socket（在发送之前进入传输缓冲中）；
        B．	内核将用户数据封装为协议数据单元；
        C．	协议数据单元将被放入设备的传输队列；
        D．	驱动将队列中的协议数据单元从头开始拷贝到网卡；
        E．	当数据发送的时候网卡将产生中断
    * Linux内部结构中一切皆为文件,除了网络设备以外,因此将数据写入到socket“文件”(进入传输缓冲), 对socket进行读就是接收,进行写就是发送;Kernel将数据封成为PDU;将PDU放在所期待网络设备的传 送队列中;每个网卡的驱动在收到PDU之后就会开始往队列中读取数据并按照队列顺序发送;
    * 在发送的地方能够调优的地方是将发送的buffer调到合适的值,让队列长度、实际带宽和延迟达到一定的最合适的比例。
  
* 简化接收数据的模型: 

        A．	网卡接收到一个数据帧并使用DMA将其拷贝到接收缓冲中；
        B．	网卡产生CPU中断；
        C．	内核会对该中断进行处理并产生一个软中断；
        D．	软中断会将数据包移动到IP层以部署合适的路由策略；
        E．	如果数据是由本地传递，则：将数据解封装之后放入到socket的接收缓冲中；唤醒socket等待队列中的进程；进程会从socket的接收缓存中读取数据.
    * 当内核通过调度softirq来处理中断的时候，有数据的设备将被加入到CPU的poll队列中。当kernel处理softirq的时候，所有的在poll队列中的设备将被处理，数据包会直接从ring buffer被传递到IP层。
    * 网卡收到一个帧,通过DMA拷贝到接收buffer中(即网卡直接将数据拷贝到内存中而不通过CPU);然后 网卡要求CPU产生一个的硬件中断,每个网络包都会进行一次硬件中断;当Kernel收到该消息处理中断并 调度一个softirq,因此一个计算机在不断接收包的过程中Kernel会不断进行softirq,即不断被硬件中断并 调度软件中断,这就是网络易受DOS攻击的原因之一;然后softirq会通过irqhandler将包交到ip的缓冲池 中,若包的目标是自己则直接接收,如果是别人则需要转发,之后激活socket并让socket读取数据。
    * 因此在此期间能调整的就是网络的recive buffer,即接收缓冲。 一般buffer就是队列长度,如果队列短则包可能丢,如果队列长可能延迟会大

### 针对Kernel socket buffer进行调整
* 针对UDP协议，控制buffer的时候需要控制网络的core的读写buffer；
* 针对TCP协议调整的话，不光是需要调TCP读写buffer，还要调整core buffer，core buffer是总数；
* 碎片buffer是针对不足默认MTU大小的碎片进行整理，如果碎片过多，可以调整该buffer。
* 在不好的网络环境中可以对该buffer进行调整。
* 一般kernel会自动调整该buffer，但可以限制其大小。
* 一般buffer消耗的是normal zone中的不可被配置的memory。
* 所有控制器收发都基于buffer。

### 如何计算Buffer的大小
* 带宽延迟产生（BDP）
  
    Lpipe = Bandwidth * DelayRTT = A * W
    即buffer总大小 = 带宽 * 到达时间（比如ping主机时候的time值）
    100 Mebibits | 3 s 	 | 1 Byte  | 220
    -------------+-------+---------+------ = 39321600 Bytes		BDP
    s 				  | 		 | 8 bits  | Mebi
    上述公式计算出了一个39MB的buffer size；

* 由于所有的连接都共享同一个buffer，所以最终每个网卡上的buffer大小为：Buffer = BDP / 网络接口值；
* 上面的公式计算的只是一个平均值，那么在调整之前还要算一个最小值和最大值。

    如果想要调整最小的buffer，当链接达到峰值的时候，就是buffer的最小值；
    如果想要调整最大的buffer，当链接达到最小的时候，就是buffer的最大值；
    即通过该公式算出来，在系统状况健康的时候给每个链接分配较多的buffer；

### 调整核心buffer的大小：
* 一般core主要针对UDP，同时如果针对TCP也要调整。
* 四个sysctl的开关用于调整接收和发送buffer的最大值。
* 一个应用程序所能够使用的接收buffer的最大值由net.core.rmem_max控制，单位为byte；
* 一个应用程序所能够使用的发送buffer的最大值由net.core.wmem_max控制，单位为byte；
* 如果应用程序没有特意制定，则使用默认值，由下面的两个参数来定义：net.core.rmem_default和net.core.wmem_default。
* 但是TCP拥有单独的机制来自动调整buffer大小，因此一般都不会使用上面那两个带default的参数。
* 例如，针对在UDP协议基础上的NFS服务，通过下面的参数修改buffer值可以提升性能：

    net.core.rmem_max=262143
    net.core.wmem_max=262143
    net.core.rmem_default=262143
    net.core.wmem_default=262143
    但需要记住，调整完后服务要重启。如重启nfs服务等。

### 调整TCP的buffer大小
* 首先需要针对BDP连接来core的大小；然后调整后面的三个参数：

    • Overall TCP memory in pages
    net.ipv4.tcp_mem		总数	（结构包括：最小值	 中间值		最大值）
    • Input/reader in Bytes
    net.ipv4.tcp_rmem		读buffer
    • Output/writer in Bytes	
    net.ipv4.tcp_wmem		写buffer
* TCP协议中的一个重要功能是滑动窗口，因此TCP不是一个静态的协议。在传输开始的时候segment的大小在socket建立的时候就已经协商好了，而且发送方必须在接收方没有ACK返回的时候进行重传。而发送方也必须按照发送方最后发送的数据以及重传的数据量来确定窗口的大小。一般一个ACK能够用于确认多个segment，如果需要重传没有ACK确认的数据，可能会将多个数据合并为一个大的segment。这个功能会由系统上的一个参数来控制：net.ipv4.tcp_window_scaling=1，如果将其设置为0之后，窗口大小被设死为64KB。而在RHEL系统上，该参数的值为1。尽管有很多的参数可对网络进行调整，但是使用默认值不失为一个好的方案。对于无线网络来说，可以通过调整net.ipv4.tcp_frto来开启FRTO功能以获得更好的无线网络性能。

### 碎片问题
* 一般使用nststat –s查看所有的网络监听状态，一般可以显示Kernel计数器，可以帮助查看重新组装包的频率。如果发现频率过大，则证明buffer太小。
* 造成碎片的原因：Dos攻击；NFS；网络之间的垃圾或者网卡电路失败；
* 一个IP数据包可能在发送方被标记为don’t fragment，这样路由器可能会阻挡该包，并返回一个ICMP的错误“destination-unreachable/fragmentation-needed”给发送方。
* 对于IPv4来说，DF标记控制一个超出标准MTU值的数据包是否被分片，如果DF标记被设置，而且IP数据包过大，这样该包会被丢弃并且错误计数器会产生技术。* 所以一般identifier字段和offset字段用于标记分片的数据包。
* 被分片的数据包被缓冲，当一个IP包的所有分片到达的时候会被kernel重组，因此缓冲的大小由两个kernel参数控制：
net.ipv4.ipfrag_high_thresh		默认值为256KiB
* 表示一旦buffer达到这个参数限定的值的时候，内核会丢弃IP分片，直到buffer达到
net.ipv4.ipfrag_low_thresh		默认为192KiB
一般丢弃IP分片会导致丢包。
* 因此对于NFS服务来说如果客户端来自于WAN，则可能需要提高着两个值。而另外一个值：net.ipv4.ipfrag_time 定义了一个分片在buffer中存在多长时间才会被丢弃，默认为30s。对于延迟高的网络来说，该值可以上调。或者可以通过降低这个值来变相调大buffer大小。
* 网络包发送的时候，都会默认做一些碎片整理，如果需要整理的内容太多，超出256K的峰值，则正式开始丢包，在丢包到达下限的时候则又开始整理(192)，这样处理的初衷是为了反DOS。

### 中断
* NIC一般会针对每一个package向CPU产生一个硬中断，CPU中断后kernel会产生一个softirq软中断。如果发送方和接收方的buffer都满，则可能产生丢包，在netstat –s统计中就会有大量丢包。所以在设计比较差的操作系统体系中，操作系统可能因为大量的网络IRQ操作而将CPU资源耗尽。就是DOS攻击。
* 查看硬件中断：/proc/interrupts
* 查看软件中断：ps axo pid,comm,util | grep softirq
* 提高中断处理机制：

    两种重要的技术提高中断处理能力：
    第一；将多个中断合并为一个中断处理，在网卡底层实现。
    第二；polling，kernel为避免被宏攻击，会主动每隔一段时间到buffer中获取数据，这种技术需要最新的Linux	API支持，同时也要网络驱动和网卡的支持。
    另外在负载特别重的网络中，可以考虑使用TCP链接复用。即不用先释放原来连接再创建新连接，而是将以前的TCP复用，这种复用会由Kernel保证其安全性而不影响以前的链接。

### 调节中断
* 从物理上反DOS的方法可以设置interrupt throttle。
* 这个方法在驱动中设置，例如修改/etc/modprobe.conf，增加参数为：options e1000 InterruptThrottleRate=1,3000 
表示，上面提到每当收到一个包都要做一个irq（包括硬件irq和软件irq），因此当每秒钟有3000个irq的时候，kernel就认为有攻击产生，因此kernel会要求网卡使用刚才提到的poll模式。这是网卡的特性之一，需要kernel配合。
但是默认不用poll的原因是因为poll的延迟很高。所以网卡的工作模式是可以转换的。在不同的环境下用不同的方法，在没有DOS攻击的情况下使用老方法。
所以上述方法在安全的情况下，用老方法，一旦发现攻击则自动转换poll模式。

### sockets
* 刚才提到的socket会将用用程序绑定到网络栈上用于数据读写。
* 每一个socket（网络连接）被看做一个虚拟文件，因此：
* 写该文件的时候就是发送数据；读该文件的时候就是接收数据；如果关闭socket则该文件也被干掉。
* 读写buffer中存储的应用程序数据，一般TCP协议中要求有25%的overhead供使用，因此buffer要做相应的调节。
* TCP sockets
    * TCP连接是使用“三路握手”来建立的。当客户端系统启动连接时，它会发送一个带有SYN标志的服务器的数据包。此时，服务器将在侦听队列并回送具有SYN和ACK标志集的答复，该集合指示服务器确认。
    * 接收客户端初始包并希望与客户端建立连接。客户端完成通过使用包含ACK标志的数据包来响应连接。一旦客户端响应，连接就会移动。
    * 侦听队列进入连接队列。
    * 在接收大量连接请求的高延迟网络上的系统中，有可能由于客户端完成连接所需的时间，侦听队列可以变得完整。另一种可能问题是拒绝服务攻击。攻击者可以用TCP连接包轰击服务器，使用SYN标志集和伪源地址。这将导致服务器以等待方式填充侦听队列。
    * 请求从未接收到其发送的SYN请求的ACK。最后，当然，连接将时间到。
    * MSS是将被接受的段的最大大小。这通常是主机的本地MTU减去。
    * TCP/IP报头。例如：如果MTU为1500，MSS通常宣布为1460。与路径结合使用MTU发现，这样可以避免碎片化。如果没有发送MSS，通常假设MSS＝536（主机上的RFC）。
    * 要求“这是Internet连接的主机所能拥有的最小MSS。”
    * 接收窗口大小是另一侧发送的未被攻击数据的最大量。每个ACK发送更新有关当前窗口大小的信息。

* 在使用nmap扫描的时候，使用-t表示做三次握手的扫描，而-s表示隐式扫描，因为这种模式只扫描SYN。所以一般-s是一种黑客行为。
* 查看socket
    * netstat -tulpn
    • Active sockets
    sar -n SOCK
    lsof -i				-->查看打开文件数
    netstat -tu
    • All sockets
    netstat -taupe
    • Half-closed connections
    netstat -tapn | grep TIME_WAIT

### 调整TCP socket的建立：
net.ipv4.tcp_syn_retries
当每次试图连接其他机器的时候，重试的次数，超过该次数连接失败；
net.ipv4.tcp_max_syn_backlog
当别人连接本机以及大量SYN还没有回复，或者回复到一半还没有被对方ACK的时候，这是一个暂存池。
net.ipv4.tcp_tw_recycle
刚才提到的在TCP大量负载的情况下可以reuse；

### 调整TCP socket keepalive

[root@dhcp-129-162 ~]# sysctl -a | grep net.ipv4.tcp_keepalive_time
net.ipv4.tcp_keepalive_time = 7200
默认的连接生存期；

[root@dhcp-129-162 ~]# sysctl -a | grep net.ipv4.tcp_keepalive_int
net.ipv4.tcp_keepalive_intvl = 75
每隔75s发探测包；

[root@dhcp-129-162 ~]# sysctl -a | grep net.ipv4.tcp_keepalive_probe
net.ipv4.tcp_keepalive_probes = 9
发探测包的个数；

### 参考实验

































 
* TCP的流控和BDP（Bandwidth delay product）:
在一个延迟比较高的网络上观测流动窗口如何实现自动控制，观察BDP以及调整buffer size和窗口大小对网络的影响。
和上一个网络环境一样，需要两台机器。分别是192.168.0.60和192.168.0.80我们将在192.168.0.80上建立一个web服务器，并通过高延迟的网络下载该文件，观察性能；之后对网络调整之后再观察性能。


[root@kdc ~]# ifconfig 
bdptun    Link encap:IPIP Tunnel  HWaddr   
          inet addr:10.10.60.60  P-t-P:10.10.60.160  Mask:255.255.255.0

[root@app ~]# ifconfig 
bdptun    Link encap:IPIP Tunnel  HWaddr   
          inet addr:10.10.80.80  P-t-P:10.10.80.180  Mask:255.255.255.0

我们会尝试ping对方，这个时候将发现一个非常高的延迟：

在书上的实验显示，每个包的延迟为3s，那么在这种情况下，BDP应该是：
Lpipe = Bandwidth * DelayRTT = A * W

100 Mebibits | 3 s 	| 1 Byte 	| 220
-------------+-------+---------+------ = 39321600 Bytes
s | 	  	| 8 bits 	| Mebi

现在在被ping的那一方即192.168.0.80这台机器上修改/etc/fstab文件，在内存中建立一个5MB的文件：

[root@app ~]# mkdir /var/www/bdp
[root@app ~]# cat /etc/fstab | grep bdp
tmpfs                   /var/www/bdp            tmpfs   defaults        0 0
[root@app ~]# mount -a

[root@app ~]# dd if=/dev/zero of=/var/www/bdp/bigfile bs=1M count=5
5+0 records in
5+0 records out
5242880 bytes (5.2 MB) copied, 0.055922 seconds, 93.8 MB/s

并在该机器的apache服务器上增加一个子配置：
[root@app ~]# cat /etc/httpd/conf.d/bdp.conf 
alias "/bdp" "/var/www/bdp"
<directory "/var/www/bdp">
  order allow,deny
  allow from all
  options indexes
</directory>

在另外一台机器上查看sysctl –a的值，比较关键的是tcp_rmem和rmam_max。

通过将这些值导入系统来调整内核参数：
[root@kdc ~]# sysctl -a | grep rmem
net.ipv4.udp_rmem_min = 4096
net.ipv4.tcp_rmem = 4096        87380   131072
net.core.rmem_default = 109568
net.core.rmem_max = 109568

[root@kdc ~]# sysctl -a | grep rmem >> /etc/sysctl.conf

之后在kdc上，通过执行time wget命令从192.168.0.80上获取文件：
命令：# time wget http://10.10.80.180/bdp/bigfiles，记录下载时间。

现在调整在192.168.0.60上的接收缓冲区大小为原来的10倍：
# echo '393216000 393216000 393216000' > /proc/sys/net/ipv4/tcp_rmem
# echo 393216000 > /proc/sys/net/core/rmem_max

完成之后重新执行命令：
# echo 393216000 > /proc/sys/net/core/rmem_max

需要注意的是：在默认BDP的size之外增加更多的buffer空间不会对下载速度有明显的改善，而且在传输中的碎片可能使得情况更糟。

现在在192.168.0.60上关闭窗口调整功能：
# echo 0 > /proc/sys/net/ipv4/tcp_window_scaling
然后继续执行下载命令：
# time wget http://10.10.80.180/bdp/bigfiles

我们将发现下载速度变慢很多。因为关闭窗口自动分割将破事接收缓存变成64KiB大小，因此发送方发送的数据段大小也被限制到64KiB。
但如果现在重新打开自动窗口分割：
# echo 1 > /proc/sys/net/ipv4/tcp_window_scaling

接着在192.168.0.60即发送机上将窗口的scaling factor设置为14（最大值）。
# sysctl -w net.ipv4.tcp_adv_win_scale=14

 
实验三：网络连接和内存使用：

在192.168.0.60，即发送机上检查当前net.core.rmem_max和tcp.ipv4.tcp_rmem的设置：

[root@kdc ~]# sysctl -a | grep --color rmem
net.ipv4.udp_rmem_min = 4096
net.ipv4.tcp_rmem = 4096        87380   131072
net.core.rmem_default = 109568
net.core.rmem_max = 109568

现在我们将强制发送机对每个连接都使用512KiB的buffer size。
# sysctl -w net.core.rmem_max=524288
# sysctl -w net.ipv4.tcp_rmem="524288 524288 524288"

现在开两个窗口，其中一个用于监控内存的使用，而另外一个窗口用于监控apache进程的变化：

# watch -n1 'cat /proc/meminfo'
# watch -n1 'ps -ef | grep httpd | wc -l'

之后确保192.168.0.80上开启httpd进程，并在192.168.10.60上执行ab对其进行压力测试。
当然在这个实验当中，我们并非要对apache进行压力测试，我们的目的是要观察在一个系统处于很重的网络负载情况下对内存的使用。
# ab -n 100 http://192.168.0.X+100/
同样，可以将压力模拟到10个用户以致100到1000个用户的并发访问：
# ab -n 100 –c 10 http://192.168.0.X+100/
# ab -n 100 –c 100 http://192.168.0.X+100/









