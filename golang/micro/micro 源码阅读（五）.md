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
func (c *cmd) Init(opts ...Option) error {
    ...
	c.app.RunAndExitOnError()
	return nil
}
```
在Init方法中调用了将os.Args赋值给c.app的步骤。

### 服务注册

```go
if name := ctx.String("registry"); len(name) > 0 && (*c.opts.Registry).String() != name {
	r, ok := c.opts.Registries[name]
	if !ok {
		return fmt.Errorf("Registry %s not found", name)
	}
	*c.opts.Registry = r(registrySrv.WithClient(microClient))
	serverOpts = append(serverOpts, server.Registry(*c.opts.Registry))
	clientOpts = append(clientOpts, client.Registry(*c.opts.Registry))
	if err := (*c.opts.Selector).Init(selector.Registry(*c.opts.Registry)); err != nil {
		logger.Fatalf("Error configuring registry: %v", err)
	}
	clientOpts = append(clientOpts, client.Selector(*c.opts.Selector))
	if err := (*c.opts.Broker).Init(broker.Registry(*c.opts.Registry)); err != nil {
		logger.Fatalf("Error configuring broker: %v", err)
	}

```



