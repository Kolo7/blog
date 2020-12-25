# aggregate 管道查询

### 语法

#### $lookup  

就是关联不同表之间的键。  
先贴语法
```js
{
   $lookup:
     {
       from: <collection to join>,
       localField: <field from the input documents>,
       foreignField: <field from the documents of the "from" collection>,
       as: <output array field>
     }
}
```

### 示例

需求：关联app和project表中的projectid和_id字段。
```python
result = db_tako.app.aggregate([
    {'$match':{
        'projectid': '10024'
    }},
    {'$lookup': {
        'from': 'project',
        'localField': 'projectid',
        'foreignField': '_id',
        'as': 'region'
    }},
    {'$project':{
        '_id':1,
        'projectid':1,
        'createtime':1,
        'region.name':1
    }}
])
for each in result:
    print(each)
```

#### $group

分组查询

```js
{ $group: { _id: <expression>,
 <field1>: { <accumulator1> : <expression1> }, ... }
  }
```

- _id  
为必选字段，为被分组字段，可为空或null

- \<accumulator\>  
分组函数，可选如下：  
```
$addToSet
$avg
$first
$last
$max
$mergeObjects
$min
$push
$stdDevPop
$stdDevSamp
$sum
```

```js
db.user.aggregate(
    {"$group":{
        "_id":{"username":"$username"},
        "sum": {"$sum":1}
    }},
    {"$sort":{
        "sum":-1
    }}
)
```


#### \$skip和\$limit
可以用这个两个关键字实现分页功能

```js
db.app.aggregate(

{"$skip": page.Cursor},
{"$limit": page.Count},
)
```