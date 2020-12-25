
# Faker

### 应对需求

    在软件需求、开发、测试过程中，有时候需要使用一些测试数据，针对这种情况，我们一般要么使用已有的系统数据，要么需要手动制造一些数据。
    
    由于现在的业务系统数据多种多样，千变万化。在手动制造数据的过程中，可能需要花费大量精力和工作量，此项工作既繁复又容易出错，而且，部分数据的手造工作无法保障：比如UUID类数据、MD5、SHA加密类数据等。

### 介绍

    Faker是一个Python包，开源的GITHUB项目，主要用来创建伪数据，使用Faker包，无需再手动生成或者手写随机数来生成数据，只需要调用Faker提供的方法，即可完成数据的生成。
     
     现在的Faker支持 Python Faker, PHP Faker, Perl Faker, and by Ruby Faker。

### 使用

##### 安装

pip install Faker

##### 基本用法


```python
from faker import Faker
fake = Faker()
```


```python
fake.name()
```

> 'Meredith Chavez'




```python
fake.address()
```

> '4260 Carpenter Cove\nPort Joseph, IN 13731'




```python
fake.text()
```

> 'Finish health analysis write cause in agreement their. Challenge set brother likely not.\nBig language plant look marriage. Or large large so stay heart cut.'



### Provider

制造更加复杂的假数据，需要加载不同的Provider。

##### base Provider

base Provider无需加载直接可用，是默认使用的provider。
可以制造一些基础的数据，例如任意长度的数字，字母组合，但没有实际的意义。


```python
# 数字加字母
fake.bothify(text="## ??", letters="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
```

> '76 vX'




```python
# 范围内数字
fake.random_int(min=0, max=9999, step=1)
```

> 3830



##### 其他官方Provder


```python
from faker.providers import internet
fake.add_provider(internet)
```


```python
fake.ipv4_private()
```

> '10.151.113.226'



### 本地化


```python
fake = Faker('zh_CN')
```


```python
fake.text()
```

> '作品看到一定威望.管理登录最大这么出来生活操作.\n之后留言类别很多最大无法.你们美国报告.分析时候北京威望.责任的话中国您的.\n系列教育还有完成全国发布手机这样.一种两个应用登录.以下应用一样广告.\n规定喜欢完全学生首页帮助.\n名称之后希望建设业务历史如此继续.一定管理回复详细阅读文章.以下的是技术计划什么.\n起来这个搜索最新公司.帖子开发来源完成已经.问题还有客户介绍.'




```python
fake.address()
```

> '青海省阜新市朝阳李街H座 986383'



### 创建自己的Provider


```python
from faker.providers import BaseProvider
```


```python
class MyProvider(BaseProvider):
    def foo(self):
        return 'bar'
```


```python
fake.add_provider(MyProvider)
fake.foo()
```

>  'bar'



| providers类名 | 作用 |
| :----------- | ----: |
| base        | 基础包，包含各种数字字母随机方法 |
| address     | 地址相关 |
| automotive  | 汽车行业 |
| bank        | 银行 |
| barcode     | 条码 |
| color       | 颜色 |
| company     | 公司（职称，口号） |
| credit_card | 信用卡 |
| currency    | 货币 |
| date_time   | 日期时间 |
| file        | 文件（扩展名，文件名，带路径文件名） |
| geo         | 地理 |
|internet|互联网（邮箱，域名，hostname，图片url，ipv4、ipv6地址，mac地址）|
|isbn|书号|
|job|工作|
|lorem|文章句子|
|misc|杂项（md5，二进制串，密码，sha1，sha256，uuid）|
|person|人相关（人名（可分男女），姓，名，）|
|phone_number|电话号码（手机号，电话号码）|
|profile|制造JSON格式的数据|
|python|python相关（小数，列表，字典，集合，元组）|
|ssn|搞不懂|
|user_agent|用户代理（安卓设备渠道token，各类浏览器标识，操作系统token）|

### 在命令行使用

- `-h`，请求帮助。
- `-o filename`，输出重定向到指定文件夹。
- `-l zh_CN`，默认是英文，改为输出中文。
- `-r pepeat `，输出指定数量的随机数据。
- `-s sep`，在生成的输出之间用指定的分隔符分割。
- `-i {custom_provider1 custom_provider2}`，使用指定的provider类所在文件。

### 创建属于自己的provider


```python
from faker.providers import BaseProvider

class Provider(BaseProvider):
    def foo(self):
        return 'bar'

fake.add_provider(Provider)
fake.foo()
    'bar'
```


### 获取random示例


```python
fake.random.randint(1,10)
```



### 重现随机

可以设置种子，就可以方便测试重现。


```python
from faker import Faker
fake = Faker()
Faker.seed(4321)

print(fake.name())
```

    Jason Brown

