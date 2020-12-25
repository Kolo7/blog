# Jenkins 

### 作用



### 安装

##### windows下

官网下载，得到`jenkins.war`文件；

>  java -jar jenkins.war

##### linux下



### 基础以及插件配置

完成启动之后，浏览器搜索如下，如果启动失败，可能是端口冲突，需要检查一下8080端口在启动jenkins之前是不是空闲。

> localhost:8080

进入网站后，需要安装大量插件，选择“Install suggest Plugins”，这个过程需要联网下载很多东西，因此会要等待一下。

### 介绍一下重要的插件

##### Locale plugin & Localization Support Plugin & Localization: Chinese (Simplified)

解决语言问题，但是不是很好用，部分汉化了，并且还有时候失灵，失灵的时候就重启。



##### Publish Over SSH

项目构建完成后，为了体现持续部署的观念，有可能需要把打出来的包放到远程机器上某个目录下，使用这个插件可以通过SSH方式把包发过去。

如果希望包发过去之后，完成一些清理原包和终止原程序的操作，需要事先做好一些脚本，然后在该插件中，用shell命令启动脚本，完成需要的工作。

### 执行脚本

如果希望构建完成之后，包能够从jenkins的workspace转移到指定的目录，并且运行起来的话，需要指定执行脚本，而脚本需要提前写好：

```bash
#export BUILD_ID=dontKillMe这一句很重要，这样指定了，项目启动之后才不会被Jenkins杀掉。
export BUILD_ID=dontKillMe

#指定最后编译好的jar存放的位置 即是发布目录
www_path=/root/work/target
#Jenkins中编译好的jar位置  即是编译目录
jar_path=/var/lib/jenkins/workspace/pressure-test-tool/target
#Jenkins中编译好的jar名称 
jar_name=sdkserver-0.0.1-SNAPSHOT.jar
pidfile=/root/work/demo-test.pid

#获取运行编译好的进程ID，便于我们在重新部署项目的时候先杀掉以前的进程
pid=$(cat ${pidfile})

#进入指定的编译好的jar的位置
cd  ${jar_path}
#将编译好的jar复制到最后指定的位置
cp  ${jar_path}/${jar_name} ${www_path}
#进入最后指定存放jar的位置
cd  ${www_path}

if ${pid}; then  #判断进程号id是否存在
    echo "pid is null"
else
    kill -9 ${pid}  #杀掉以前可能启动的项目进程
fi    #if结束标志

#启动jar，指定SpringBoot的profiles为dev,后台启动
#java -jar -Dspring.profiles.active=dev ${jar_name} &
#启动jar，后台执行
java -jar ${jar_name} &

#将进程ID存入到demo-test.pid文件中
echo $! > ${pidfile}
```

```bash
#!/bin/bash 

#export BUILD_ID=dontKillMe这一句很重要，这样指定了，项目启动之后才不会被Jenkins杀掉。
export BUILD_ID=dontKillMe

#指定最后编译好的jar存放的位置
target_path=/root/pressure-test-tool/target
#Jenkins中编译好的jar位置
jenkins_path=/var/lib/jenkins/workspace/pressure-test-tool/target

# 停止原来的进程
PID=$(ps -ef | grep sdkserver-0.0.1-SNAPSHOT.jar | grep -v grep | awk '{ print $2 }')
if [ -z "$PID" ]
then
    echo Application is already stopped
else
    echo kill $PID
    kill $PID
fi

#将编译好的jar复制到最后指定的位置
cp  ${jenkins_path}/sdkserver-0.0.1-SNAPSHOT.jar ${target_path}


#启动jar，指定SpringBoot的profiles为test,后台启动
nohup java -jar ${target_path}/sdkserver-0.0.1-SNAPSHOT.jar >> /root/work/output.log 2>&1 &
```

##### 配置webhook

