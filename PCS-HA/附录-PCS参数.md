# PCS 参数

Pacemaker
Pacemaker，即Cluster Resource Manager（CRM），管理整个HA集群，客户端通过pacemaker管理和监控整个集群。

CRM常用ocf和lsb两种资源类型：

    ocf格式的启动脚本在/usr/lib/ocf/resource.d/
    lsb的脚本一般在/etc/rc.d/init.d/

## 1. PCS创建命令

### 1.1 群集的创建：

    1. 配置群集节点的认证as the hacluster user:
    [shell]# pcs cluster auth node1 node1
    2. 创建一个二个节点的群集
    [shell]# pcs cluster setup --name testcluster node1 node1
    3. 设置资源默认粘性（防止资源回切）
    [shell]# pcs resource defaults resource-stickiness=100
    4. 设置资源超时时间
    [shell]# pcs resource op defaults timeout=90s
    5. 双节点时，忽略节点quorum功能
    [shell]# pcs property set no-quorum-policy=ignore
    6. 没有 Fencing设备时，禁用STONITH 组件功能
    在 stonith-enabled="false" 的情况下，分布式锁管理器 (DLM) 等资源以及依赖DLM 的所有服务（例如 cLVM2.GFS2 和 OCFS2）都将无法启动。
    [shell]# pcs property set stonith-enabled=false
    7.启动停止集群 
    [shell]# pcs cluster start --all  
    [shell]# pcs cluster stop --all  

### 1.2 资源的创建：	

    1. 查看可用资源
    查看支持资源列表，pcs 
    [shell]# pcs resource list 							
    查看资源使用参数
    [shell]#pcs resource describe ocf:heartbeat:IPaddr2

    2. 创建虚拟IP
    [shell]# pcs resource create VIP ocf:heartbeat:IPaddr2 \
    ip="192.168.56.120" cidr_netmask=32 nic=eth0 op monitor interval=30s 

    3. 创建Apache(httpd)
    [shell]# pcs resource create WebServer ocf:heartbeat:apache \
    httpd="/usr/sbin/httpd" configfile="/etc/httpd/conf/httpd.conf" \
    statusurl="http://localhost/server-status" op monitor interval=1min

    其余资源还请参考相关参数和man配置文件进行参数的增补和设定.

### 1.3 调整集群：

    1. 配置资源约束
    [shell]# pcs resource group add WebSrvs VIP  ## 配置资源组，组中资源会在同一节点运行
    [shell]# pcs resource group remove WebSrvs VIP  ## 移除组中的指定资源
    [shell]# pcs resource master WebDataClone WebData  	## 配置具有多个状态的资源，如 DRBD master/slave状态
    [shell]# pcs constraint colocation add WebServer VIP INFINITY  ## 配置资源捆绑关系
    [shell]# pcs constraint colocation remove WebServer  ## 移除资源捆绑关系约束中资源
    [shell]# pcs constraint order VIP then WebServer  ## 配置资源启动顺序
    [shell]# pcs constraint order remove VIP  ## 移除资源启动顺序约束中资源
    [shell]# pcs constraint --full  ## 查看资源约束关系

    2. 配置资源位置
    [shell]# pcs constraint location WebServer prefers node1
    ## 指定资源默认某个节点，node=50 指定增加的 score
    
    [shell]# pcs constraint location WebServer avoids node1
    ## 指定资源避开某个节点，node=50 指定减少的 score
    
    [shell]# pcs constraint location remove location-WebServer
    ## 移除资源节点位置约束中资源ID，可用pcs config获取
    
    [shell]# pcs constraint location WebServer prefers node1=INFINITY   ## 手工移动资源节点，指定节点资源的 score of INFINITY

    [shell]# crm_simulate -sL   ## 验证节点资源 score 值

    3. 修改资源配置
    [shell]# pcs resource update WebFS ## 更新资源配置
    [shell]# pcs resource delete WebFS ## 删除指定资源

    4. 管理群集资源
    [shell]# pcs resource disable VIP    ## 禁用资源
    [shell]# pcs resource enable VIP   ## 启用资源
    [shell]# pcs resource failcount show VIP   ## 显示指定资源的错误计数
    [shell]# pcs resource failcount reset VIP  ## 清除指定资源的错误计数 
    [shell]# pcs resource cleanup VIP   ## 清除指定资源的状态与错误计数

### 1.4 配置Fencing设备，启用STONITH

    1. 查询Fence设备资源
    [shell]# pcs stonith list  ## 查看支持Fence列表
    [shell]# pcs stonith describe fence_vmware_soap	   ## 查看Fence资源使用参数
	
    2. 配置fence设备资源
    [shell]# pcs stonith create ipmi-fencing fence_ipmilan \
    pcmk_host_list="pcmk-1 pcmk-2" ipaddr="10.10.10.1" login=testuser passwd=acd123 op monitor interval=60s

    3. 配置VMWARE (fence_vmware_soap)
   
        3.1 确认vmware虚拟机的状态：
        [shell]# fence_vmware_soap -o list -a vcenter.example.com -l admin -p <password> -z  			## 获取虚拟机UUID
        [shell]# fence_vmware_soap -o status -a vcenter.example.com -l admin -p <password> -z -U <UUID> 	## 查看状态
        [shell]# fence_vmware_soap -o status -a vcenter.example.com -l admin -p <password> -z -n <vm name>

        3.2 配置fence_vmware_soap
        [shell]# pcs stonith create vmware-fencing fence_vmware_soap \
        action="reboot" ipaddr="192.168.56.10" login="vmuser" passwd="vmuserpd" ssl="1" pcmk_host_argument="uuid" pcmk_host_check="static-list" pcmk_host_list="node1,node1" pcmk_host_map="node1:UUID（此处填写vm虚拟机uuid）;node2:UUID（此处填写vm虚拟机uuid）" shell_timeout=60s login_timeout=60s op monitor interval=90s

    4. 管理 STONITH
    [shell]# pcs resource clone vmware-fencing    ## clone stonith资源，供多节点启动
    [shell]# pcs property set stonith-enabled=true   ## 启用 stonith 组件功能
    [shell]# pcs stonith cleanup vmware-fencing	   ## 清除Fence资源的状态与错误计数
    [shell]# pcs stonith fence node1    ## fencing指定节点

### 1.5 群集操作命令

    1. 验证群集安装
    [shell]# pacemakerd -F    # 查看pacemaker组件，ps axf | grep pacemaker
    [shell]# corosync-cfgtool -s  	## 查看corosync序号
    [shell]# corosync-cmapctl | grep members  	## corosync 2.3.x
    [shell]# corosync-objctl | grep members  	## corosync 1.4.x

    2. 查看群集资源
    [shell]# pcs resource standards  			## 查看支持资源类型
    [shell]# pcs resource providers  			## 查看资源提供商
    [shell]# pcs resource agents				## 查看所有资源代理
    [shell]# pcs resource list 				## 查看支持资源列表
    [shell]# pcs stonith list				## 查看支持Fence列表
    [shell]# pcs property list --all			## 显示群集默认变量参数
    [shell]# crm_simulate -sL    				## 检验资源 score 值

    3. 使用群集脚本
    [shell]# pcs cluster cib ra_cfg    	## 将群集资源配置信息保存在指定文件
    [shell]# pcs -f ra_cfg resource create    ## 创建群集资源并保存在指定文件中（而非保存在运行配置）
    [shell]# pcs -f ra_cfg resource show  	## 显示指定文件的配置信息，检查无误后
    [shell]# pcs cluster cib-push ra_cfg  	## 将指定配置文件加载到运行配置中

    4. STONITH 设备操作
    [shell]# stonith_admin -I    		## 查询fence设备
    [shell]# stonith_admin -M -a agent_name   	## 查询fence设备的元数据，stonith_admin -M -a fence_vmware_soap
    [shell]# stonith_admin --reboot nodename    ## 测试 STONITH 设备

    5. 查看群集配置
    [shell]# crm_verify -L -V    	## 检查配置有无错误
    [shell]# pcs property    		## 查看群集属性
    [shell]# pcs stonith    		## 查看stonith
    [shell]# pcs constraint    		## 查看资源约束
    [shell]# pcs config    			## 查看群集资源配置
    [shell]# pcs cluster cib    	## 以XML格式显示群集配置

    6. 管理群集
    [shell]# pcs status  			## 查看群集状态
    [shell]# pcs status cluster   
    [shell]# pcs status corosync
    [shell]# pcs cluster stop [node1]  	## 停止群集
    [shell]# pcs cluster start --all    ## 启动群集
    [shell]# pcs cluster standby node1  	## 将节点置为后备standby状态[shell]# pcs cluster unstandby node1    ## 将节点置为非standby状态
    [shell]# pcs cluster destroy [--all]  	## 删除群集，[--all]同时恢复corosync.conf文件
    [shell]# pcs resource cleanup VIP	## 清除指定资源的状态与错误计数
    [shell]# pcs stonith cleanup vmware-fencing  	## 清除Fence资源的状态与错误计数

    7. 备份和还原
    [shell]# pcs config backup filename  ##备份集群文件
    [shell]# pcs config restore [--local] [filename] ##还原集群文件



## 2. PCS 参数

### 2.1 为集群配置超时值
* 使用 pcs cluster setup 命令创建集群时，会将集群超时值设定为默认值，这适用于大多数集群配置。但如果您的系统需要不同的超时值，则可以使用 pcs cluster setup 选项修改这些数值。

|选项|描述|
|:---|:---|
|--token timeout|以毫秒为单位设定未收到令牌后多长时间宣布令牌丢失（默认为 1000 毫秒）
|--join timeout|以毫秒为单位设定等待加入信息的时间（默认为 50 毫秒）
|--consensus timeout|以毫秒为单位设定启动新一轮成员关系配置前等待达成共识的时间（默认为 1200 毫秒）
|--miss_count_const count |设定重新传送前检查令牌信息接收情况的最多次数（默认为 5 条信息）
|--fail_recv_const failures|指定构成新配置前，在应当收到信息但却没有收到时执行的令牌轮换次数（默认为 2500 次失败）

### 2.2 配置仲裁选项
 * Red Hat Enterprise Linux High Availability Add-On 集群使用 votequorum 服务避免出现裂脑（split-brain）的情况。会为集群的每个系统都分配大量投票，并只有在出现大多数投票时才允许执行集群操作。必须将这个服务上传至所有节点，或者根本不上传至任何节点。如果将其上传至集群节点的子网中，则会出现意外结果。有关配置和操作 votequorum 服务的详情，请查看 votequorum(5) man page。
* 当您了解到集群处于投票数不足（inquorate）的情况，但仍想继续进行资源管理时，则可以使用下面的命令防止集群在建立仲裁时等待所有节点投票。 
    
        # pcs cluster quorum unblock

|选项|描述|
|:---|:---|
|--wait_for_all	|启用该选项后，只有在至少有一次可同时看到所有节点后，才会第一次建立 quroate 状态。
|--auto_tie_breaker|启用后，在决定性情况下，集群可以接受同时有 50% 的节点失败。集群分区或一组仍与 auto_tie_breaker_node 中配置的 nodeid（如果没有配置，则为最低 nodeid）沟通的节点仍保持 quorate 状态。其他节点则将处于 inquorate 状态。
|--last_man_standing|启用后，集群可动态重新计算 expected_votes，并在具体情况下进行仲裁。启用这个选项时必须启用 wait_for_all，并指定 last_man_standing_window。
|--last_man_standing_window|集群丢失节点后，等待重新计算 expected_votes 和仲裁的时间（单位：毫秒）。

### 2.3 Fencing 设备的常规属性

|项|类型|默认值|描述|
|:---|:---|:---|:---|
|stonith-timeout|time|60s|在每个 stonith 设备中等待 STONITH 动作完成的时间，可覆盖 stonith-timeout 集群属性。
|priority|整数|0|stonith 资源的优先权。这些设备将按照优先权从高到低的顺序排列。
|pcmk_host_map|字符串||为不支持主机名的设备提供的主机名和端口号映射。例如：node1:1;node2:2,3 让集群的节点 1 使用端口 1，节点 2 使用端口 2 和 3。
|pcmk_host_list|字符串||这台设备控制的机器列表（自选，pcmk_host_check=static-list 除外）。
|pcmk_host_check|字符串|dynamic-list|如何确定该设备控制的机器。允许值为：dynamic-list（查询该设备），static-list（检查 pcmk_host_list 属性），none（假设每台设备都可以隔离所有机器）。|

### 2.4 资源元数据选项

|项|默认值|描述|
|:---|:---|:---|
|priority|0|如果无法保证所有资源都处于活跃状态，则集群会停止低优先权资源，以便让高优先权资源保持活跃状态。
|target-role|Started|该集群应让这个资源保持为何种状态？允许值为：Stopped - 强制资源停止;Started - 允许起源启动（在多状态资源的情况下，不能将其提升至主资源);Master - 允许资源启动，并在适当时提升。
|is-managed|true|集群是否允许启动和停止该资源？允许值为：true, false
|resource-stickiness|0|表示该资源留在原有位置的倾向值。
|requires|Calculated|表示在什么条件下启动该资源。默认为 fencing，但在下属条件下除外。可能值为：<br>nothing - 该集群总是可以启动该资源。<br>quorum - 只有在大多数配置的节点活跃的情况下该集群方可启动这个资源。如果 stonith-enabled 为 false，或资源的 standard 为 stonith，这就是默认值。<br>fencing - 只有在大多数配置的节点活跃，同时已关闭所有失败或未知节点的情况下该集群方可启动这个资源。<br>unfencing - 只有在大多数配置的节点活跃，同时已关闭所有失败或未知节点的情况下，该集群只能在 未隔离 的节点中启动该资源。<br>如果已为 fencing 失败设定 provides=unfencing stonith 元数据选项，则这个值就是默认值。
|migration-threshold|INFINITY（禁用）|将某个节点标记为无权托管这个资源前，这个资源可在该节点中出现失败的次数。
|failure-timeout|0（禁用）|与 migration-threshold 选项一同使用，代表将其视为没有发生过失败，并可能允许该资源返回其失败的节点前需要等待的秒数。
|multiple-active|stop_start|如果发现该资源从未在一个以上节点中活跃时，集群该如何响应。允许值为:<br>block - 将该资源标记为 unmanaged。<br>stop_only - 停止所有活跃实例并保留原状。<br>stop_start -停止所有活跃实例并只在一个位置启动该资源。 

### 2.5 资源操作
为保证资源正常工作，可在资源定义中添加监控操作。如果没有为资源指定监控操作，默认情况下 pcs 命令会创建一个监控操作，操作间隔由资源代理决定。如果资源代理未提供默认监控间隔，则 pcs 命令将创建一个以 60 秒为间隔的监控操作。 

|选项|描述|
|:---|:---|
|id|该操作的特定名称。配置操作时系统会分配这个名称。
|name|要执行的操作。常用值为：monitor, start, stop
|interval|执行该操作的频率（秒）。默认值为：0，就是说从不执行。
|timeout|宣布操作失败前等待的时间长度。如果发现您的系统中包含某个资源，该资源需要很长时间完成启动或停止，或在启动时执行非循环监控操作，所需时间超过了系统允许的宣布该操作失败所需时间，则可增大其默认值 20，或 "op defaults" 部分的 timeout 值。
|on-fail|操作从未失败时采用的动作。允许值为:<br>ignore - 假设资源未失败。<br>block - 不对该资源执行任何进一步的操作。<br>stop - 停止该资源且不在任何其他位置启动。<br>restart - 停止该资源并重新启动（可能是在不同节点中）。<br>fence - 使用 STONITH 隔离资源失败的节点。<br>standby - 将全部资源从资源失败的节点中移除。<br>启用 STONITH 时的默认操作为 stop，否则为 block。所有其他操作默认为 restart。
|enabled|如果为 false，则将该操作视为不存在。允许值为：true, false


### 2.6 资源限制
* 通过为那个资源配置限制条件决定集群中某个资源的行为。可配置以下限制分类：
    
    1. 位置限制 — 位置限制决定某个资源可在哪个节点中运行。
    2. 顺序限制 — 顺序限制决定资源的运行顺序。
    3. 节点共置（colocation） 限制 — 节点共置限制决定相对于其他资源应放置资源的位置。 
* 为简化配置一组限制，以便将一组资源放在一起以保证资源按顺序启动，并按相反的顺序停止，Pacemaker 支持资源组的概念。

|选项|描述|
|:---|:---|
|rsc|资源名称|
|node|节点名称|
|score|确定某个资源应该或避免在某个节点中运行的指数。INFINITY 值将 "should" 改为 "must"；INFINITY 是资源位置限制的默认分值。 

### 2.7  顺序限制
顺序限制决定资源运行顺序，可配置顺序限制以决定资源的启动和停止顺序。

|选项|描述|
|:---|:---|
|resource_id|执行动作的资源名称。
|action|在资源中执行的动作。action 属性的可能值为：<br>start - 启动该资源。<br>stop - 停止该资源。<br>promote - 将某个资源从辅资源提升为主资源。<br>demote - 将某个资源从主资源降级为辅资源。<br>如果未指定动作，则默认动作为 start。
|kind option|如何加强限制。kind 选项的可能值如下：<br>Optional - 只可在两个资源均启动和/或停止时使用。<br>Mandatory - 总是使用该值（默认值）。如果指定的第一个资源停止或无法启动，则必须停止第二个指定的资源。<br>Serialize - 确定不会对一组资源同时执行 stop/start 操作。
|symmetrical| 选项如果使用默认值 true，则以相反的顺序停止这些资源。默认值为：true|

### 2.8 顺序相关
* 强制排序表示如果指定的第一个资源未处于活跃状态，则无法运行指定的第二个资源。这是 kind 选项的默认值。采用这个默认值可保证您指定的第二个资源会在指定的第一个资源更改状态时有所响应。

    1. 如果指定的第一个资源正在运行，并已被停止，则指定的第二个资源也会停止（如果该资源正在运行）。
    2. 如果指定的第一个资源没有运行，且无法启动，则指定的第二个资源也会停止（如果该资源正在运行）。
    3. 如果指定的第一个资源已重启，同时指定的第二个资源正在运行，则指定的第二个资源会停止，然后重启。 

### 2.9 Pacemaker 集群属性
* 使用集群属性控制在集群操作过程中遇到问题时的集群行为。 

|项|默认值|描述|
|:---|:---|:---|
|batch-limit|30	|允许平行运行的转移引擎（transition engine，TE）数。所谓“正确”值要具体看网络和集群节点速度和负载。
|migration-limit|-1（无限）|允许在某个节点中平行运行 TE 的迁移任务数。
|no-quorum-policy|stop|集群没有仲裁时该做什么？允许值为：<br>ignore - 继续进行所有资源的管理<br>freeze - 继续资源管理，但不要恢复不在受影响分区中的资源<br> stop - 停止受影响集群分区中的所有资源<br>suicide - 隔离受影响集群分区中的所有资源
|symmetric-cluster|true|表示资源是否默认可在任意节点中运行。
|stonith-enabled|true|表示应隔离失败的节点及包含无法停止资源的节点。要保护数据则需要将这个选项设定为 true。如果设定为 true，或未设定，则在配置更多 STONITH 前，该集群会拒绝启动资源。
|stonith-action|reboot|发送到 STONITH 设备的动作。允许值为：reboot、off。还允许使用 poweroff，但只能用于旧有设备。
|cluster-delay|60s|网络轮询延迟（动作执行除外）。所谓“正确”值要具体看网络和集群节点速度和负载。
|stop-orphan-resources|true|表示是否应该停止删除的资源。
|stop-orphan-actions|true|表示是否应该取消删除的动作。
|start-failure-is-fatal|true|将其设定为 false 时，该集群会使用资源的 resource-failure-stickiness 值，而不是 failcount。
|pe-error-series-max|-1 (all)|导致要保存 ERROR 的 PE 输入数。报告问题时使用。
|pe-warn-series-max|-1 (all)|导致要保存 WARNING 的 PE 输入数。报告问题时使用。
|pe-input-series-max|-1 (all)|要保存的“正常” PE 输入数。报告问题时使用。
|cluster-infrastructure||目前正在运行的 Pacemaker 中堆积的信息。可用于信息及诊断目的，但用户无法进行配置。
|dc-version	||集群指定控制器（Designated Controller，DC）中的 Pacemaker 版本。可用于诊断目的，但用户无法进行配置。
|last-lrm-refresh||本地资源管理器的最后一次刷新，新世纪后采用秒为单位。可用于诊断目的，但用户无法进行配置。
|cluster-recheck-interval|15min|对基于时间的选项变更进行轮询的时间间隔。允许值为：0 代表禁用轮询；正数值代表间隔秒数（除非指定其他 SI 单位，比如 5 分钟）。
|default-action-timeout|20s|Pacemaker 动作的超时值。这个用于资源自身操作的设定总是优先于集群选项的默认设定值。
|maintenance-mode|false|维护模式让集群进入“无操作”模式，且在未告知其启动或停止服务前不会进行任何此类操作。完成维护模式后，集群会检查所有服务的当前状态，然后根据需要停止或启动任意服务。
|shutdown-escalation|20min|停止尝试正常关机并退出前要等待的时间。仅作为高级配置使用。
|stonith-timeout|60s|等待 SONITH 动作完成的时间。
|stop-all-resources|false|集群是否应停止所有资源。
|default-resource-stickiness|5000|代表有多少资源首选留在其所在位置。建议将这个值作为资源/操作默认值，而不是集群选项进行设定。
|is-managed-default|true|代表是否允许集群启动或停止某个资源。建议将这个值作为资源/操作默认值，而不是集群选项进行设定。
|enable-acl|false|代表集群是否可使用 pcs acl 设定的访问控制列表。 


## 总结
这些参数和默认值的调整将会使得集群更匹配生产需求，而这一部分参数仅仅是PCS的一小部分，其实还有很多高级功能，比如资源clone，ACL规则等等，但是实在是用的不多，生产中求的是稳，尽可能的架构简单，服务稳定，出错快速恢复，如果架构复杂，出问题查起来也费事。如果真的用到了，需要了解更详细的，可以参考PCS的官网http://clusterlabs.org/pacemaker/doc/中的内容。