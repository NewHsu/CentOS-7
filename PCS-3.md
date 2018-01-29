# PCS -- DB2 + web
## 介绍
说句实话很多人问我为什么不写WEB的HA，现在都应用层面大部分都已经使用负载均衡的模式在做了，很少会用HA，但是数据库的HA模式确实用的非常之多，所以这里举例也是用数据库，当然，无论DB2还是mysql还是其它数据库他们也都有自己的HA方法，具体用哪个看你自己了，我更习惯用系统的HA模式。

## DB2 HA 配置

### ywdb2节点安装配置DB2
安装DB2软件的时候一定要注意，俩边主机都要安装在相同的目录，并且双侧主机的账户UID和GID都要一样，如果出现偏差可能就不能进行切换了。
>以下所有操作都在集群存活的主机上执行: 以下操作主机均为ywdb2，查看cluster基础环境配置

    [root@ywdb2 /]# pcs status
    ……………………….
    Resource Group: db2group
        VIP	(ocf::heartbeat:IPaddr2):	Started ywdb2 
        lvm	(ocf::heartbeat:LVM):	Started ywdb2 
        dbfs	(ocf::heartbeat:Filesystem):	Started ywdb2

1.	上传DB2安装软件到HA主机并在双侧主机进行解压：

        #tar xvf v9.7fp3_25384_linuxx64_server.tar.gz

2.	创建DB2所需账户

        # groupadd db2grp
        # groupadd db2fgrp 
        # groupadd dasadm 
        # useradd -m -g db2grp -d /home/db2inst -s /bin/bash db2inst
        # useradd -m -g db2fgrp -d /home/db2fenc -s /bin/bash db2fenc
        # useradd -m -g dasadm -d /home/dasusr -s /bin/bash dasusr

3.	为DB2账户设置密码

        # passwd db2inst 
        New password:db2inst 
        Re-enter new password:db2inst Password changed 
        # passwd db2fenc
        …… 
        # passwd dasusr
        ……

4.	进行安装

        #cd ~/server
        #./db2_install
        #默认安装路径
        #输入ESE

5.	DB2 License

        #cd /opt/ibm/db2/V9.7/adm
        # ./db2licm –a /mnt/db2install/db2/license/db2ese_t.lic  
        //如果没有License 授权可以跳过该步骤

6.	创建DAS和数据库实例

        # cd /opt/ibm/db2/V9.7/instance
        # ./dascrt -u dasusr
        # ./db2icrt -p 50001 -u db2fenc db2inst
7.	更改DB2 库文件默认目录

        #su – db2inst
        $db2 get dbm cfg  //获得当前DB2配置
        ……..
        Default database path                       (DFTDBPATH) = /home/db2inst
        ……….

        $ db2 update dbm cfg using DFTDBPATH /dbdata    //更改到共享存储
        ……….
        Default database path                       (DFTDBPATH) = /dbdata
        ………
8.	设置共享存储权限
        
        #chown -R db2inst.db2grp /dbdata
9.	创建范例数据库

        #su – db2inst
        $db2sampl
        Starting the DB2 instance...
        Creating database "SAMPLE"...
        Connecting to database "SAMPLE"...
        Creating tables and data in schema "DB2INST"...
        Creating tables with XML columns and XML data in schema "DB2INST"...
        Stopping the DB2 instance...

        'db2sampl' processing complete.
10.	查看并连接范例数据库

        $ db2 list db directory
        …….
        Database 1 entry:

        Database alias                       = SAMPLE
        Database name                        = SAMPLE
        Local database directory             = /dbdata
        Database release level               = d.00
        Comment                              =
        Directory entry type                 = Indirect
        Catalog database partition number    = 0
        …….

        $db2start

        $db2 connect to sample
        ……
        Database server        = DB2/LINUXX8664 9.7.3
        SQL authorization ID   = DB2INST
        Local database alias   = SAMPLE

### ywdb1节点安装配置DB2
1.	迁移集群资源组db2group到ywdb1

        # pcs constraint location db2group  prefers ywdb1=INFINITY  
        //迁移资源组 
        pcs constraint show
        //查看有哪些任务在进行
        # pcs constraint remove location-db2group-ywdb1-INFINITY
        //迁移完成后一定不要忘记把迁移策略取消，把管理权交还给集群
2.	安装配置DB2

        方法如同ywdb2，执行1到8步

3.	将数据库catalog到ywdb1

        #su – db2inst
        $ db2 catalog  db sample on /dbdata
4.	启动数据库并进行链接测试

        #su – db2inst
        $db2start
        $db2 connect to sample
        ……..
        Database server        = DB2/LINUXX8664 9.7.3
        SQL authorization ID   = DB2INST
        Local database alias   = SAMPLE

### DB2加入集群
1.	加入集群之前，先关闭双侧主机DB2，让集群去控制DB2启动和停止，不要让DB2随系统启动

        #su – db2inst
        $db2stop force
	
2.	编写DB2启动和停止脚本要附带检查状态

        //我的脚本写的比较简单，你可以继续完善
        //脚本一定要放到/etc/init.d/目录，并且权限为755
        #!/bin/sh
        # chkconfig: 2345 99 01
        # processname:IBMDB2
        # description:db2 start
        
        DB2_HOME="/home/db2inst/sqllib" 
        DB2_OWNER="db2inst" 
        
        case "$1" in
        start )
        echo -n "starting IBM db2"
        su - $DB2_OWNER -c $DB2_HOME/adm/db2start
        touch /var/lock/db2
        echo "ok"
        RETVAL=$?
        ;;

        status)
        ps -aux | grep db2sysc | grep -v grep
        RETVAL=$?
        ;;

        stop )
        echo -n "shutdown IBM db2"
        su - $DB2_OWNER -c $DB2_HOME/adm/db2stop force
        rm -f /var/lock/db2
        echo "ok"
        RETVAL=$?
        ;;
        restart|reload)
        $0 stop
        $0 start
        RETVAL=$?
        ;;
        *)
        
        echo "usage:$0 start|stop|restart|reload"
        exit 1
        
        esac
        exit $RETVAL
        chmod 755 /etc/init.d/db2p.sh

3.	添加resource资源，在web页面添加（脚本在/etc/init.d/）
  <center>
    <img src="./images/cluster 7/db2startstop.PNG">
</center>
>指令添加：包含failure-timeout
        
    #pcs resource create dbstartstop lsb:db2.sh
    #pcs resource group add db2group dbstartstop
    #pcs resource meta dbstartstop  failure-timeout=30

### DB2切换测试
1.	检测条件为

        ps -aux | grep db2sysc | grep -v grep     //判断db2sysc  进程是否存在
	
2. 在资源启动的主机上kill掉db2sysc进程进行切换测试,未kill之前:

        Resource Group: db2group
            VIP	(ocf::heartbeat:IPaddr2):	Started ywdb1 
            lvm	(ocf::heartbeat:LVM):	Started ywdb1 
            dbfs	(ocf::heartbeat:Filesystem):	Started ywdb1 
            db2startstop	(lsb:db2.sh):	Started ywdb1
        [root@ywdb1 init.d]# ps -aux | grep db2sysc
        db2inst   76453  0.1  3.9 1473096 39872 ?       Sl   18:48   0:02 db2sysc 0
        root     110183  0.0  0.0 112656   972 pts/1    S+   19:26   0:00 grep --color=auto db2sysc

3. 杀掉之后切换到ywdb2执行

        [root@ywdb1 init.d]# kill -9 76453
        Resource Group: db2group
            VIP        (ocf::heartbeat:IPaddr2):	Started ywdb2
            lvm        (ocf::heartbeat:LVM):   Started ywdb2
            dbfs	(ocf::heartbeat:Filesystem):    Started ywdb2
            db2startstop	(lsb:db2.sh):   Started ywdb2

        Failed actions:
            db2startstop_monitor_60000 on ywdb1 'not running' (7): call=125, status=complete, exit-reason='none', ……..
3. 测试链接数据库

        [db2inst@ywdb2 ~]$ db2 connect to sample

        Database Connection Information

        Database server        = DB2/LINUXX8664 9.7.3
        SQL authorization ID   = DB2INST
        Local database alias   = SAMPLE

4. 添加一步状态查看。

## 继续Web集群
DB2这个实例是利用自建脚本来启动服务，相对来讲会复杂一下，但是PCS内会为我们提供一定的可构建集群服务的默认资源，使用起来也非常方便。

### Apache
1.	双侧安装http服务

        [root@ywdb1 ~]# yum -y install httpd
        [root@ywdb2 ~]# yum -y install httpd

2.	添加web集群虚拟IP

        [root@ywdb1 ~]# pcs resource create webvip ocf:heartbeat:IPaddr2 ip="192.168.56.190" cidr_netmask=32 op monitor interval=30s
        [root@ywdb1 ~]# pcs resource meta webvip failure-timeout=30
3.	设置WebServer资源

        [root@ywdb1 ~]#pcs resource create WebServer ocf:heartbeat:apache httpd="/usr/sbin/httpd" configfile="/etc/httpd/conf/httpd.conf" statusurl="http://localhost/server-status" op monitor interval=1min
        [root@ywdb1 ~]# pcs resource meta WebServer failure-timeout=30
4.	添加到group组执行
        
        [root@ywdb1 ~]# pcs resource group add HttpServer webvip WebServer
5.	配置httpd资源statusurl，双侧主机都要执行

        [root@ywdb1 ~]# cat > /etc/httpd/conf.d/status.conf << EOF
        <Location /server-status>
        SetHandler server-status
        Order deny,allow
        Deny from all
        Allow from localhost
        </Location> 
        EOF
6.	设置web页面 

        [root@ywdb1 ~]#cat <<-END >/var/www/html/index.html
        <html>
        <body>Hello ywdb1</body>
        </html>
        END
        [root@ywdb2 ~]#cat <<-END >/var/www/html/index.html
        <html>
        <body>Hello ywdb2</body>
        </html>
        END
* 本例采用的是本地磁盘，主要是让大家看清楚切换效果，实际生产环境都加可以利用上面已有的lvm进行共享磁盘设置，挂载到/var/www/html/，这样的话无论切换到哪个主机都会看到相同页面。
* 结合当前环境而言，我只有一个共享存储制作的LVM，如果我要是使用共享存储的其它LV来作为挂载的话，必须要保证我的web资源组和DB2资源组在同一台主机上运行。

7.	切换测试

        [root@ywdb1 ~]# pcs status
        ……
        Resource Group: HttpServer
            webvip	(ocf::heartbeat:IPaddr2):	Started ywdb2 
            WebServer	(ocf::heartbeat:apache):	Started ywdb2
        ……
        
        [root@ywdb1 ~]# pcs constraint location HttpServer prefers ywdb1=INFINITY
        [root@ywdb2 ~]# pcs  status
        ……
        Resource Group: HttpServer
            webvip	(ocf::heartbeat:IPaddr2):	Started ywdb1 
            WebServer	(ocf::heartbeat:apache):	Started ywdb1
        [root@ywdb1 ~]# pcs constraint remove location-HttpServer-ywdb1-INFINITY
 
* 实际生产环境中，已经很少用HA的技术保障WEB了，基本上都采用lvs来负载web页面了，更多的还是数据库在用HA或者CRM一类的系统用的多。

>总结
差双心跳，资源介绍，参数介绍等等

注意添加资源顺序，减少使用规则是次数
资源启动顺序
pcs constraint order set VIP lvm dbfs
pcs constraint order remove resource1 [resourceN]...
pcs resource relocate run

12、配置服务启动顺序
以避免出现资源冲突，语法：(pcs resource group add的时候也可以根据加的顺序依次启动，此配置为可选)
1.	# pcs constraint order [action] then [action]
2.	# pcs constraint order start VIP then start WEB
pcs resource update VIP op monitor interval=30s
查看集群成员
[root@node01 ~]# corosync-cmapctl |grep members  

