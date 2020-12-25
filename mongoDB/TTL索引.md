# 设置TTL索引

mongodb不能单独设置某文档中一行的过期时间，而是通过设置TTL过期索引实现。

## 设置TTL索引  
先删除可能存在索引，然后为accesstoken表添加过期索引: expiredtime，过期时间设置为一个月。
```js
db.accesstoken.dropIndex("expiredtime_1")
db.accesstoken.createIndex(
    {"expiredtime":1},
    {expireAfterSeconds: 2592000}
)
```
## 插入文档

创建好索引后，在需要某个行有过期时间时，只需要设置它包含同名字段。
```js
db.accesstoken.insert({"expiredtime" : new Date()})
```

## 注意事项

1. 一行只能包含关联一个过期索引  
2. mongodb每60s检查一次过期时间是否到达，集中删除已过期行，因此过期时间设置小于60s是不准确的  
3. 在设置过期索引之前的行如果包含了同名字段，在设置后自动的使用索引，在时间到达后被删除  
4. 索引本身是不会过期的
