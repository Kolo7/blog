# micro源码分析（三）

### 前言

前面两篇已经分析到服务端启动建立http链接并且取得了传输层的`net.Conn`。本节继续分析http方式的rpc通信的默认实现。

### httpTransportSocket

httpTransportSocket是代表着tcp和http连接的结构体，具有着服务器套接字的标准接口：Recv和Send。它是真正套接字连接的封装。

__TODO__
这一块的实现分析暂时靠后。

#### socket池

为了复用http连接，在应用层面弄了一个socket池，以id为标识区分。

```go
type Socket struct {
    id string
    // closed
    closed chan bool
    // remote addr
    remote string
    // local addr
    local string
    // send chan
    send chan *transport.Message
    // recv chan
    recv chan *transport.Message
}
// 写入recv
func (s *Socket) Accept(m *transport.Message) error
// 从recv读
func (s *Socket) Recv(m *transport.Message) error
// 写入send
func (s *Socket) Send(m *transport.Message) error
// 从send读
func (s *Socket) Process(m *transport.Message) error 
```

这里列出最重要的四个方法，`Accept`和`Recv`一对，是对recv缓冲队列的读写，另外两个是对send缓冲队列的读写。而recv队列是为了从`net.socket`读信息而存在的，send则是向其中写信息。虽然只有一条`net.socket`连接，但是通过这样的rpc.socket池，就能够利用一条传输层套接字传输多个service的方法。

```go
if ok {
    // we're starting processing
    wg.Add(1)
    // pass the message to that existing socket
    if err := psock.Accept(&msg); err != nil {
    	// release the socket if there's an error
    	pool.Release(psock)
    }
    // done waiting
    wg.Done()
    // continue to the next message
    continue
}

```

对于一条已经存在的rpc连接，只需要不断的从`net.socket`中读出msg,塞入rpc.socket中。

经过这一步操作，同一个连接过来的消息就被按照id划分为了不同的存储来处理。

#### codec

codec是解码器，对传输过来的消息按文本原序列化协议来进行反序列化操作。

```go
DefaultContentType = "application/protobuf"

DefaultCodecs = map[string]codec.NewCodec{
    "application/grpc":         grpc.NewCodec,
    "application/grpc+json":    grpc.NewCodec,
    "application/grpc+proto":   grpc.NewCodec,
    "application/json":         json.NewCodec,
    "application/json-rpc":     jsonrpc.NewCodec,
    "application/protobuf":     proto.NewCodec,
    "application/proto-rpc":    protorpc.NewCodec,
    "application/octet-stream": raw.NewCodec,
}
```

这里默认使用的是protobuf协议，grpc同样也是使用该协议。

__TODO__
具体的编解码细节，留作后面分析。

