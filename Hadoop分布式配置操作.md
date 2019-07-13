# Hadoop分布式配置操作

### 前提条件

在linux下，我的是centos7

装好了jdk1.8

装好了ssh

### 配置网络

所有节点主机都需要。

Hosts文件

```
192.168.1.116  Master
192.168.1.181  Slave1
192.168.1.199  Slave2
```
### 配置jdk

所有节点主机都需要。

配置java环境变量

```bash
vim /etc/profile

export JAVA_HOME=/usr/local/jdk1.8
export PATH=$JAVA_HOME/bin:$PATH
export CLASSPATH=:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar

source /etc/profile
```
### 配置Hadoop专用的用户组和用户

所有节点主机都需要。

```bash
sudo groupadd hadoop

useradd -s /bin/bash -d /home/kolo -m kolo -g hadoop -G root

sudo passwd kolo

su kolo
```
### 配置免密ssh登录

所有节点主机都需要。

需要作为Master的节点可以无密码ssh连接全部的Slave节点

```bash
ssh localhost

cd ~/.ssh

rm ./id_rsa* 

ssh-keygen -t rsa 

cat ./id_rsa.pub >> ./authorized_keys

scp ~/.ssh/id_rsa.pub kolo@Hadoop1:/home/kolo/
scp ~/.ssh/id_rsa.pub kolo@Hadoop2:/home/kolo/

cat ~/id_rsa.pub >> ~/.ssh/authorized_keys

rm ~/id_rsa.pub
```
### 修改权限

要把kolo加入到sudoers文件中。

修改kolo用户权限

```bash
sudo chown -R kolo:hadoop ./hadoop-2.7.7
```

### hadoop环境变量

这里配置的情况使得只有kolo用户可以使用该环境变量。

配置hadoop环境变量

```
vim ~/.bashrc
export PATH=$PATH:/usr/local/hadoop/hadoop-2.7.7/bin:/usr/local/hadoop/hadoop-2.7.7/sbin
source ~/.bashrc
```

---------------
### hadoop配置和启动

下载好hadoop，放到/usr/local/hadoop下

这样权限就是kolo可以写入的。修改hadoop下的etc/hadoop/中的配置文件

core-site.xml文件

```xml
<configuration>
        <property>
                <name>fs.defaultFS</name>
                <value>hdfs://Hadoop1:9000</value>
        </property>
        <property>
                <name>hadoop.tmp.dir</name>
                <value>file:/usr/local/hadoop/hadoop-2.7.7/tmp</value>
                <description>Abase for other temporary directories.</description>
        </property>
</configuration>
```
---------
 hdfs-site.xml文件

 ```xml
<configuration>
        <property>
                <name>dfs.namenode.secondary.http-address</name>
                <value>Master:50090</value>
        </property>
        <property>
                <name>dfs.replication</name>
                <value>2</value>
        </property>
        <property>
                <name>dfs.namenode.name.dir</name>
                <value>file:/usr/local/hadoop/hadoop-2.7.7/tmp/dfs/name</value>
        </property>
        <property>
                <name>dfs.datanode.data.dir</name>
                <value>file:/usr/local/hadoop/hadoop-2.7.7/tmp/dfs/data</value>
        </property>
</configuration>
 ```
---------------
mapred-site.xml

```xml
<configuration>
        <property>
                <name>mapreduce.framework.name</name>
                <value>yarn</value>
        </property>
        <property>
                <name>mapreduce.jobhistory.address</name>
                <value>Master:10020</value>
        </property>
        <property>
                <name>mapreduce.jobhistory.webapp.address</name>
                <value>Master:19888</value>
        </property>
</configuration>
```

yarn-site.xml

```xml
<configuration>
        <property>
                <name>yarn.resourcemanager.hostname</name>
                <value>Master</value>
        </property>
        <property>
                <name>yarn.nodemanager.aux-services</name>
                <value>mapreduce_shuffle</value>
        </property>
</configuration>
```

slaves

要在slaves文件中加入datanode主机的名字

向各节点复制Hadoop

tar -zcvf /etc/local/hadoop/hadoop-2.7.7.tar.gz hadoop

```bash
scp /usr/local/hadoop/hadoop-2.7.7.tar.gz kolo@Slave1:/usr/local/hadoop
scp /usr/local/hadoop/hadoop-2.7.7.tar.gz kolo@Slave2:/usr/local/hadoop
```

在Master节点初始化NameNode节点

```bash
hdfs namenode -format

```

### 设置防火墙

一定要关闭防火墙，并且设置开启不自动启动

```bash
#查看防火墙
firewall-cmd --state						
#关闭防火墙
systemctl stop firewalld.service
#禁止防火墙启动
systemctl disable firewalld.service 
```

启动hadoop

```bash
start-dfs.sh
start-yarn.sh
mr-jobhistory-daemon.sh start historyserver
```

关闭hadoop

```bash
stop-yarn.sh
stop-dfs.sh
mr-jobhistory-daemon.sh stop historyserver
```







