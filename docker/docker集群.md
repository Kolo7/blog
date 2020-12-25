# docker swarm配置minIO集群

docker warm是一个docker的集群模式，作用是，让多台计算机形成docker集群，能够做到在多机器中快速部署多容器，实际用途可以作为：服务集群、微服务部署等。  

### 概念
#### node
swrm模式中每个真实的运行着docker-engine的机器都是一个node。node分为master和其他节点，master节点只有一个，其他节点通过主动加入的方式和master组成一个集群。集群中node的节点不限。  

#### service
node是可以认为是能执行service的机器，每一个service都是一个待执行的任务，它将会被随机分配或是条件约束部署到node上执行，在机器上执行的是service是以容器来执行的。service可以复制好几份相同的，随机分配到集群中，来启动好多容器执行，基于这一点可以做模拟压力测试。

#### stack
通过`docker service`一次只能执行一个service，而stack就是多个service的集合，不仅可以同时启动多个service，还可以指定service之间的启动关系。  

#### network
network是docker跨容器互联的工具，通过指定多个容器加入同一个network就能实现容器间的互联。  
network提供有五种网络驱动模式  
1. `bridge`  
默认的网络驱动方式，容器之间类似于局域网互联的关系。  
2. `host`  
移除容器和 Docker 宿主机之间的网络隔离，并直接使用主机的网络。  
3. `overlay`  
一般用在集群服务方式，将多个进程连接在一起，容器之间类似于进程间通信。(swarm模式下推荐使用)  
4. `macvlan`  
会为容器分配mac地址，docker会通过mac地址将流量路由到容器内。这应该是很少用的一种。
5. `none`  
这个禁用联网。

#### volumes
一般在使用docker创建一个简单的容器的时候也会用到-v参数来指定容器内路径挂载到真实主机的路径，volumes工具有更集中的管理方式，更易于备份和迁移。  
在docker-compose.yaml文件中的一种配置方式将会自动的指定一个真实主机地址挂载。

### 集群建立流程
#### 前提条件
swarm模式需要linux下的docker-engine才可以开启，windows和mac下无法创建或是加入该模式。  
多机之间docker的版本最好是差不多，如果出现不能加入的情况，需要检查版本是否兼容。  
主机的2377端口需要保持空闲。

#### 检查info
`docker info`  
使用集群模式之前需要检查是否开启swarm模式，`Swarm: active`代表开启了。

#### 启动模式
如果没有开启swarm需要执行一下命令。  
`docker swarm init --advertise-addr <MANAGER-IP>`  

#### 加入swarm
启动swarm之后会有一条命令信息打印在控制台，在同网络下执行该命令信息可以加入到本manager创建的集群中。  
如果忘记了join token，可以执行下面命令重新获取token。  
`docker swarm join-token worker`

#### 查看节点状态
`docker node ls`   

#### 创建docker secret
secret是为容器内服务创建键值对，可以作为启动时的环境变量。在minIO中作为客户端的登录账号和密码  
`echo "AKIAIOSFODNN7EXAMPLE" | docker secret create access_key -`  
`echo "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" | docker secret create secret_key -`


### 集群使用
如果是使用docker-compose.yaml文件创建分发service将会比较简单。最好是经过了本地docker-compose的测试。  
当docker-compose.yaml没有问题，可以进行service的创建分发。

#### 部署
直接使用docker-compose.yaml文件部署  
`docker stack deploy --compose-file=docker-compose.yaml minio_stack`

#### 更新
如果某个service挂了，可以重启更新  
`docker service update [serivce-name]`

#### 删除
先删除service  
`docker stack rm minio_stack`  
再删除volumes  
`docker volume ls`  
`docker volume rm volume_name `

#### 指定node
有时候需要将service指定运行到固定的node，这需要在配置文件中配合指定label  

1. 为node添加label  
docker node update --label-add role=labelName hostname1  
2. 查看标签  
docker node inspect hostname1  
3. 删除标签（需要时再执行）  
docker node update --label-rm role hostname1  
4. stack方式服务部署条件约束  
```
         deploy:
           mode: global
           placement:
              constraints:                      # 添加条件约束
                - node.labels.role==labelName
```
5. service方式服务部署条件约束
```
--constraint 'node.labels.role == labelName'
```

#### 常见问题和解决方法
通过该文件启动service后，可以检查service的状态和名字  
`docker service ls`  

指定名字查看详细信息  
`docker service inspect --pretty [service-name]`  

可以查询service真实运行在哪个节点，失败还是成功，启动了几次等信息  
`docker service ps [service-name]`  

如果出错，还可以指定`--no-trunc`看service的详细信息  
`docker service ps --no-trunc minio_stack_minio1`  

以上命令足以定位到错误发生的node、容器名字、容器状态，进入错误发生的地方打印日志查看容器启动信息  
`docker log [CONTAINER ID]`  

定位好问题才能够解决问题，一般错误可以通过修改配置文件来解决。  

