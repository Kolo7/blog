# mongodb集群带来的一致性问题

## 关键词
> mongodb、集群、强一致性问题、Write Concern、事务

### 环境

mongoDB version: 4.0.18

mongoDB集群：一主两从（主写从读）

golang version: 1.14.4

驱动库: gopkg.in/mgo.v2@v2.0.0

### 问题描述

这几天线上环境反馈了一个小小的bug，一个更新操作无法正常执行。我的更新业务是先写更新，再读取刚刚更新的内容，再写入到另外一个表。表现出得bug就是，写入另外一个表的数据是旧的。

根据分析就发现问题与mongodb集群有关系。线上采用的是mongodb集群，一主两从，主写从读。第一次的写操作是写入到主节点，随后紧跟着的读操作是向从节点读，这时复制操作还没发生，从节点的数据是旧的，这才导致了bug。问题不复杂，是集群数据库为保证高可用性，而带来了一致性问题。我的业务要求这次写操作应该是强一致性的。

### 解决方案

- 方案一

mongodb支持改变读写模式，从集群的读写方式入手，就是由主写从读改成主写主读。也就不存在一致性问题。不过这样就改变了分布式的初衷了。主从模式变成了主备。

所以这个方案我就没尝试了。

- 方案二

从事务角度入手。mongodb官方提供了Write/Read Concern的设置。详细的介绍如下：

>https://docs.mongodb.com/master/reference/write-concern/

简单来说，通过设置Write Concern，可以保证这次写操作最少要写入多少个replica。例如：我这里三个replica，我的需求是强一致性，也就是保证写操作全部写入到所有的主从节点才返回。

按照`gopkg.in/mgo.v2`官方文档的介绍，有以下方法可以设置单次session中Write Concern模式：

> session.SetSafe(&mgo.Safe{W: 3})

整个请求的过程
```go
var(
    dbSession *mgo.Session
)
func init(){
    dbSession, _ = mgo.Dial(host)
}

func Update(){
    session := dbSession.Copy()
    session.setSage(&mgo.Sage{W: 3})
    db := session.DB(dbname)
    collection := db.C(collectionName)
    _ := collection.Update(selector, updater)
}
```

### 扩展讨论

Write Concern的设置，可以满足对mongoDB强一致性或者是事务的可靠性的要求。单次session的设置能够最小限度的降低等待时延影响。如果是利用mongoDB做一些CURD业务时，是比较常见的需求。

mongoDB数据库集群平时用着似乎和普通的mysql差不多，但毕竟还是其特性的。在针对事务性方面不能够把集群层面透明化处理。需要考虑主从性质或者是主备性质。而且mongoDB集群本身就是一种灾备手段，需要把机器宕机作为一种常态化处理，在代码层面不能忽视。