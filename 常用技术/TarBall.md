# Tar包管理
* 在Linux系统中除了实用RPM软件包进行安装以后还实用源码包进行安装，也就是所谓的tar包安装，实际上源码包安装就是将源码压缩到一个tar包内，我们可以通过解压tar包，来进行源码安装，同时也可以通过实用tar的压缩方式将文件压缩进行传输或归档
* 生产环境中最长用的场景并不是使用tar包安装软件，而是将服务器上所需的数据进行压缩打包下载到本地，故而，这个技能还是要掌握的，要不然拿个数据下来都不能，学了一堆的基础也就是白学了。

#### Tar解压和压缩
* 很早以前我们需要解压缩和压缩tar包，要制定解压和压缩的后缀格式，例如，gzip和bz2对应不通的参数，现在tar已经非常智能化了，你只要输入解压的参数，tar就会自动识别匹配参数。
###### 解压缩

    [root@localhost ~]# tar xvf loganalyzer-3.6.5.tar.gz –C /tmp
参数解释：
v示信息
f 指定文件
x 解压
C 指定路径

###### 归档
tar cvf 自定义名称.tar.gz(或自定义名称.bz2)  /sources   （文件夹或者文件）

    [root@localhost tmp]# tar cvf test.tar.gz ./yum_save_tx.2015-10-3*
    所有yum文件进行打包
#### 源码安装
源码编译安装，需要有GCC的支持，所以还请通过`yum –y install gcc`安装gcc。


安装nginx需要有pcre的支持，本文只为说明源码安装步骤，所以pcre就直接使用yum安装了。
>yum install pcre-devel zlib-devel openssl-devel
###### 1.下载nginx源码包
    [root@localhost tmp]# wget http://nginx.org/download/nginx-1.6.0.tar.gz
###### 2.解压nginx
    [root@localhost tmp]# tar xvf nginx-1.6.0.tar.gz
###### 3.进入目录
    [root@localhost tmp]# cd nginx-1.6.0/
###### 4.Configure
    [root@localhost nginx-1.6.0]# ./configure --prefix=/usr/local/pcre
    --prefix参数指定安装目录，还有更多参数，可以参看./configure说明
###### 5.Make
    [root@localhost nginx-1.6.0]#make
###### 6.Make install
    [root@localhost nginx-1.6.0]#make install
###### 7.启动nginx
    [root@localhost nginx-1.6.0]# cd /usr/local/nginx/sbin/
    [root@localhost sbin]# ./nginx
###### 测试
![png](./images/TarBall/1.png)
>以上只是介绍tar的解压和压缩以及源码安装的三步，实际源码安装可能比这个复杂，./configure的时候需要更多参数的支撑和依赖的软件定位，所以还要多度./configure的帮助和看提示信息。
>Tar包的解压和压缩也有很多方式，这里介绍的只是最最最基础的压缩和解压.
>>复杂的在这里！！！！！
###### 实例1：将整个 /etc 目录下的文件全部打包成为 /tmp/etc.tar
    [root@linux ~]# tar -cvf /tmp/etc.tar /etc　　　　<==仅打包，不压缩！
    [root@linux ~]# tar -zcvf /tmp/etc.tar.gz /etc　　<==打包后，以 gzip 压缩
    [root@linux ~]# tar -jcvf /tmp/etc.tar.bz2 /etc　　<==打包后，以 bzip2 压缩
###### 实例2：查看test.tar.gz下有哪些文件
    [root@localhost tmp]# tar tvf test.tar.gz
###### 实例3：只解压压缩包内的某一个文件
    [root@localhost tmp]# tar xvf test.tar.gz ./yum_save_tx.2015-10-31.21-41.a2YHFA.yumtx
###### 实例4：备份/home,/etc, 但是不备份 /home/db2inst1
    [root@localhost tmp]#tar –exclude /home/db2inst1 –cvf mytar.tar.gz /home/* /etc/
###### 实例5：增量备份
  执行完整备份

    [root@localhost tmp]# tar -g snapshot -cvf backup.tar.gz tartest
    tar: tartest: Directory is new
    tartest/
    tartest/file1
    tartest/file10
    tartest/file2
    tartest/file3
    tartest/file4
    tartest/file5
    tartest/file6
    tartest/file7
    tartest/file8
    tartest/file9
    [root@localhost tmp]# cd tartest/
    [root@localhost tartest]# touch file{11..20}
    [root@localhost tartest]# cd ..
执行增量备份，这里注意file1到file10将不在备份

    [root@localhost tmp]# tar -g snapshot -cvf backup1.tar.gz tartest
    tartest/
    tartest/file11
    tartest/file12
    tartest/file13
    tartest/file14
    tartest/file15
    tartest/file16
    tartest/file17
    tartest/file18
    tartest/file19
    tartest/file20
`但是还原的时候需要一个一个的还原了`
## 总结
本文重点讲解tar的压缩解压，无论如何都要搞定这些内容，并且tar也是生产常用内容。
