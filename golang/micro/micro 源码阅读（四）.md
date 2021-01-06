# micro 源码阅读（四）

### 前言

前面用了三篇的量，分析了micro从启动到rpc协议监听远程调用。但真正的启动还没有完成，开始监听之后，就需要将service注册，暴露自己的服务。在这之前，有个细节没有搞定，所有的service还没把自己的handler方法配置到router中，所以先补上这一部分。

### registerHandler

```go
// hello.pb.micro.go
func RegisterHelloHandler(s server.Server, hdlr HelloHandler, opts ...server.HandlerOption) error {
	type hello interface {
		Call(ctx context.Context, in *Request, out *Response) error
		Stream(ctx context.Context, stream server.Stream) error
		PingPong(ctx context.Context, stream server.Stream) error
	}
	type Hello struct {
		hello
	}
	//h := &helloHandler{hdlr}
	return s.Handle(s.NewHandler(&hdlr, opts...))
}

```

这里代码有点绕，同时存在着`hello`、`helloHander` 、`Hello`、`HelloHandler`，这四个概念。首先要明确的是，重要的是`helloHander`和`HelloHandler`，大写的是接口，小写的是结构体，`helloHandler`结构体组合了一个`HelloHandler`接口的字段，虽然helloHander有Call、Stream、PingPong这些方法，但这三个方法的参数与helloHandler的不相同。所以helloHander与HelloHander的关系是适配器关系。

清楚了Handler的关系，这里又来套了一层Hello。之所以如此麻烦，由于Hander最终要被调用反射方法取得其Type、Value、Name，反射得到的Name就是最终的service.endpoint中的service的name。如果通过反射helloHandler获取得到的name就会是`helloHandler`，所以为了让反射得到的名字是不带Handler就套用一层结构体。

这里采用匿名字段替代了接口实现。
```go
typ := reflect.TypeOf(handler)
hdlr := reflect.ValueOf(handler)
name := reflect.Indirect(hdlr).Type().Name()

for m := 0; m < typ.NumMethod(); m++ {
    if e := extractEndpoint(typ.Method(m)); e != nil {
        e.Name = name + "." + e.Name
        for k, v := range options.Metadata[e.Name] {
            e.Metadata[k] = v
        }
        endpoints = append(endpoints, e)
    }
}

```

通过反射机制，取得service的所有方法（endpoint）的信息。

