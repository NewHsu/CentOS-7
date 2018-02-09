#!/bin/sh
# chkconfig: 2345 99 01
# processname:IBMDB2
# description:db2 start
 
DB2_HOME="/home/db2inst1/sqllib" #°²װdb2Ó»§µÄqllib
DB2_OWNER="db2inst1"             #db2Ó»§Ã
 
case "$1" in
start )
echo -n "starting IBM db2"
su - $DB2_OWNER -c $DB2_HOME/adm/db2start
touch /var/lock/db2
echo "ok"
RETVAL=$?
;;

status)
ps -aux | grep db2sysc | grep -v grep && ping -c 2 35.1.1.246
RETVAL=$?
#if [ $RETVAL != 0  ];
#then
#clusvadm -r nfsserver
#fi
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

