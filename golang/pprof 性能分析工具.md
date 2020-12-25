# pprof 性能分析工具

### 启动http接口
```golang
import _ "net/http/pprof"
go func() {
	log.Info("%v",http.ListenAndServe("localhost:9999",nil))
}()
```

### 作用
- CPU分析
- 内存分析
- 阻塞分析
- 锁分析

### web界面

>http://localhost:9999/debug/pprof/

### 交互式工具

- flat：给定函数上运行耗时 
- flat%：同上的 CPU 运行耗时总比例 
- sum%：给定函数累积使用 CPU 总比例 
- cum：当前函数加上它之上的调用运行总耗时 
- cum%：同上的 CPU 运行耗时总比例

参数:  
inuse_space  
amount of memory allocated and not released yet


inuse_objects  
amount of objects allocated and not released yet


alloc_space  
total amount of memory allocated (regardless of released)


alloc_objects  
total amount of objects allocated (regardless of released)


- #### 查看cpu10s内的分析数据
``` bash
go tool pprof  http://localhost:9999/debug/pprof/profile?seconds=10
top10
```
- #### 查看内存分析数据
```bash
go tool pprof  http://localhost:9999/debug/pprof/heap
```

- #### 查看阻塞
```bash
go tool pprof  http://localhost:9999/debug/pprof/block
```

- #### 查看互斥锁
```bash
go tool pprof  http://localhost:9999/debug/pprof/mutex
```

### 可分析问题

#### 内存泄漏
内存泄漏的问题比较常见的情况是有全局变量错误持有大内存对象并且不主动放弃持有；或者是有链表形式的数据结构头指针被某个没有结束的goroutine持有，内存无法释放。


#### goroutine
一般是多个相同的goroutine同时无法结束，每个goroutine的栈帧不能得到释放，积少成多造成了内存泄漏，可以称为goroutine泄漏。

