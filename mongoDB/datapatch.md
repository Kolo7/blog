### 备份
```bash
mongodump -u tako -p AdY9pQDqP75vONm1 -d tako -o tako_db.20200903
```
### createtime时间戳改为标准格式

第一步：检查目前情况
```js
db.app.find({createtime: {$type: "long"}}).count();
/usr/bin/mongo -utako -pAdY9pQDqP75vONm1 tako --quiet --eval 'DBQuery.shellBatchSize = 100000;db.app.find({createtime: {$type: "long"}},{createtime:1})' > tako-app.createtime-migration.json
```

```js
db.app.find({"releaseversion.createtime": {$type: "long"}}).count();
/usr/bin/mongo -utako -pAdY9pQDqP75vONm1 tako --quiet --eval 'DBQuery.shellBatchSize = 100000;db.app.find({"releaseversion.createtime": {$type: "long"}},{"releaseversion.createtime":1})' > tako-app.releaseversion.createtime-migration.json
```

```js
db.appversion.find({createtime: {$type: "long"}}).count();
/usr/bin/mongo -utako -pAdY9pQDqP75vONm1 tako --quiet --eval 'DBQuery.shellBatchSize = 100000;db.appversion.find({createtime: {$type: "long"}},{createtime:1})' >> tako-appversion.createtime-migration.json
```

```js
db.app.find({createtime: {$type: "date"}}).count();
db.app.find({"releaseversion.createtime": {$type: "date"}}).count();
db.appversion.find({createtime: {$type: "date"}}).count();
```

第二步：更新app和appversion的createtime字段类型+数据迁移
```js
db.appversion.find().forEach(
    function(i) {
        if (Object.prototype.toString.call(i.createtime) == "[object NumberLong]") {
            i.createtime = new Date(i.createtime * 1000);
            db.appversion.save(i);
        }
    }
);
```

```js
db.app.find().forEach(
    function(i) {
        if (Object.prototype.toString.call(i.createtime) == "[object NumberLong]") {
            i.createtime = new Date(i.createtime * 1000);
        }
        if (i.releaseversion != null && Object.prototype.toString.call(i.releaseversion.createtime) == "[object NumberLong]") {
            i.releaseversion.createtime = new Date(i.releaseversion.createtime * 1000);
        }
        db.appversion.find({appid: i._id.str}).sort({'createtime':-1}).limit(1).forEach(
            function(av) {
                i.updatetime = av.createtime;
            }
        )
        db.app.save(i);
    }
);
```

### 更新app的图片地址(截断?sign=)
```js
db.app.find({logourl:/sign=/},{_id: 0,logourl: 1}).count()

db.app.find({logourl:/sign/}).forEach(
    function(i) {
        var index = i.logourl.indexOf("?sign=")
        if (index) {
            i.logourl = i.logourl.substring(0,index)
            db.app.save(i)
        }
    }
)
```

### 启用lanfiledelete字段记录内网包存在
删除废弃字段appversion.package.lan_resource_invalid
```js
db.appversion.find({"package.lan_resource_invalid":{$exists:1}}).count()
db.appversion.update({"package.lan_resource_invalid":{$exists:1}},{$unset: {"package.lan_resource_invalid": ""}},false,true)
db.appversion.find({"package.lan_resource_invalid":{$exists:1}}).count()
```

设置2020年6月1日之前的version.lanfiledeleted字段全部为true
```js
db.appversion.find({ createtime: {$lt: ISODate("2020-06-01T00:00:00Z")}, lanfiledeleted: {$ne: true}, "package.lanurl": /10.11.32.11:9000/ }).count()
db.appversion.update({ createtime: {$lt: ISODate("2020-06-01T00:00:00Z")}, lanfiledeleted: {$ne: true}, "package.lanurl": /10.11.32.11:9000/ }, {$set: {lanfiledeleted: true}} , false, true)
db.appversion.find({ createtime: {$lt: ISODate("2020-06-01T00:00:00Z")}, lanfiledeleted: {$ne: true}, "package.lanurl": /10.11.32.11:9000/ }).count()
```
更新内网包在6月1日之后的lanfiledeleted标记，只对10.11.32.11:9000
```js
db.appversion.find({$and: [{createtime: {$gt: ISODate("2020-06-01T00:00:00Z")}} , {createtime: {$lt: ISODate("2020-09-18T00:00:00Z") }}, {lanfiledeleted: {$exists: 0}}, {"package.lanurl": /10.11.32.11:9000/} ] }).count()
POST /api/app/version/checklandeleted?st=2020-06-01T00:00:00Z&et=2020-09-18T00:00:00Z
db.appversion.find({$and: [{createtime: {$gt: ISODate("2020-06-01T00:00:00Z")}} , {createtime: {$lt: ISODate("2020-09-18T00:00:00Z") }}, {lanfiledeleted: {$exists: 0}}, {"package.lanurl": /10.11.32.11:9000/} ] }).count()
```

### 将所有的is_public_app字段替换成 ispublicapp
```js
db.app.find({is_public_app: {$exists: 1}}).count()
db.app.find({is_public_app: {$exists: 1}}).forEach(
    function(i) {
        i.ispublicapp = i.is_public_app;
        db.app.save(i);
    }
)
db.app.find({ispublicapp: {$exists: 1}}).count()
db.app.update({is_public_app: {$exists: 1}},{$unset: {is_public_app: ""}},false,true)
db.app.find({is_public_app: {$exists: 1}}).count()
```

### 将原host改为域名
含有minio host只有appversion.package.lanurl和app.releaseversion.package.lanurl  
lanurl替换  
- 珠海：zhminio-tako.seasungame.com 10.11.32.11     443
- 广州：gzminio-tako.seasungame.com 172.18.116.50   443
- 北京：bjtako.jx2.bjxsj.site 10.89.129.105         443
- 深圳：tako.jx2.bjxsj.site 172.18.72.77            443
// 查询所有的host
```js
db.appversion.aggregate([ {$group: {_id: {$substr: ["$package.lanurl", 0, 24]}, num: {$sum: 1}}}])

db.app.aggregate([ {$group: {_id: {$substr: ["$releaseversion.package.lanurl", 0, 18]}, num: {$sum: 1}}}])
// 珠海 先替换lanfiledeleted=true
db.appversion.find({"package.lanurl": /10.11.32.11/, "lanfiledeleted":true}).forEach(
    function(i) {
        i.package.lanurl = i.package.lanurl.replace("http://10.11.32.11:9000", "https://zhminio-tako.seasungame.com")
        db.appversion.save(i)
    }
);
// 再替换lanfiledeleted!=true
db.appversion.find({"package.lanurl": /10.11.32.11/, "lanfiledeleted":{$ne: true}}).forEach(
    function(i) {
        i.package.lanurl = i.package.lanurl.replace("http://10.11.32.11:9000", "https://zhminio-tako.seasungame.com")
        db.appversion.save(i)
    }
);
// 替换app.releaseversion
db.app.find({"releaseversion.package.lanurl": /10.11.32.11/}).forEach(
    function(i) {
        i.releaseversion.package.lanurl = i.releaseversion.package.lanurl.replace("http://10.11.32.11:9000", "https://zhminio-tako.seasungame.com")
        db.app.save(i)
    }
);
// 广州
db.appversion.find({"package.lanurl": /172.18.116.50/}).forEach(
    function(i) {
        i.package.lanurl = i.package.lanurl.replace("http://172.18.116.50:9000", "https://gzminio-tako.seasungame.com")
        db.appversion.save(i)
    }
);
db.app.find({"releaseversion.package.lanurl": /172.18.116.50/}).forEach(
    function(i) {
        i.releaseversion.package.lanurl = i.releaseversion.package.lanurl.replace("http://172.18.116.50:9000", "https://gzminio-tako.seasungame.com")
        db.app.save(i)
    }
);

// 深圳 深圳的host和北京的只差一个前缀
db.appversion.find({"package.lanurl": /http:\/\/tako.jx2.bjxsj.site/}).forEach(
    function(i) {
        i.package.lanurl = i.package.lanurl.replace("http://tako.jx2.bjxsj.site:9000", "https://tako.jx2.bjxsj.site")
        db.appversion.save(i)
    }
);
db.appversion.find({"package.lanurl": /172.18.72.77/}).forEach(
    function(i) {
        i.package.lanurl = i.package.lanurl.replace("http://172.18.72.77:9000", "https://tako.jx2.bjxsj.site")
        db.appversion.save(i)
    }
);
db.app.find({"releaseversion.package.lanurl": /http:\/\/tako.jx2.bjxsj.site/}).forEach(
    function(i) {
        i.releaseversion.package.lanurl = i.releaseversion.package.lanurl.replace("http://tako.jx2.bjxsj.site:9000", "https://tako.jx2.bjxsj.site")
        db.app.save(i)
    }
);

db.app.find({"releaseversion.package.lanurl": /172.18.72.77/}).forEach(
    function(i) {
        i.releaseversion.package.lanurl = i.releaseversion.package.lanurl.replace("http://172.18.72.77:9000", "https://tako.jx2.bjxsj.site")
        db.app.save(i)
    }
);


```

db.appversion.find({"package.lanurl": /https\/\/zhminio-tako.seasungame.com/}).forEach(
    function(i) {
        i.package.lanurl = i.package.lanurl.replace("https", "https:")
        db.appversion.save(i)
    }
);

db.appversion.find({"package.lanurl": /https::\/\/zhminio-tako.seasungame.com/}).forEach(
    function(i) {
        i.package.lanurl = i.package.lanurl.replace("::", ":")
        db.appversion.save(i)
    }
);

查询有多少用户存在两个同名user：  
> db.user.aggregate([{$group:{_id:"$username",num:{$sum: 1}}}, {$match:{num:{$gt: 1}}}])