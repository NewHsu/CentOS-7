# Ceph 对象网关-2

* 前章所说的都是在默认的情况下最经典的搭建方式，可是很多时候我们会面临众多的用户，这个对于CEPH的对象存储的压力还是非常大的，所以要做好提前规划。
* 规划中有几个要素如下：
    * 主机尽可能的大内存，否则levelDB和OSD会因为数据量的压力产生问题
    * 主机一定要配置SSD磁盘来做元数据的pool（.rgw.buckets.index）
    * 合适的sata盘组成数据资源池（.rgw.buckets的pool）
    * 一定要设置“rgw_override_bucket_index_max_shards”分片，否则单bucket数据多了，绝对是个灾难
    * 网络尽可能的万兆，并且要区分public和cluster
    * 规划好pg和pgp
    * 做好bucket的数量规划，例如每一个部门使用一个bucket？还是一个公司公用一个bucket，这个要好好划分，计算好量。

## 创建bucket
* 前面几个都可以处理，但是分出不同的bucket就需要新建了，所以需要熟悉s3调试工具。
1. 调试对象存储 s3cmd

        [root@ceph-1 ceph]# yum install s3cmd -y
2. 配置s3cmd进行S3接口测试

        [root@ceph-1 ceph]# s3cmd --configure
        Access Key: TCRBE7E5LXILLD01FH3O         <----输入access key
        Secret Key: 9TwNNYTS2sux1IOOlmeuCMerptBzdAEEMMTIqV2H    <----输入 Secret key
        Default Region [US]:           <----地区默认，可以不更改
        S3 Endpoint [s3.amazonaws.com]: 192.168.56.130     <----输入 IP
        DNS-style bucket+hostname:port template for accessing a bucket [%(bucket)s.s3.amazonaws.com]: 192.168.56.130:80/my-new-bucket    <----输入IP + bucket
        Encryption password:        <----回车默认
        Path to GPG program [/usr/bin/gpg]:     <----回车默认
        Use HTTPS protocol [Yes]: no      <----输入no，不使用https
        HTTP Proxy server name:    <----回车默认
        Test access with supplied credentials? [Y/n] y  <----输入Y
        Save settings? [y/N] y    <----输入 Y
        Configuration saved to '/root/.s3cfg'  

3. 帮助命令：s3cmd --help
4. 创建bucket
        
        [root@ceph-1 ceph]# s3cmd mb s3://my-test-bucket
        Bucket 's3://my-test-bucket/' created

        [root@ceph-1 ceph]# radosgw-admin buckets list
        [
            "my-test-bucket",
            "my-new-bucket"
        ]
5. 同样可以将该bucket对接到owncloud上，并且为单独的用户服务。其实也可以这样操作，在你前端的注册部分，如果用户注册合法通过，将调用API创建一个bucket出来，这样就可以了，省的后端在创建，还要去做对应。

## zone同步

* RGW很容易就解决了网盘问题，但是有没有想过类似网盘这类服务，是不是该考虑下高可靠和高可用呢？不可能读取和写入全部都集中在中心服务器吧，带宽和数据压力会直接压垮整个网盘或者类似使用RGW的服务。
* 还好RGW提供了异步方案，不仅可以容灾，还可以借助DNS和负载均衡，CDN等技术提供就近访问，分散流量并且实现客户的高速访问。
* 术语
        * Region：地区，它包含一个或多个域。一个包含多个 region 的集群必须指定一个主 region。（比如：中国，CN。北京，BJ）
        * Zone: 域、是一个或多个 Ceph 对象网关例程的逻辑分组。每个 region 有一个主域处理客户端请求。zone不可以跨集群。（Zone的划分一般以集群为单位，多个集群可以划分成zone1和zone2）
        * realm：代表一个唯一的命名空间，有一个或多个zonegroup组成。在同一个realm中的不同zonegroup只能同步元数据。在realm中有period的概念，表示zonegroup的配置状态，修改zonegroup，必须更新period。
>依据官方提示：你可以从二级域读取对象，但只能写入 region 内的主域。当前，网关程序不会禁止你写入二级域，但是，万万不要这样做！
* 规划
        1. 每个zone必须有一个Master Zone需要进行读写处理，所以必须选择一个设备精良，线路较好的zone来支撑。
        2. 其他的zone都智能进行读取，需要考虑客户群所在，实现就近读取。
>使用ceph-2模拟 bj-zone1，ceph-4模拟HRB-zone1来实现同步，实际生产实现，还需要考虑以上2个因素所在。

* 实施
* Ceph rgw需要使用多个pool来存储相关的配置及用户数据。删除默认创建的rgw，自行创建，利用命名格式管理和区分不同的zone，本例以（地区+zone）来做前缀。

        1. 删除原有rgw pool，参考前章内容。
        2. 在不同的集群创建新的pool，按规划的命名格式。 (一定是各自集群创建各自的！！！！！！)
                [root@ceph-1 ~]# ceph osd pool create bj.zone1.rgw.root 128 128
        3. 完成后如下所示：
                [root@ceph-1 ~]# ceph osd pool ls
                bj.zone1.rgw
                bj.zone1.rgw.root
                bj.zone1.rgw.control
                bj.zone1.rgw.gc
                bj.zone1.rgw.buckets
                bj.zone1.rgw.buckets.index
                bj.zone1.rgw.buckets.extra
                bj.zone1.log
                bj.zone1.intent-log
                bj.zone1.usage
                bj.zone1.users
                bj.zone1.users.email
                bj.zone1.users.swift
                bj.zone1.users.uid

