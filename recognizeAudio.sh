#!/bin/bash
##################################################
## Dmitriy Lazarev (goldlinux) 2022              #
##################################################
# pip3 install ffmpeg-normalize
export LC_ALL=ru_RU.UTF-8

api_key='your_key'
folderid='your_folfer_id'

function recognize {
  curl -q --silent -X POST -H "Authorization: Api-Key $api_key" \
	-H "Transfer-Encoding: chunked"  --data-binary "@$1" \
	"https://stt.api.cloud.yandex.net/speech/v1/stt:recognize?topic=general&format=lpcm&sampleRateHertz=8000&folderId=$folderid&rawResults=true"\
  | jq '.result' | cut -d '"' -f2 | grep -v 'null'
}

function normalize {
    md5=`md5sum "$1" | awk '{ print $1 }'`
    tmp="/tmp/$md5.wav"
    level=$(ffmpeg -y -i "$1" -af "volumedetect" -vn -sn -dn -f null /dev/null 2>&1 | grep max_volume | awk -F': ' '{print $2}' | cut -d' ' -f1)
    level=$(echo "-(${level})" | bc -l)
    ffmpeg -y  -loglevel panic -i "$1" -af volume=${level}dB "$tmp"
    mv "$tmp" "$1"
}

function process {
  # normalize "$fl"
  txt=$(recognize "$1")
  if [ ! -z "$txt" ]; then
    echo "${fl}: ${txt}"
    echo "${txt}" > "${1}.txt"
  fi
}

find -name "*.wav" |  while read fl; do
  process "$fl" &
  while [ `ps -ax | grep $(basename "$0") -c` -ge 10 ]; do sleep 0.5; done
done
