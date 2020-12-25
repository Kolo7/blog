# minIO扩容

### 单机扩容到集群
单机扩展到集群原单机还是得用原来的磁盘，另外的机器和原机器间数据独立存储，但是在同一客户端共享读写。  


### 原minIO环境
- 磁盘：4块
- 版本：minio/minio:2018-05-04T23:13:12Z
- 方式：单机

### 创建固定大小的卷
docker volume create -d local -o type=tmpfs -o device=tmpfs -o o=size=50m --name data1
docker volume create -d local -o type=tmpfs -o device=tmpfs -o o=size=50m --name data2
docker volume create -d local -o type=tmpfs -o device=tmpfs -o o=size=50m --name data3
docker volume create -d local -o type=tmpfs -o device=tmpfs -o o=size=50m --name data4

### docker模拟原环境
上述启动环境可以用docker模拟出来，便于做扩展验证。
```bash
docker run -d --name minio-server \
-e "MINIO_ACCESS_KEY=minio" -e "MINIO_SECRET_KEY=minio123" \
-v data1:/data1 -v data2:/data2 -v data3:/data3 -v data4:/data4 -v config:/root/.minio \
-p 9000:9000 \
minio/minio:RELEASE.2020-09-21T22-31-59Z \
server /data1 /data2 /data3 /data4 
```

```bash
docker run -d --name minio-server \
-e "MINIO_ACCESS_KEY=minio" -e "MINIO_SECRET_KEY=minio123" \
-v data1:/data1 -v data2:/data2 -v data3:/data3 -v data4:/data4 -v data5:/data5 -v data6:/data6 -v data7:/data7 -v data8:/data8 -v config:/root/.minio \
-p 9000:9000 \
minio/minio:RELEASE.2020-09-21T22-31-59Z \
server /data1 /data2 /data3 /data4 /data5 /data6 /data7 /data8
```

### 原机器启动命令
在原机器上通过docker启动minio，启动磁盘挂载到和原单机方式相同的位置。  
```bash
docker run --name minio1  \
-e "MINIO_ACCESS_KEY=minio" -e "MINIO_SECRET_KEY=minio123" \
-v data1:/data/11sdb1 -v data2:/data/11sdb2 -v data3:/data/11sdc1 -v data4:/data/11sdc2 -v config:/root/.minio \
-p 9000:9000 \
minio/minio:RELEASE.2020-09-21T22-31-59Z \
server http://localhost/data/11sd{b...c}{1...2} http://10.11.97.24/data{1...4}
```

### 扩展机器启动命令
集群方式启动（host2）   
在扩展的机器执行类似的命令，挂载位置可以修改实际扩展磁盘位置。
```bash
docker run --name minio2  \
-e "MINIO_ACCESS_KEY=minio" -e "MINIO_SECRET_KEY=minio123" \
-v data1:/data1 -v data2:/data2 -v data3:/data3 -v data4:/data4 -v config:/root/.minio \
-p 9000:9000 \
minio/minio:RELEASE.2020-09-21T22-31-59Z \
server http://10.11.99.137/data/11sd{b...c}{1...2} http://localhost/data{1...4}
```

### 用nginx做负载均衡
单机模式下单个文件将做纠错码处理，两份相同大小的明文切片，两份和明文切片大小相同的纠错码文件。  
两台机器间信息互通，但数据并不互通。根据写数据时使用的ip决定存储到哪个机器上。  
为了均匀的使用集群的磁盘，需要做负载均衡。  
用docker启动一个nginx。
```bash
docker run --name nginx \
-v /root/nginx.conf:/etc/nginx.conf:ro \
-p 9001:9001 \
nginx:1.19.2-alpine
```

### 注意事项
- 必须指定新的集合来扩展，无法通过单个指定的方式添加实例，就是得使用`http://host/data{1...4}`的方式。  
- 扩容添加的集合大小必须和原来的集合大小有一定关系，例如，如果原有是单机8磁盘，现在扩容，必须是添加原有的倍数：8，16，32...
- 使用docker会有一个坑点，server COMMAND中不能用自身的ip，要用回环地址，类似`localhost`。
- 单机磁盘间容量要差不多，多机之间没有这个必要，因为存储时需要负载均衡来控制数据往哪个单机存。


### 启用tls

```bash
docker run --name minio-tls \
-e "MINIO_ACCESS_KEY=minio" -e "MINIO_SECRET_KEY=minio123" \
-v data1:/data/11sdb1 -v data2:/data/11sdb2 -v data3:/data/11sdc1 -v data4:/data/11sdc2 -v /root/.minio:/root/.minio \
-p 9002:9000 \
minio/minio:RELEASE.2020-09-21T22-31-59Z \
server https://localhost/data/11sdb1 https://localhost/data/11sdb2 https://localhost/data/11sdc1 https://localhost/data/11sdc2
```

