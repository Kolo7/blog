# go开发配置

### go module

​	go module是go语言下比较流行的依赖管理工具，通过go module可以方便的依赖上自己想要的第三方包或者是本地私有库。

​	开启go module模式的方法就是设置环境变量：

```
GO111MODULE=on
```

##### mod指令

| 指令            | 作用                   |
| --------------- | ---------------------- |
| go get          | 拉指定库               |
| go mod download | 根据go.mod拉库         |
| go mod tidy     | 去掉go.mod无效库       |
| go mod graph    | 查看依赖               |
| go mod init     | 初始化生成需要的go.mod |
| go mod edit     |                        |
| go mod vendor   |                        |
| go mod verify   |                        |


##### goproxy

go module在国内使用需要配置代理，否则不能拉取到代码。

```
GOPROXY=https://goproxy.cn
```

##### GOPRIVATE

​	设置完代理之后，所有的依赖库都将会从代理服务器中拉去，如果想要用私有库，这样是无法拉取到代码的。所以通过设置GOPRIVATE来让部分域名的库越过代理。

```
GOPRIVATE=gitlab.com/*
```

​	这样设置GOPRIVATE环境变量后，所有以gitlab.com开头的模块将会不经过代理。

### Github

​	想面向Github开发还得有梯子，否则clone的速度让人难受，尤其是移动的网络，它使用DNS污染的方法导致了Github仓库访问慢。

​	如果有了梯子，需要设置git的全局配置。

​	第一步应该查看一下自己梯子socks5监听本地的那个端口，例如1080。

```
git config --global http.https://github.com.proxy socks5://127.0.0.1:1080
git config --global https.https://github.com.proxy=socks5://127.0.0.1:1080
```

配置好之后就可以享受到加速的效果了。