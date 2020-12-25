# TLS

```
openssl genrsa -out ca.key 4096
openssl req -new -x509 -days 36500 -subj "/CN=10.11.8.109" -key ca.key -out ca.crt

openssl genrsa -out server.key 4096
openssl req -new -subj "/CN=10.11.8.109" -key server.key -out server.csr
openssl x509 -req -sha256 -CA ca.crt -CAkey ca.key -CAcreateserial -days 36500 -in server.csr -out server.crt

openssl genrsa -out client.key 4096
openssl req -new -subj "/CN=client.tcgo.io" -key client.key -out client.csr
openssl x509 -req -sha256 -CA ca.crt -CAkey ca.key -CAcreateserial -days 36500 -in client.csr -out client.crt
```
