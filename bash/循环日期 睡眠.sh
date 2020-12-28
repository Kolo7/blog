# /bin/bash

starttime=$(date +%s -d '2020-06-01 00:00:00')

endtime=$(date +%s -d '2020-10-31 00:00:00')

oneday=$((24*60*60))

while [[ $starttime -le $endtime ]];
do
deldate=$(date +%Y%m%d -d "1970-01-01 UTC $starttime seconds")
starttime=$(($starttime+$oneday))
echo $deldate
/usr/local/bin/mc rm --recursive --force minio1/local/download/${deldate}
sleep 0.5s
done
