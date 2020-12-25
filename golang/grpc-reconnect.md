# grpc-reconnect

client在请求拨号期间会进行多次尝试，默认情况是会一直请求的。通过设置拨号参数可以改变重试的频率。这个也叫做退避策略。

### 入门操作
```golang
opt := grpc.WithConnectParams(
    grpc.ConnectParams(
        Backoff: backoff.Config(
            BaseDelay:  1.0 * time.Second,
            Multiplier: 1.6,
            Jitter:     0.2,
            MaxDelay:   120 * time.Second,
        ),
        MinConnectTimeout: 10 * time.Second,
    )
)
grpc.Dial("localhost:1234",
        opt,
        grpc.WithInsecure())
client := hello.NewHelloClient(conn)
```

- BaseDelay：基础间隔时间
- Multiplier：上次间隔时间 * Multiplier下次间隔时间
- Jitter：抖动系数
- MaxDelay：最大间隔时间

### 注意事项
1. 注意不要关闭了连接  
常见的在一个协程中启动grpc客户端，往往就不小心在defer中调用了close方法关闭client。这是没有任何默认提示的，如果不小心关闭了，你将死活找不出reconnect失败的原因。
2. reconnect并不会恢复之前建立的流  
如果是使用的流方法，那么在断开重连后，要主动的去获取新的流，常见的做法是pingpong，也就是通过另外请求一个相同client的简单方法去判断有没有重连上。如果对恢复的速度不着急，就定个sleep吧。
```golang
go func() {
	for {
		stream, err := client.Exchange(context.Background())
		if err != nil {
			log.Println("error get stream", err)
			time.Sleep(time.Second)
		} else {
			tick := time.Tick(time.Second * 1)
			for range tick {
				err := stream.Send(&hello.HelloRequest{})
				if err != nil {
					log.Println("Error sending:", err)
					break
				} else {
					log.Println("message send")
				}
			}
		}
	}
}()
```
