# httpClient

### 设置拨号超时时间

```go
// untils.go
// 请求阶段设置超时时间timeout，尝试请求直到成功或请求retry次
func CustomDo(method, url string, header map[string]string, reader io.Reader, timeout time.Duration, retry int) (*http.Response, error) {
	client := http.Client{
		Transport: &http.Transport{
			DialContext: (&net.Dialer{
				Timeout: timeout,
			}).DialContext,
		},
	}
	var err error
	var resp *http.Response
	req, err := http.NewRequest(method, url, reader)
	if err != nil {
		return nil, err
	}
	for k, v := range header {
		req.Header.Set(k, v)
	}
	for i := 0; i < retry; i++ {
		if resp, err = client.Do(req); err != nil {
			// 请求间隔为（0s～1s）
			time.Sleep(time.Millisecond * time.Duration(rand.Intn(1000)))
			continue
		}
		break
	}
	return resp, err
}
```

### 开启gzip压缩
这个需要对方配合能够处理
```go
// untils.go
func GZipData(data []byte) (io.Reader, error) {
	var zBuf bytes.Buffer
	zWriter := gzip.NewWriter(&zBuf)
	if _, err := zWriter.Write(data); err != nil {
		log.Error("gzip failed[%s]", err)
		return nil, err
	}
	defer zWriter.Close()
	return &zBuf, nil
}
```

```go
// dao
reader, err := utils.GZipData(bytes)
header := map[string]string{
	"Accept-Encoding": "gzip",
    }
resp, err := utils.CustomDo("POST", url, header, reader, 10*time.Second, 5)
if err != nil {
    log.Error("post clickhouse failed[%v]", err)
	}
defer resp.Body.Close()
log.Info("response status[%s]",resp.Status)
```