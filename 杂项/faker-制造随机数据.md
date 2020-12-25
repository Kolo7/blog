# faker 

### 应对需求

在软件需求、开发、测试过程中，有时候需要使用一些测试数据，针对这种情况，我们一般要么使用已有的系统数据，要么需要手动制造一些数据。

由于现在的业务系统数据多种多样，千变万化。在手动制造数据的过程中，可能需要花费大量精力和工作量，此项工作既繁复又容易出错，而且，部分数据的手造工作无法保障：比如UUID类数据、MD5、SHA加密类数据等。

### 介绍

Faker是一个Python包，开源的GITHUB项目，主要用来创建伪数据，使用Faker包，无需再手动生成或者手写随机数来生成数据，只需要调用Faker提供的方法，即可完成数据的生成。

 现在的Faker支持 Python Faker, PHP Faker, Perl Faker, and by Ruby Faker。

### 示例

##### 安装

>  pip install Faker

##### 基本用法

```python
from faker import Faker
fake = Faker()
fake.name()
```




### 使用不同的语言

```python
from faker import Faker
fake = Faker(['it_IT', 'en_US', 'ja_JP'])
for _ in range(10):
    print(fake.name())
```



### 使用官方的provider

```python
fake.add_provider(internet)
fake.ipv4_private()
```



官方的provider种类已经非常的多，能够满足日常的大部分使用情形。

| providers类名 |                                                         作用 |
| :------------ | -----------------------------------------------------------: |
| base          |                             基础包，包含各种数字字母随机方法 |
| address       |                                                     地址相关 |
| automotive    |                                                     汽车行业 |
| bank          |                                                         银行 |
| barcode       |                                                         条码 |
| color         |                                                         颜色 |
| company       |                                           公司（职称，口号） |
| credit_card   |                                                       信用卡 |
| currency      |                                                         货币 |
| date_time     |                                                     日期时间 |
| file          |                         文件（扩展名，文件名，带路径文件名） |
| geo           |                                                         地理 |
| internet      | 互联网（邮箱，域名，hostname，图片url，ipv4、ipv6地址，mac地址） |
| isbn          |                                                         书号 |
| job           |                                                         工作 |
| lorem         |                                                     文章句子 |
| misc          |              杂项（md5，二进制串，密码，sha1，sha256，uuid） |
| person        |                         人相关（人名（可分男女），姓，名，） |
| phone_number  |                                 电话号码（手机号，电话号码） |
| profile       |                                           制造JSON格式的数据 |
| python        |                   python相关（小数，列表，字典，集合，元组） |
| ssn           |                                                       搞不懂 |
| user_agent    | 用户代理（安卓设备渠道token，各类浏览器标识，操作系统token） |

### 使用社区的provider

社区贡献了一些provider，关于微服务，云服务，web相关，但是并不怎么友好，没有说明

### 在命令行使用

- `-h`，请求帮助。
- `-o filename`，输出重定向到指定文件夹。
- `-l zh_CN`，默认是英文，改为输出中文。
- `-r pepeat `，输出指定数量的随机数据。
- `-s sep`，在生成的输出之间用指定的分隔符分割。
- `-i {custom_provider1 custom_provider2}`，使用指定的provider类所在文件。

### 创建属于自己的provider

##### 导入包

```python
from faker.providers import BaseProvider
```

##### 继承BaseProvider

```python
class Provider(BaseProvider):
    def foo(self):
        return 'bar'
```

##### 实现指导

通过继承base，使用base中的基础方法，实现自己的目标provider。

### 重现随机

可以设置种子，就可以方便测试重现。

```python
from faker import Faker
fake = Faker()
Faker.seed(4321)

print(fake.name())
```



