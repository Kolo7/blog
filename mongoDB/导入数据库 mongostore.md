# mongodb 导入数据库

### 工具
mongorestore

### 删除数据库
```js
use dbname
db.dropDatabase()
```

### 命令
```bash
mongorestore -h 127.0.0.1  -d dbname -u username -p password --authenticationDatabase=dbname dbdirectory
```

### 注意事项
这里的authenticationDatabase是验证数据库，可能是导入的库，也可能不是。

