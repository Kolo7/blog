# minIO配置奇偶检验比例

minIO在多余四块磁盘的时候自动启用纠删码  
默认情况奇偶检验块和数据块比例是1:1  
奇偶检验块数量不能少于2  
只有四块磁盘时无法设置REDUCED_REDUNDANCY比例  

### 存储级别
minIO可以设置两个参数，它代表着两个存储级别，分别强调节省空间和安全性。  

##### STANDARD
默认情况下存储一个对象使用该标准级别；  
奇偶检验快大于等于2；  
奇偶校验块数量大于REDUCED_REDUNDANC。  

##### REDUCED_REDUNDANCY
默认情况下小于N/2；  
小于STANDARD；

### 配置方法
可以在启动minio server之前设置环境变量，也可以在使用api存储对象的时候设置。

### 示例

```
export MINIO_STORAGE_CLASS_STANDARD=EC:3
export MINIO_STORAGE_CLASS_RRS=EC:2
```

