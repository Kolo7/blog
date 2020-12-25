# mailx发邮件配置

### 安装mailx
> yum install mailx

### 修改配置文件
> vim /etc/mail.rc
在末尾加上一下配置

```bash
set from=kuangle@kingsoft.com
set smtp=zhmail.kingsoft.com:587
set smtp-auth-user=xxxx
set smtp-auth-password=xxxxxx
set smtp-auth=login
set smtp-use-starttls=yes
set ssl-verify=ignore
set nss-config-dir=~/.certs
```

### 配置项解释
##### 发件人邮箱
> set from=kuangle@kingsoft.com

##### 发件服务器
> set smtp=zhmail.kingsoft.com:587

##### 发件人账号密码
>set smtp-auth-user=xxxx  
>set smtp-auth-password=xxxxxx

##### 验证方式
>set smtp-auth=login

##### 是否启用ssl验证
下面三者只在启动SSL验证方式时才需要
>set smtp-use-starttls=yes

##### 忽略证书警告
>set ssl-verify=ignore

##### 证书所在位置
>set nss-config-dir=~/.certs

### 获取ssl证书配置发送
##### 获取证书
```bash
#获取邮件服务器证书：
　　# 465端口
　　echo -n "" | openssl s_client -connect smtp.xxx.com:465 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > xxx.crt

　　# 587端口
　　echo -n | openssl s_client -starttls smtp -connect smtp.xxx.com:587 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > xxx.crt

    # 也可以直接在浏览器上打开网页版，保存证书为PEM（base64格式）格式然后上传到服务器
```

##### 信任证书
```bash
certutil -A -n 'xxx' -t "P,P,P" -d . -i ./xxx.crt··
#上述命令中
#    -A表示添加
#    -n是nickname，可以随意取，例如126或qq
#    -t表示受信任的标签，可取值是t/c/p三种或者其组合
#    -d表示证书所在目录，-i指示证书文件的位置

certutil -A -n 'smtpqq' -t "P,P,P" -d . -i ./certs/qq.crt
```
### 发件
按ctrl+d结束正文书写
>mail -s "test" 1438349140@qq.com

##### 使用文件发送
> mail -s "This is Subject" someone@example.com < /path/to/file

### 详细参考
[传送地址](http://lokie.wang/article/57)