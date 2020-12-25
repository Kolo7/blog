# minIO启用TLS

### 准备
数字证书和私钥  
- public.crt
- private.key
##### 自签名证书
没有证书，可以自己签名一个，生成工具如下地址：  
[generate_cert.go](https://golang.org/src/crypto/tls/generate_cert.go?m=text  )

##### 证书放这
数字证书默认位置在`/root/.minio/certs`

### 启动命令
如果是用`http://localhost/data1`，这样的命令启动的，那么要切换成`https://localhost/data1`

### 注意事项
如果是普通集群方式，需要使用负载均衡工具，如果是nginx，那么证书应该配置到nginx上。