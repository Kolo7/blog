# goroutine pool工具库

### 工具名

grpool

### 地址

> github.com/gogf/gf

### 基本使用

```go
// utils.go
var GrPool  *grpool.Pool

func init()  {
	GrPool = grpool.New(conf.PackageParseConfig.GoroutinePoolSize)
	log.Info("start up goroutine pool[100]")
}

func Close() {
	GrPool.Close()
}
```

```go
// service.go

func service(){
    _ := utils.GrPool.Add(func(){
        ...
    })
    utils.GrPool.
}
```

### 高阶方法

- AddWithRecover()
- Jobs()
- Caps()
- Size()
- IsClosed()

