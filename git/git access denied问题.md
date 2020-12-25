# windows下git修改凭据

### 错误现象
修改gitlab密码后，git无法push代码到远程仓库。
报错如下
```sh
git push
remote: HTTP Basic: Access denied
fatal: Authentication failed for 'https://gitlab.cn/demo.git/'
```

### 重现条件：
系统：windows10
版本控制工具：git
远程仓库：自建gitlab
仓库连接方式：https

### 原因：
git在连接仓库时采用账号密码验证方式，而windows将账密保存在凭据管理器，需要手动去修改。

### 有效方法
运行对话框（win+R）
输入`control /name Microsoft.CredentialManager`
找到`git:`打头的条目，可能会有多个，选择gitlab替换你的密码

### 其他参考
[GitLab remote: HTTP Basic: Access denied and fatal Authentication](https://stackoverflow.com/questions/47860772/gitlab-remote-http-basic-access-denied-and-fatal-authentication/52092795#52092795)
