# minioClinet(mc)工具

### 添加云存储服务
```bash
# mc config host add <ALIAS> <YOUR-S3-ENDPOINT> <YOUR-ACCESS-KEY> <YOUR-SECRET-KEY> [--api API-SIGNATURE]
mc config host add minio1 http://localhost:9000 accesskey secretkey --api s3v4
```

### 常见小操作
以下命令中minio1为上命令所配置s3server。

##### 查看配置
> mc config host ls

##### 查看服务存储桶
>mc ls minio1

