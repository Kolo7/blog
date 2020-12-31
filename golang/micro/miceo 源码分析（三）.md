# micro源码分析（三）

### 前言

前面两篇已经分析到服务端启动建立http链接并且取得了传输层的`net.Conn`。本节继续分析http方式的rpc通信的默认实现。

### httpTransportSocket

httpTransportSocket是代表着tcp和http连接的结构体，具有着服务器套接字的标准接口：Recv和Send。

这一块的你分析暂时靠后。

### rpc连接

