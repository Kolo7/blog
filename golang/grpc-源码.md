### go-grpc 源码

``` 
-grpc
	-attributes
	-backoff
```

##### attributes

​	attributes包是一个实验性的包，定义了grpc通用键值存储组件。，以及它的两个工厂方法：New()和WithValues()。Attributes还包括了一个获取键对应的值的方法Value()。需要注意的是工厂方法接受参数需要是双数，因为它默认键值交替传入。

```go
// 主体是一个结构体Attributes，只包含一个map，用于存储kv对
type Attributes struct

// 两个工厂方法
func New(kvs ...interface{}) *Attributes

func (a *Attributes) WithValues(kvs ...interface{}) *Attributes 

// 通过kay得到value
func (a *Attributes) Value(key interface{}) interface{}
```



##### backoff

​	backoff包是一个实验性的包，提供了backoff的配置选项。backoff是一种退避机制。当client连接到service失败时，最好不要立即重连，而是采用backoff。

可以设置的退避机制包括：

1. INITIAL_BACKOFF（第一次失败后要等待多久才能重试）
2. MULTIPLIER（重试失败后乘以补偿的因子）
3. JITTER (随机分配等待时间)
4. MAX_BACKOFF（退避上限）
5. MIN_CONNECT_TIMEOUT（我们愿意完成连接的最短时间）

```go
// 包含了backoff机制的配置，通过设置该结构体可以使用backoff
type Config struct

// 是一个带有默认值的Config
var DefaultConfig
```

##### balancer

​	balancer定义了有关负载均衡的API。依然是实验性的API。

##### benchmark

​	benchmark 实现了基准测试。

##### binarylog

​	包含了一个pb生成go文件，里面包含了GrpcLog相关的结构体。在查阅blog了解到，该包在gRPC中提供二进制日志记录功能。

作用是：

- 对服务进行故障排除，查找异常

- 负载测试

- 重现生产中的RPC

  按照提案上的说法，使用GrpcLog不需要改变代码，而是开启一个`GRPC_BINARY_LOG_FILTER`的环境变量或者是相同名字的标志或是选项字符串。

GrpcLogEntry是记录格式的原型，内部带有`initial`和`trailing`两种`metadata`。

​	日志记录是带有控制界面的，并且有过滤器，过滤器通过在``GRPC_BINARY_LOG_FILTER`环境变量设置。

​	默认过滤器将会记录完整的标题和消息，通过过滤器设置，可以记录截断的header和message，但是必要的标头是一定会无视过滤器规则记录的。过滤器规则是：`<service>/<method>`或者是`*` ，这是为了选择服务和方法。可以选择后面配置上`{[h:<header_length>];[m:<message_length>]}`，这是为了过滤最大记录长度。过滤器多条规则可以用','分隔。

- '*'，默认值。
- `<service>/*` ，指定服务中的所有方法
- `-<service>/<method>`，-是取反，不得记录指定方法
- 不支持`*/<method>`
- 不支持重复规则
- 格式错误将会无法启动gRPC

有关更多过滤细节，可以查看https://github.com/grpc/proposal/blob/master/A16-binary-logging.md

```go
type GrpcLogEntry struct
type GrpcLogEntry_ClientHeader struct
type GrpcLogEntry_ServerHeader struct
type GrpcLogEntry_Message struct
type GrpcLogEntry_Traier struct

type ClientHeader struct
type ServerHeader struct
type Message struct
type Traier struct
type Metadata struct
type MetadataEntry struct
type Address struct
```

##### channelz

​	Channelz是一个工具，可提供有关gRPC中不同级别的连接的全面运行时信息。

Channelz通过gRPC服务提供gRPC内部网络机制统计信息。要启用channelz，用户只需在其程序中将channelz服务注册到gRPC服务器并启动服务器即可。

```go
import "google.golang.org/grpc/channelz/service"

// s is a *grpc.Server
service.RegisterChannelzServiceToServer(s)

// call s.Serve() to serve channelz service
```



##### code

​	该包是定义了gRPC使用的规范错误代码。

```go
type Code uint32

func (c *Code) UnmarshalJSON(b []byte) error
func (c Code) String() string
```

##### connectivity

​	connectivity定义了连接语义。此包中所有API都是实验性的。

​	根据blog得知，gPRC建立了一种channel的抽象概念，描述客户端和服务器通信。和connectivity有关的是channel的五种状态。

- CONNECTING											连接中
- REDAY                                                        准备好
- TRANSIENT_FALURE                               暂时失败
- IDLE                                                            空闲
- SHOTDOWN                                              关闭

```go
type State int

func (s State) String() string

// 定义了channel五种状态
const (
	Idle	State = iota
    Connecting
    Ready
    TransientFailure
    Shutdown
)
// 提供一个Reporter接口，包含了轮询状态和等待状态改变的
type Reporter interface {
    CurrentState() State
    // 该方法将会阻塞，直到状态发生改变与给定状态不同；如果ctx超时或是被取消会提前返回false
    WaitForStateChange(context.Context, State) bool
}
```

##### credentials

​	credentials实现了关于gRPC库的各类凭证支持。封装了客户端向服务器进行身份验证所需的所有状态。

##### encoding

​	encoding定义了压缩器和编解码器的接口，并且还有注册和检索压缩器和编解码器的功能。

​	该包实现了proto的编解码器和gzip压缩器。

```GO
// 该常量用于指定未压缩流的可选编码
const Identity = "identity"
// 压缩器接口
type Compressor interface {
    Compress(w io.Writer) (io.WriteCloser, error)
    Decompress(r io.Reader) (io.Reader, error)
    Name() string
}
// 压缩器映射表
var registeredCompressor = make(map[string]Compressor)
// 在映射表注册压缩器，注册压缩器只能在init时进行，并且该方法不是线程安全的
func RegisterCompressor(c Compressor)

func GetCompressor(name string) Compressor
// 编解码器，要求编解码器的编解码方法必须是线程安全的，能够在多个goroutines间工作
type Codec interface{
    Marshal(v interface{}) ([]byte, error)
    
    Unmarshal(data []byte, v interface{}) error
    
    Name() string
}

var registeredCodecs = make(map[string]Codec)
// 同样，编解码器只能在init期间注册，并且线程不安全
func RegisterCodec(codec Codec)

func GetCodec(contentSubtype string) Codec
```

