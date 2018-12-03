# journalctl
在CentOS7的版本中，相对应的体现出systemd的日志，相对应我们需要了解systemd的日志条目，同时新加入的journalctl，可以做日志查找和追溯等工作.

Systemd日志将日志数据存储在带有索引的结构化二进制文件中，此数据包含与日志事件相关的额外信息，例如，对于系统的日志事件，包含原始消息的设备和优先级。

通过journalctl命令从最旧的日志条目开始显示完整的系统日志
```
………………….
Oct 28 16:24:38 centos7.book setroubleshoot[5924]: Plugin Exception restorecon_source
Oct 28 16:24:38 centos7.book setroubleshoot[5924]: lookup_signature: found 0 matches with scores
Oct 28 16:24:38 centos7.book setroubleshoot[5924]: not in database yet
Oct 28 16:24:38 centos7.book setroubleshoot[5924]: sending alert to all clients
Oct 28 16:24:38 centos7.book setroubleshoot[5924]: SELinux is preventing /usr/sbin/httpd from 
…………………
```
Journalctl 命令以粗体文本突显优先级为notice或warning的消息，以`红色文本`突显优先级为error或更高级别的信息。
```
Journalctl –n  //默认显示最后10行
Journalctl –n 5  //显示5行
Journalctl –p err  //列出优先级为err或以上的条目
//级别为：debug/info/notice/warning/err/crit/alert/emerg
Journalctl –f   //显示最后10行，并进行监控实时输出记录，和tail –f类似
Journalctl –since today   //显示当天所有日志条目,支持yesterday/today/tomorrow
Journalctl –since “2015-10-21 20:21:00” –until “2015-10-25 12:00:00”
//输出时间段内的日志
Journalctl _PID=1  //显示pid为1的进程日志
Journalctl _UID=0 //显示源自用户0启动服务的所有systemd日志信息
Journalctl –since 9:00:00 _SYSTEM_UNIT=”httpd.service” 
//仅显示httpd，并且时间为当天早上9点以后的日志
```

### 永久存储
Systemd-journald 的日志是保存在`内存`中，可以将其设置保存在`磁盘`上，以便追溯。
默认情况下systemd日志保存在/run/log/journal中，意味着系统重新启动它会被清除,这是CentOS7的新机制，实际就是对于大多数系统来说，自上一次启动到现在运行的日志就足够了。
如果存放在/var/log/journal目录中，这样做的优点是可以启动后立即获得历史数据，然而并非所有数据都将永久保留。该日志具有一个内置的轮换机制，每月触发。
此外，默认情况下，日志的大小不能超过所处文件系统的10%，也不能造成文件系统的可用空间低于15%。这些值可以在/etc/system/journal.conf中调节。
```
[root@centos7 loganalyzer-3.6.5]# journalctl | head -2
-- Logs begin at Wed 2015-10-28 13:35:47 CST, end at Wed 2015-10-28 17:10:01 CST. --
Oct 28 13:35:47 localhost.localdomain systemd-journal[82]: Runtime journal is using 6.2M (max 49.6M, leaving 74.5M of free 490.4M, current limit 49.6M).
查看当前使用空间和总空间大小
```
用户以root身份创建/var/log/journal目录，使systemd日志变为永久日志
```
#mkdir /var/log/journal
```
确保/var/log/journal目录由root用户和systemd-journal所有，权限2755
```
#chown root:system-journal /var/log/journal
#chmod 2755 /var/log/journal
```
重新启动系统或者killall –USR1 system-journald

## 重要！时钟同步
### 设置本地时钟和时区
在整体的日志收集和查看日志过程中，必须保证系统中的日志时间戳正确无误，对于多个系统间分析日志而言，正确同步系统时间非常重要。
通过NTP（网络时间协议）来解决这个问题。
1.	Timedatectl 命令可以显示当前时间信息和设置时间，如系统时间和NTP同步
```
[root@localhost ~]# timedatectl 
      Local time: Thu 2015-10-29 11:28:55 CST
  Universal time: Thu 2015-10-29 03:28:55 UTC
        RTC time: Thu 2015-10-29 03:28:58
        Timezone: Asia/Shanghai (CST, +0800)
     NTP enabled: yes
NTP synchronized: yes
 RTC in local TZ: no
      DST active: n/a
```
```
[root@localhost ~]# timedatectl list-timezones 
Africa/Abidjan
Africa/Accra
Africa/Addis_Ababa
……
```
```
[root@localhost ~]# timedatectl set-timezone Asia/Shanghai
[root@localhost ~]# timedatectl set-time 9:00:00
```
2.	设置NTP
CentOS7中采用chronyd服务配置NTP
```
[root@localhost ~]# timedatectl set-ntp true
[root@localhost ~]# vim /etc/chrony.conf
# Use public servers from the pool.ntp.org project.
# Please consider joining the pool (http://www.pool.ntp.org/join.html).
Server  centos7.com  iburst
[root@localhost ~]# systemctl restart chronyd
[root@localhost ~]# chronyc sources -v
210 Number of sources = 4

  .-- Source mode  '^' = server, '=' = peer, '#' = local clock.
 / .- Source state '*' = current synced, '+' = combined , '-' = not combined,
| /   '?' = unreachable, 'x' = time may be in error, '~' = time too variable.
||                                                 .- xxxx [ yyyy ] +/- zzzz
||                                                /   xxxx = adjusted offset,
||         Log2(Polling interval) -.             |    yyyy = measured offset,
||                                  \            |    zzzz = estimated error.
||                                   |           |                         
MS Name/IP address         Stratum Poll Reach LastRx Last sample
===============================================================================
^* centos7.com                 2   6    17    31    -12us[ +261us] +/-   25ms
```

## 总结
生产系统中，养成全局收取日志的系统，采用日志服务器加页面分析，或者是采用日志服务器加自己的过滤规则写成的应用软件
在新的版本中可以使用journalctl来查看系统信息，并且调教过滤效果比较好，对比老版本而言这是一个非常大的改进
高端一点的生产日志服务器会监控日志，主要思路就是：
收集日志，异步写入存储池，采用大数据或者其他方式进行实施分析。
