#!/bin/bash
# author:kuangle

if [ ! "$1" ];
then
  echo "需要指定参数{tag}";
  exit 0;
fi

tag=$1
docker stop tako-ws
docker rm tako-ws
docker run -d --network host -p 8000-8003:8000-8003 --name tako-ws -v /data/tako-ws/tako-ws.yaml:/app/tako-ws.yaml -v /data/tako-ws/log:/app/log hub.kce.ksyun.com/xsjom/tako-ws:$tag
