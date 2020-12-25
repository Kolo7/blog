# docker-compose测试minIO集群

本文档以构建一个minio分布式集群为案例，介绍如何在docker-compose下模拟，单机、多容器的minio服务器环境。  

### 前置条件
在windows和macos桌面版docker在安装引擎的时候自带有docker-compose。

### 作用
一般使用docker是创建一个容器在本机上运行，而需要启动多个容器，以及设置多个容器之间启动关系时，就可以使用docker-compose。基于这个特点，可以将docker-compose的配置移植到docker swarm下，也就是真实的多机多容器的集群环境下。  
所以一般docker-compose可以作为没有正式环境条件之前的测试模拟。

### 配置文件
docker-compose需要一个默认名为`docker-compose.yaml`的文件。  
该文件的作用是设置多个容器的配置，以及这些容器的启动关系，还可以包含配置docker network、docker volume。  
该配置文件在docker swarm中也可以使用，就真实的变成了集群环境。

### 命令
docker-compose默认在当前路径下寻找叫做`docker-compose.yaml`的文件作为配置。  
`docker-compose pull`  
该命令会根据配置文件中的设置，准备好前置条件，例如pull镜像。  
`docker-compose up`  
根据配置依次启动容器。

### 注意事项
docker-compose一般不容易出问题，因为是单机多容器，不存在真实环境下的复杂情况。  
需要注意的是在配置的时候有些概念：  
配置中的sevices的name就可以作为主机名使用，因此`server http://minio{1...4}/data{1..2}`不用担心hostname的问题。在docker warm集群中也是一样，service的名字一样可以作为hostname配置使用。  
官方推荐的配置文件中存在nginx服务，实际是可以省略的，如果不需要的话直接删除有关配置。