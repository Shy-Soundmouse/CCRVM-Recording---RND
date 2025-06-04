#!/bin/bash

# $1 - url
# $2 - prefix

url=$1
prefix=$2

period=3600

while [ 1 ];do

s1=$(date +%s)
s2=$(( $s1 + ${period} ))
s2=$(( $s2 - ( $s2 % ${period} )))
r=$(( $s2 - $s1 ))
dir=$(date -u --date=@$s1 +"%Y-%m-%d")
t1=$(date -u --date=@$s1 +"%Y%m%d%H%M%S")
t2=$(date -u --date=@$s2 +"%Y%m%d%H%M%S")

if [ ! -d ${dir} ]; then mkdir ${dir}; fi

ffmpeg -i "$url" -acodec aac -vcodec libx264 -s 256x144 -r 5 -t $r -crf 30 ${dir}/${prefix}_${t1}_${t2}.mp4

# !!! remember the pro*.sh script MUST have a sleep before moving to allow ffmpeg to close gracefully !!!
./s3_upload.sh ${dir}/${prefix}_${t1}_${t2}.mp4 &

done
