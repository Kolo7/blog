# http 过程分析

### 起步

```go
func httpServer(){
    listener, _ := net.Listen("tcp",":http")
    ...
}

```

### Transport

这里的协议选择tcp，addr填写的`:http`这等于是`0.0.0.0:80`的缩写。建立一个http连接，首先得有一个tcp连接，而学过网络编程应该知道tcp连接先得有一个监听一个端口号，如果有请求连接的话，将会建立起一个socket。
```go
func (lc *ListenConfig) Listen(ctx context.Context, network, address string) (Listener, error) {
    la := addrs.first(isIPv4)
    switch la := la.(type) {
    	case *TCPAddr:
    		l, err = sl.listenTCP(ctx, la)
    ...
}


func (sl *sysListener) listenTCP(ctx context.Context, laddr *TCPAddr) (*TCPListener, error) {  
    fd, err := internetSocket(ctx, sl.network, laddr, nil, syscall.SOCK_STREAM, 0, "listen", sl.ListenConfig.Control)
    ...
}

func internetSocket(ctx context.Context, net string, laddr, raddr sockaddr, sotype, proto int, mode string, ctrlFn func(string, string, syscall.RawConn) error) (fd *netFD, err error) 
    ...
    return socket(ctx, net, family, sotype, proto, ipv6only, laddr, raddr, ctrlFn)
}

func socket(ctx context.Context, net string, family, sotype, proto int, ipv6only bool, laddr, raddr sockaddr, ctrlFn func(string, string, syscall.RawConn) error) (fd *netFD, err error) {
	s, err := sysSocket(family, sotype, proto)
    ...
}
```

追踪到此，我就不再追踪至系统调用级别了，这不是一时半会能看完的。

TCP监听端口，而这里拿到的不是真正的socket，而是一个监听器，线程不会在tcp监听这里阻塞住。

```go
type Listener interface {
    Accept() (Conn, error)
    Close() error
    Addr() Addr
}
```

这里Accept方法即开启监听，等待客户端发起连接请求。当连接建立后，将会得到一个`net.Conn`。
```go
type Conn interface {   
    Read(b []byte) (n int, err error)
    Write(b []byte) (n int, err error)
    Close() error
    LocalAddr() Addr
    RemoteAddr() Addr
    SetDeadline(t time.Time) error
    SetReadDeadline(t time.Time) error
    SetWriteDeadline(t time.Time) error
}
```

一个net.Conn就代表着一个socket连接。拥有着非常底层的读写方法。

### http的等待
```go
func httpServer(){
    listener, _ := net.Listen("tcp",":http")
    _ = server.Serve(listener)
}
```

http接过从tcp连接得到的listener，这个时候还没有开始监听。而是在准备有关http服务器相关的资源。

```go
func (srv *Server) Serve(l net.Listener) error {
    for {  
        rw, err := l.Accept()
        ...
        tempDelay = 0
        c := srv.newConn(rw)
        c.setState(c.rwc, StateNew) // before Serve can return 
        go c.serve(connCtx)
    }
}
```
阻塞发生在l.Accept()，它等待着客户端发起tcp连接。当连接建立后，拿到的是代表着一条连接的`net.Conn`，随后http为`net.Conn`做了一层包装，`http.conn`多了很多参数，这就可以称得上是一个http连接了。每一个http单独起一个goroutine进行处理，可以想象的到，同一时间内如果有多个tcp客户端请求过来，极端情况真的可能出现部分请求失效，因为l.Accept()还没准备好。

```go
func (c *conn) serve(ctx context.Context) {
    ...
    c.r = &connReader{conn: c}
    c.bufr = newBufioReader(c.r)    
    c.bufw = newBufioWriterSize(checkConnErrorWriter{c}, 4<<10)
    ...
    w, err := c.readRequest(ctx)
    ...
    req := w.req
    ...
    serverHandler{c.server}.ServeHTTP(w, w.req)
    w.cancelCtx()
    ...
}
```

### req、resp的构建

这里Reader、Writer、bufioReader、bufioWriter都是套在conn.rwc上，也就是tcp的连接上。

```go
func (c *conn) readRequest(ctx context.Context) (w *response, err error) {
	...
    req, err := readRequest(c.bufr, keepHostHeader)
    ...
    w = &response{
        conn: c,
        req: req,
    	...
    }
}
```

c.readRequst(ctx)这里构造了，我们熟悉的`request`和`response`；

```go
// 来自response.cw.Write
func Write(){
    ...
    n, err = cw.res.conn.bufw.Write(p)
    ...
}
```

response持有`http.conn`，故而也持有向`net.Conn`的Writer。

### 文本分割

```go
func readRequest(b *bufio.Reader, deleteHostHeader bool) (req *Request, err error) {
    tp := newTextprotoReader(b)
    var s string
    // First line: GET /index.html HTTP/1.0
    if s, err = tp.ReadLine(); err != nil {
        return nil, err
    }
    ...
    req.Method, req.RequestURI, req.Proto, ok = parseRequestLine(s)
    ...
    // Subsequent lines: Key: value.
    mimeHeader, err := tp.ReadMIMEHeader()
    ...
    err = readTransfer(req, b)
    ...
}
```

上面分别读取了协议头、URI、header。并且在transfer中将body置为了`http.conn`

可以知道，只有在真正读取body的时候，才会调用从内存中读。

### handler

```go
// server.go
func (c conn)serve(ctx context.Contenxt){
    ...
    serverHandler{c.server}.ServeHTTP(w, w.req)
    ...
}

// server.go
func (sh serverHandler) ServeHTTP(rw ResponseWriter, req *Request) {
    handler := sh.srv.Handler
    if handler == nil {
        handler = DefaultServeMux
    }
    ...
    handler.ServeHTTP(rw, req)
}
```

Handler接口也就是我们真正处理http请求业务逻辑要实现的接口，但一般http服务不止一个handler，对应不同URI有不同的handler来处理。
因此在http中还有一个多路复用器，用于分发http请求。

```go
type ServeMux struct { 
    mu    sync.RWMutex
    m     map[string]muxEntry
    es    []muxEntry // slice of entries sorted from longest to shortest.
    hosts bool       // whether any patterns contain hostnames
}

type muxEntry struct {
    h       Handler
    pattern string
}

func (mux *ServeMux) Handler(r *Request) (h Handler, pattern string) 
func (mux *ServeMux) ServeHTTP(w ResponseWriter, r *Request)
func (mux *ServeMux) Handle(pattern string, handler Handler) 
func (mux *ServeMux) HandleFunc(pattern string, handler func(ResponseWriter, *Request))
```

```go
func (mux *ServeMux) HandleFunc(pattern string, handler func(ResponseWriter, *Request)){
    mux.Handle(pattern, HandlerFunc(handler))
}

func (mux *ServeMux) Handle(pattern string, handler Handler){
    ...
    e := muxEntry{h: handler, pattern: pattern}
	mux.m[pattern] = e
	if pattern[len(pattern)-1] == '/' {
		mux.es = appendSorted(mux.es, e)
	}
    ...
}
// 重命名了这类handler函数
type HandlerFunc func(ResponseWriter, *Request)
// 调用真实的函数
func (f HandlerFunc) ServeHTTP(w ResponseWriter, r *Request) {
	f(w, r)
}
```

多路复用器的代码很简单，mu保证分发的时候是同步的。muxEntry就是处理器与对应URI的映射。
调用HandleFunc或者是Handle方法向多路复用器注册Handler，httpServer将会在收到http请求的时候调用`HttpServe`分发请求，多路复用器依照URI找到映射的handler，并且执行。

注册的handler函数，必须是实现了HandlerFunc接口，也就是`handler func(ResponseWriter, *Request)`。

```go
func (mux *ServeMux) ServeHTTP(w ResponseWriter, r *Request){
    ...
    h, _ := mux.Handler(r)
    h.ServeHTTP(w, r)
}
```

未完，还有很多细节。