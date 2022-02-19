#!/bin/bash
# pip3 install ffmpeg-normalize

api_key='your_key'
folderid='your_folder_id'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
mkdir -p $SCRIPT_DIR/results

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

find -name "*.wav" |  while read fl; do
  normalize "$fl"
  txt=$(recognize "$fl")
  if [ ! -z "$txt" ]; then
    echo "${txt}"
    echo "${txt}" >> "${fl}.txt"
  fi
done
