# GlusterFS 故障恢复

常在河边走，哪有不湿鞋？

1. 分布式卷灾难恢复
GlusteFS 崩溃，数据恢复（严重灾难，仅分布式卷适用于以下方法）
在GlusterFS无法启动的情况下可以将各个挂载目录的文件进行合并，然后即可恢复出原有目录的内容。
这里要注意 ---------T   这个是blance 之后留下来的文件，千万不要复制过去。
scp -r `ls -l /data/ | grep -v "\---------T" | awk '{print $9}'`  g1:/cdr/

2. 保留磁盘数据，更换主机（灾难恢复）

        1: 安装软件
        2:恢复原来的节点名称和IP (同原来机器一样)
        3: UID 查看 (新机器)
        cat /var/lib/glusterd/glusterd.info
        4: 在线的其他节上上查看原来更换主机的UID
        cat /var/lib/glusterd/peers/id
        找到server2 的UID
        可以使用gluster peer status 进行查看id
        5：找到的ID 进行复制,然后更改server的新ID
        6：重启gluster
        7： 添加节点(要恢复的机器上操作.添加存在的节点)
        gluster volume sync nodename all

3. 双副本恢复 （重大灾难，集群无法启动，但数据可访问）
这里要注意 ---------T   这个是blance 之后留下来的文件，千万不要复制过去。
scp -r `ls -l /data/ | grep -v "\---------T" | awk '{print $9}'`  g1:/cdr/

4. 替换多副本brick （重大灾难，主机宕机无法启动）

        Gluster volume replace-brick <VOLNAME> <BRICK> <NEW-BRICK> {start [force]|pause|abort|status|commit [force]} - replace-brick operations

        Gluster volume replace-brick gfs g4:/g4 g5:/g5 commit force

        volume rebalance <VOLNAME> {{fix-layout start} | {start [force]|stop|status}} - rebalance operations  
        gluster volume repalance gfs start force
        gluster volume repalance gfs status 


11.Q&A

Q1：Gluster需要占用哪些端口？
Gluster管理服务使用24007端口，Infiniband管理使用24008端口，每个brick进程占用一个端口。比如4个brick，使用24009-24012端口。Gluster内置NFS服务使用34865-34867端口。此外，portmapper使用111端口，同时打开TCP和UDP端口。

Q2：创建Gluster资源池出问题？
首先，检查nslookup是否可以正确解析DNS和IP。其次，确认没有使用/etc/hosts直接定义主机名。虽然理论上没有问题，但集群规模一大很多管理员就会犯低级错误，浪费大量时间。再者，验证Gluster服务所需的24007端口是否可以连接(比如telnet)？Gluster其他命令是否可以成功执行？如果不能，Gluster服务很有可能没有启动。

Q3：如何检查Gluster服务是否运行？
可以使用如下命令检查Gluster服务状态：
(1) service glusterd status
(2) systemctl status glusterd.service
(3) /etc/init.d/glusterd status

Q4：无法在server端挂载(mount)Gluster卷？
检查gluster卷信息，使用gluster volume info确认volume处于启动状态。运行命令“showmount -e <glusternode>“，确认可以输出volume相关信息。

Q5：无法在client端挂载(mount)Gluster卷？
检查网络连接是否正常，确认glusterd服务在所有节点上正常运行，确认所挂载volume处于启动状态。
 
Q6：升级Gluster后，客户端无法连接？
如果使用原生客户端访问，确认Gluster客户端和服务端软件版本一致。通常情况下，客户端需要重新挂载卷。
 
Q7： 运行“glusterpeer probe“，不同节点输出结果可能不一致？
这个通常不是问题。每个节点输出显示其他节点信息，并不包括当前节点；不管在何处运行命令，节点的UUID在所有节点上都是相同和唯一的；输出状态通常显示“Peer in Cluster (Connected)“，这个值应该和/var/lib/glusterd/glusterd.info匹配。
 
Q8：数据传输过程中意外杀掉gluster服务进程？
所有数据都不会丢失。Glusterd进程仅用于集群管理，比如集群节点扩展、创建新卷和修改旧卷，以及卷的启停和客户端mount时信息获取。杀掉gluster服务进程，仅仅是一些集群管理操作无法进行，并不会造成数据丢失或不可访问。
 
Q9：意外卸载gluster？
如果Gluster配置信息没有删除，重新安装相同版本gluster软件，然后重启服务即可。Gluster配置信息被删除，但数据仍保留的话，可以通过创建新卷，正确迁移数据，可以恢复gluster卷和数据。友情提示：配置信息要同步备份，执行删除、卸载等操作一定要谨慎。
 
Q10：无法通过NFS挂载卷？
这里使用Gluster内置NFS服务，确认系统内核NFS服务没有运行。再者，确认rpcbind或portmap服务处于正常运行中。内置NFS服务目前不支持NFS v4，对于新Linux发行版默认使用v4进行连接，mount时指定选项vers=3。
mount -t nfs -o vers=3 server2:/myglustervolume/gluster/mount/point
 
Q11：双节点复制卷，一个节点发生故障并完成修复，数据如何同步？
复制卷会自动进行数据同步和修复，这个在同步访问数据时触发，也可以手动触发。3.3以后版本，系统会启动一个服务自动进行自修复，无需人工干预，及时保持数据副本同步。
 
Q12：Gluster日志在系统什么位置？
新旧版本日志都位于/var/log/glusterfs
 
Q13：如何轮转(rotate)Gluster日志？
使用gluster命令操作：gluster volume logrotate myglustervolume
 
 Q14:Gluster配置文件在系统什么位置？
3.3以上版本位于/var/lib/glusterd，老版本位于/etc/glusterd/。
 
Q15：数据库运行在gluster卷上出现很多奇怪的错误和不一致性？
Gluster目前不支持类似数据库的结构化数据存储，尤其是大量事务处理和并发连接。建议不要使用Gluster运行数据库系统，但Gluster作为数据库备份是一个很不错的选择。
 
Q16：Gluster系统异常，重启服务后问题依旧。
很有可能是某些服务进程处于僵死状态，使用ps -ax | grep glu命令查看。如果发出shutdown命令后，一些进程仍然处于运行状态，使用killall -9gluster{,d,fs,fsd}杀掉进程，或者硬重启系统。
 
Q17：需要在每个节点都运行Gluster命令吗？
这个根据命令而定。一些命令只需要在Gluster集群中任意一个节点执行一次即可，比如“gluster volume create”，而例如“gluster peerstatus ”命令可以在每个节点独立多次执行。

Q18：如何快速检查所有节点状态？
Gluster工具可以指定选项 --remote-host在远程节点上执行命令，比如gluster --remote-host=server2 peer status。如果配置了CTDB，可以使用“onnode”在指定节点上执行命令。另外，还可以通过ssh-keygen和ssh-copy-id配置SSH无密码远程登录和执行命令。

Q19：Gluster导致网络、内核、文件系统等出现问题？
可能。但是，绝大多数情况下，Gluster或者软件都不会导致网络或存储等基础资源出现问题。如果发现由Gluster引起的问题，可以提交Bug和patch，并可以社区和邮件列表中讨论，以帮助改善Gluster系统。

Q20：为什么会发生传输端点(transportendpoint)没有连接？
在Gluster日志中看到这种错误消息很正常，表明Gluster由于一些原因无法通信。通常情况下，这是由于集群中某些存储或网络资源饱和引起的，如果这类错误消息大量重复报告，就需要解决问题。使用相关技术手段可以解决大部分的问题，另外有些情况可能由以下原因引起。
1、需要升级RAID/NIC驱动或fireware；
2、第三方备份系统在相同时间运行；
3、周期更新locate数据库包含了brick和网络文件系统；
4、过多rsync作业工作在gluster brick或mount点。

