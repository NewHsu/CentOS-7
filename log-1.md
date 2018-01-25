# log，log，还是log.
## rsyslog介绍

rsyslog是syslog的升级版本, 现今CentOS 6/7已经全部是rsyslog. rsyslog是日志管理系统,记录着过去发生系统事件、内核事件、以及应用事件等等,将这些事件级别进行定义并记录到指定位置. 
rsyslog支持C/S架构,可通过UDP/TCP协议提供远程日志记录服务.

## Rsyslog的特性

1. 直接将日志写入到数据库。
2. 日志队列（内存队列和磁盘队列）。
3. 灵活的模板机制，可以得到多种输出格式。
4. 插件式结构，多种多样的输入、输出模块。
5. 可以把日志存放在Mysql ，PostgreSQL，Oracle等数据库中。

## CentOS 7 日志介绍
* 进程和操作系统内核需要能够为发生的事件记录日志。这些日志可用于系统审核和问题的故障排除，CentOS7中内建了一个基于系统日志协议的标准日志记录系统。许多程序使用此系统记录事件，并整理到日志文件中，默认存储在”/var/log”目录中。
* CentOS7 中的系统日志消息由2个服务负责处理，分别是 systemd-journald 和 rsyslog.
 
|名称|释义|
|:--|:--|
|Systemd-journald|该守护进程提供一种改进的日志管理服务，可以收集来自内核，启动过程的早期阶段，标准输出，系统日志，以及守护进程启动和运行期间错误的消息。系统日志消息可以由systemd-journald转到rsyslog做进一步处理。|
|Rsyslog|该服务随后根据类型或者设备类型以及优先级排列系统日志消息，写入/var/log/目录内的文件中|
|/var/log|该目录保管由rsyslog维护的各种特定于系统和服务的日志文件.|

### 常用系统日志文件
|日志文件|作用|
|:---|:---|
|/var/log/messages|记录系统日志消息，大多数的系统信息和服务启动系统都记录在这里|
|/var/log/secure|安全和身份验证的消息|
|/var/log/maillog|与邮件服务器相关的日志信息|
|/var/log/cron|Crontab定期执行任务的相关日志|
|/var/log/boot.log|与系统启动相关的日志|

### 日志级别
|序号|优先级|严重性|
|:--|:--|:--|
|0|Emerg|系统不可用|
|1|Alert|必须立刻采取措施|
|2|Crit|严重情况|
|3|Err|非严重错误|
|4|Warning|警告状态|
|5|Notice|正常但是重要的事件|
|6|Info|普通信息事件|
|7|Debug|调试级别信息|

## 配置文件
* Rsyslogd服务的配置文件在”/etc/rsyslog.conf”文件，以及”/etc/rsyslog.d”中的*.conf文件进行配置。
* 可以将自定义的带有.conf后缀的文件放入/etc/rsyslog.d目录，可以更改rsyslogd配置不被rsyslog更新覆盖。

### /etc/rsyslog.conf的组成
1. 加载模块部分->该部分是加载功能模块部分，例如需要使用mysql数据，需要在该部分先加载ommysql模块
```
#### MODULES ####

# The imjournal module bellow is now used as a message source instead of imuxsock.
$ModLoad imuxsock # provides support for local system logging (e.g. via logger command)
```

2. 全局配置->定义rsyslog的配置参数
```
#### GLOBAL DIRECTIVES ####

# Where to place auxiliary files
$WorkDirectory /var/lib/rsyslog
```

3. 规则部分
```
#### RULES ####
#kern.*                                                 /dev/console
//关于内核的所有日志都放到/dev/console(控制台)
*.info;mail.none;authpriv.none;cron.none                /var/log/messages
//记录所有日志类型的info级别以及大于info级别的信息到/var/log/messages，但是mail邮件信息，authpriv验证方面的信息和cron时间任务相关的信息除外
authpriv.*                                              /var/log/secure
//authpriv验证相关的所有信息存放在/var/log/secure
mail.*                                                  -/var/log/maillog
//邮件的所有信息存放在/var/log/maillog; 这里有一个"-"符号, 表示是使用异步的方式记录, 因为日志一般会比较大
cron.*                                                  /var/log/cron
//计划任务有关的信息存放在/var/log/cron
*.emerg                                                 :omusrmsg:*
//记录所有的大于等于emerg级别信息, 以wall方式发送给每个登录到系统的人
uucp,news.crit                                          /var/log/spooler
//记录uucp,news.crit等存放在/var/log/spooler
local7.*                                                /var/log/boot.log
//启动的相关信息
```
```
相关格式：
———————————————————————-
日志设备(类型).(连接符号)日志级别   日志处理方式(action)
日志设备(可以理解为日志类型):
———————————————————————-
auth        –pam产生的日志
authpriv    –ssh,ftp等登录信息的验证信息
cron        –时间任务相关
kern        –内核
lpr         –打印
mail        –邮件
mark(syslog)–rsyslog服务内部的信息,时间标识
news        –新闻组
user        –用户程序产生的相关信息
uucp        –unix to unix copy, unix主机之间相关的通讯
local 1~7   –自定义的日志设备
```
4. 转发->日志转发规则（集中采集日志所需配置）
```
# ### begin forwarding rule ###
# remote host is: name/ip:port, e.g. 192.168.0.1:514, port optional
#*.* @@remote-host:514
# ### end of the forwarding rule ###
``` 

### 日志格式 (时间戳：主机名：应用名：事件内容)
```
#cat /var/log/messages
……
Oct 26 15:30:29 centos7 systemd: Started Session 3 of user root.
Oct 26 15:30:29 centos7 systemd-logind: New session 3 of user root.
……..
```

### 定制日志格式

### 自定义日志

如果你需要记录的是单机的日志，可以直接在rsyslog.conf中修改，然后添加相对应的内容即可，或者是以.conf为后缀的配置文件存放到/etc/rsyslog.d/下。
例如，添加ssh认证的alert级别的信息，可以执行如下操作：
```
echo "authpriv.alert  /var/log/auth-errors" > /etc/rsyslog.d/auth-errors.conf
systemctl restart rsyslog
logger -p authpriv.alert "test auth error"
将会在/var/log/auth-errors中看见如下
Oct 26 16:38:11 centos7 root: test auth error
```

#### 其他rsyslog.conf选项
rsyslog 能在内存被占满时将日志队列放到磁盘。磁盘辅助队列使日志的传输更可靠。如何配置rsyslog 的磁盘辅助队列：
```
$WorkDirectory /var/spool/rsyslog #暂存文件（spool）放置位置
$ActionQueueFileName fwdRule1     #暂存文件的唯一名字前缀
$ActionQueueMaxDiskSpace 1g#1gb空间限制（尽可能大）
$ActionQueueSaveOnShutdown on     #关机时保存日志到磁盘
$ActionQueueType LinkedLis t#异步运行
$ActionResumeRetryCount -1#如果主机宕机，不断重试
```

#### 小结
以上为日志的基础内容，了解以上内容之后我们可以进行下面的内容来深入配置日志和分析日志。

## 日志轮转

### Logrorate介绍
* 所有的日志文件都会随着时间的推移和访问次数的增加而迅速增长，所以需要对日志文件进行定期清理，避免不必要的磁盘空间浪费，也加快了管理员查看日志所用的时间。这时候logrotate就非常有存在的必要了，CentOS 7系统中默然安装logrotate并且利用logrotate设置了相关对rsyslog日志增长的设置。
* Logrotate的工作是由crontab来定时执行，定时执行文件在/etc/cron.daily/logrotate，实际上就是一个启动logrotate的脚本，由crontab每天启动。
* logrorate配置文件在/etc/logrotate.conf 

### Logrorate配置文件
```
[root@centos7 rsyslog.d]#  sed -e '/^#/d'  -e '/^$/d' /etc/logrotate.conf
weekly      #每周清理一次日志文件
rotate 4    #保存四个轮换日志
create      #清除旧日志的同时，创建新的空日志文件
dateext     #使用日期为后缀的回滚文件 
include /etc/logrotate.d  #包含/etc/logrotate.d目录下的所有配置文件
/var/log/wtmp {      #对/var/log/wtmp这个日志文件按照下面的设定日志回滚
    monthly                    #每月轮转一次
    create 0664 root utmp      #设置wtmp这个日志文件的权限，属主，属组
    minsize 1M                 #日志文件必须大于1M才会去轮换(回滚）
    rotate 1                   #保存一个轮换日志
}
……
```

### Logrorate.d的模块配置文件
```
[root@centos7 logrotate.d]# ls
chrony  glusterfs  iscsiuiolog  libvirtd.qemu  ppp     samba  syslog          yum
cups    httpd      libvirtd     numad          psacct  sssd   wpa_supplicant
```
>可以看到系统已经定义好了很多日志的轮询

### Logrorate.d自定义配置
有时候某些应用可能会产生大量的日志，但是logrorate没有默认的规则适应，所以我们需要自定义一些logrorate的自定义文件，以nginx为例：
```
#vim /etc/logrotate.d/nginx
/usr/local/nginx/logs/*.log {  //需要轮询日志路径
daily   //每天轮询   
rotate 5  //保留最多5次滚动的日志
missingok  //如果日志丢失，不报错继续滚动下一个日志
dateext    //使用日期作为命名格式
compress   //通过gzip压缩转储以后的日志
notifempty  //当日志为空时不进行滚动
sharedscripts
postrotate   //在截断转储以后需要执行的命令
[ -e /var/run/nginx.pid ] && kill -USR1 `cat /var/run/nginx.pid` ]
//nginx pid位置,定义在nginx.conf
endscript
}
//如果需要立刻截断可以使用如下命令：
/usr/sbin/logrotate -f /etc/logrotate.d/nginx
```

## 小结
日志轮询是必要的，日后的生产环境中，众多的日志不做轮询策略将导致分析困难，采集困难，更别提故障排除了。
