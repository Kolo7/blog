# docker最小镜像制作

制作镜像时应该尽量的让生成的镜像体积小，达成这一点需要遵循：  
- 选择最小体积的基础镜像
- 使用少量的命令，这样产生的层较少
- 使用多阶段构建，避免中间产物加入到最终镜像
- 只加入必要的工具到镜像中


### 最小体积基础镜像
一般的基础镜像后面带`-alpine`式最小版本的。使用该类镜像作为基础镜像。  

### 控制层的多少
docker构建镜像时，dockerfile中每条命令将会生成一个新的层。因此减少命令的数量可以减小体积。  
如果有多条RUN命令，可以用`&&`连接减少层。  
原
```dockerfile
FROM IAMGE
RUN COMMAND1
RUN COMMAND2
```

变
```dockerfile
FROM IAMGE
RUN COMMAND1 \
    && COMMAND2
```


### 多阶段构建
构建时可能会有中间产物，但实际不需要带入层，这时候可以用多阶段构建。  
关键就是使用COPY命令，将第一阶段的结果复制到最终阶段需要的地方。

```dockerfile
FROM node:8 as build
WORKDIR /app
COPY package.json index.js ./
RUN npm install

FROM node:8
COPY --from=build /app /
EXPOSE 3000
CMD ["index.js"]
```

### 只添加有用工具
alpine镜像是最小的，很多linux发行版存在的工具都没有，使用apk工具安装那些需要的工具。  
经验就是缺少加啥
```dockerfile
RUN apk add --update --no-cache <package>
```


### 示例
给出一个golang的多阶段最小构建方案
```dockerfile
# syntax = docker/dockerfile:1-experimental

FROM golang:1.14-alpine AS build

ENV CGO_ENABLED=0
ENV GOPRIVATE="gitlab.xsjcs.cn/*"

RUN apk add --update --no-cache ca-certificates curl make git gcc libtool musl-dev

RUN mkdir /app
COPY . /app
WORKDIR /app
RUN --mount=type=cache,target=/root/.cache/go-build  go build -o app1 ./cmd/tako-ws/main.go

###
FROM alpine:3.11.6 as final

RUN apk add --update --no-cache ca-certificates tzdata bash curl busybox-extras
ENV TZ Asia/Shanghai
SHELL ["/bin/bash", "-c"]
VOLUME /data

COPY --from=build /app/app1 /app/

EXPOSE 8000 8001 8002
WORKDIR /app
CMD ["/app/app1"]

```