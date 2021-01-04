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

### new socket

如果是有新id的socket被创建，那么在做rpc通信之前，还要做很多的准备工作。

```go
psock.SetLocal(sock.Local())
psock.SetRemote(sock.Remote())

ctx := metadata.NewContext(context.Background(), hdr)
...
ctx, cancel = context.WithTimeout(ctx, time.Duration(n))
// 读取信息到psock.recv
psock.Accept(&msg)
...
// setup old protocol
cf := setupProtocol(&msg)
...
if cf, err = s.newCodec(ct)
...
// 设置解码器
rcodec := newRpcCodec(&msg, psock, cf)
```

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

### request&response

构造了rpc请求和回应，携带者将要交给具体service方法处理的全部信息。

```go
request := &rpcRequest{
	service:     getHeader("Micro-Service", msg.Header),
	method:      getHeader("Micro-Method", msg.Header),
	endpoint:    getHeader("Micro-Endpoint", msg.Header),
	contentType: ct,
	codec:       rcodec,
	header:      msg.Header,
	body:        msg.Body,
	socket:      psock,
	stream:      stream,
}

response := &rpcResponse{
	header: make(map[string]string),
	socket: psock,
	codec:  rcodec,
}
```

### router

```go
r := Router(s.router)
if s.opts.Router != nil {
	// create a wrapped function
	handler := func(ctx context.Context, req Request, rsp interface{}) error {
		return s.opts.Router.ServeRequest(ctx, req, rsp.(Response))
	}
	// execute the wrapper for it
	for i := len(s.opts.HdlrWrappers); i > 0; i-- {
		handler = s.opts.HdlrWrappers[i-1](handler)
	}
	// set the router
	r = rpcRouter{h: handler}
}
```

对router的处理主要是针对server.opt.Router以及server.opt.HdlrWrappers，将配置的router和包装器全部套上。

### 两个goroutine

准备好前置工作后，为每一个psock启动两个独立的goroutine循环处理。

```go
go func(id string, psock *socket.Socket) {
    ...
	for {
		// get the message from our internal handler/stream
		m := new(transport.Message)
		if err := psock.Process(m); err != nil {
			return
		}
		// send the message back over the socket
		if err := sock.Send(m); err != nil {
			return
		}
	}
}(id, psock)
```

这个goroutine的作用就是处理关闭时的一些善后工作，以及最重要的从psock不断地读取消息，经过`net.socket`发送到remote。

```go
go func(id string, psock *socket.Socket) {
	...
	// serve the actual request using the request router
	if serveRequestError := r.ServeRequest(ctx, request, response); serveRequestError != nil {
		...
	}
}(id, psock)
```
这里最重要的是将构建好的请求和响应交给到router，经过多层包装器的处理，将会走到rpc_router.router。这里也可以得知，每一个psocket将会有一个router来处理请求。

#### 读取header

在交给真正的逻辑方法处理request,response之前，有router调用codec的解码方法，读取了header和body。
```go
func (router *router) ServeRequest(ctx context.Context, r Request, rsp Response) error {
    // service:服务名,mtype:方法名,req:只包含了header信息,argv是方法参数的reflect.Value值
    service, mtype, req, argv, replyv, keepReading, err := router.readRequest(r)
    ...
}

func (router *router) readRequest(r Request) (service *service, mtype *methodType, req *request, argv, replyv reflect.Value, keepReading bool, err error) {
    cc := r.Codec()
    service, mtype, req, keepReading, err = router.readHeader(cc)
    ...
    if err = cc.ReadBody(argv.Interface()); err != nil {
		return
    }
    if !mtype.stream {
		replyv = reflect.New(mtype.ReplyType.Elem())
	}
}

func (router *router) readHeader(cc codec.Reader) (service *service, mtype *methodType, req *request, keepReading bool, err error) {
    err = cc.ReadHeader(msg, msg.Type)
    ...
    serviceMethod := strings.Split(req.msg.Endpoint, ".")
    ...
    service = router.serviceMap[serviceMethod[0]]
    ...
    mtype = service.method[serviceMethod[1]]
}
```
