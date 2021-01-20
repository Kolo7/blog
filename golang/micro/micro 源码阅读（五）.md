# micro 源码阅读（五）

### 导言

这一篇源码重点分析一下默认配置和配置读取。go-micro支持cmd、环境变量配置一些参数。出于带着目的去分析的方法。这里就追踪服务注册怎么通过命令行改变注册方式。

### etcd方式服务注册


```sh
go run main.go plugin.go --registry=etcd --registry_address=etcd1.foo.com:2379,etcd2.foo.com:2379,etcd3.foo.com:2379
```

这里在启动的时候指定两个重要的参数分别是`--registry`、`--registry_address`，分别指定了注册的方式和注册的地址。

这里希望通过阅读源码弄明白micro支持哪些可配置参数，又怎么去实现自己的注册方式，比如通过redis做服务注册行不行。micro的文档比较少

### config

#### 默认配置

```go
// config/cmd/cmd.go
var (
    DefaultCmd = newCmd()
    ...
    DefaultRegistries = map[string]func(...registry.Option) registry.Registry{
        "service": regSrv.NewRegistry,
        "etcd":    etcd.NewRegistry,
        "mdns":    mdns.NewRegistry,
        "memory":  rmem.NewRegistry,
    }
    ...
)

func newCmd(opts ...Option) Cmd {
    options := Options{
        ...
        Registry:  &registry.DefaultRegistry,
        ...
        Registries: DefaultRegistries,
        ...
    }
    for _, o := range opts {
		o(&options)
	}
    cmd := new(cmd)
    cmd.opts = options
}

```

options在初始化时设置了一些默认的实现，例如这里的服务注册，默认的实现是mdns。同时options也初始化了其他的实现方式的映射，以供通过命令行或是环境变量去选用，例如这里的Registries，代表了go-micro默认支持了service、etcd、mdns、memory这些服务注册方式。

#### cli工具

```go
DefaultFlags = []cli.Flag{
    ...
    &cli.StringFlag{
	Name:    "registry",
	EnvVars: []string{"MICRO_REGISTRY"},
	Usage:   "Registry for discovery. etcd, mdns",
    },
    &cli.StringFlag{
	Name:    "registry_address",
	EnvVars: []string{"MICRO_REGISTRY_ADDRESS"},
	Usage:   "Comma-separated list of registry addresses",
    },
    &cli.IntFlag{
	Name:    "register_ttl",
	EnvVars: []string{"MICRO_REGISTER_TTL"},
	Value:   60,
	Usage:   "Register TTL in seconds",
    },
    ...
}
...

cmd := new(cmd)
cmd.opts = options
cmd.app = cli.NewApp()
cmd.app.Name = cmd.opts.Name
cmd.app.Version = cmd.opts.Version
cmd.app.Usage = cmd.opts.Description
cmd.app.Before = cmd.Before
cmd.app.Flags = DefaultFlags
cmd.app.Action = func(c *cli.Context) error {
	return nil
}
```

这里的`cli.NewApp()`是用的第三方库。

> github.com/micro/cli/v2

工具用起来还是很简单的，要配置的重要属性主要是Flags和Before。Flag必须是cli.Flag数组。以上面截取的部分Flags来看，Name代表着启动参数，如：`--registry`；EnvVars代表着读取环境变量的key；Value是默认值。而Before配置的函数将会在执行子命令前被调用，可以认为就是在这个函数中完成从cmd参数到具体配置项的赋值就行。

```go
func (c *cmd)Before() error {
    var serverOpts []server.Option
    var clientOpts []client.Option
    ...
    if ttl := time.Duration(ctx.Int("register_ttl")); ttl >= 0 {
        serverOpts = append(serverOpts, server.RegisterTTL(ttl*time.Second))
    }
}

func (c *cmd) Init(opts ...Option) error {
    ...
    // micro.cli 工具的默认进入方法
    c.app.RunAndExitOnError()
    return nil
}
```
在Init方法中调用了将os.Args赋值给c.app的步骤。

根据这前面的追踪就能知道go-micro究竟支持多少种启动配置参数，以及是什么时机读取配置参数的。
### 服务注册

在启动的过程中同时完成了服务注册的流程，并且会维持一个goroutine在ttl间隔后重复注册操作。

服务注册线程将会一直重试，保持一个间隔时间的频率。下面的代码可以清楚的看到调用注册器和退避策略。
```go
func (s *rpcServer) Start() error {
    go func() {
        t := new(time.Ticker)
        // only process if it exists
        if s.opts.RegisterInterval > time.Duration(0) {
    	    // new ticker
    	    t = time.NewTicker(s.opts.RegisterInterval)
    }
    Loop:
        err := s.Register()
    }
}

func (s *rpcServer) Register() error {
    ...
    regFunc := func(service *registry.Service) error {
        // create registry options
        rOpts := []registry.RegisterOption{registry.RegisterTTL(config.RegisterTTL)}
        var regErr error
        for i := 0; i < 3; i++ {
            // attempt to register
            if err := config.Registry.Register(service, rOpts...); err != nil {
                // set the error
               regErr = err
               // backoff then retry
               time.Sleep(backoff.Do(i + 1))
               continue
            }
            // success so nil error
            regErr = nil
            break
        }
        return regErr
    }
    ...
    err := regFunc(rsvc)
    ...
}
```

需要注册信息都包含在registry.Service当中。下面的展示的就是组装Service。忽略了很多中间代码，但是主要脉络就是拼装要注册的信息，例如：addr、Metadata、endpoints。后面还有一些跟发布订阅相关的逻辑也是在这个函数中实现的，暂时不做分析。

```go
func Register() error {
    node := &registry.Node{
        Id:       config.Name + "-" + config.Id,
        Address:  addr,
        Metadata: md,
    }
    ...
    endpoints := make([]*registry.Endpoint, 0, len(handlerList)+len(subscriberList))
    for _, n := range handlerList {
        endpoints = append(endpoints, s.handlers[n].Endpoints()...)
    }
    for _, e := range subscriberList {
        endpoints = append(endpoints, e.Endpoints()...)
    }
    service := &registry.Service{
        Name:      config.Name,
        Version:   config.Version,
        Nodes:     []*registry.Node{node},
    	Endpoints: endpoints,
    }
}
```







