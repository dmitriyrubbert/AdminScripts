#!/bin/bash
# pip3 install ffmpeg-normalize

silenceLevel="-20dB"
silenceLength="0.7"
api_key='your_key'
folderid='your_folder_id'
res='result.txt'

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

function split {

  while read info; do
    local start=`echo $info | cut -d'|' -f1 | cut -d':' -f2 | xargs`
    local stop=`echo $info | cut -d'[' -f2 | cut -d':' -f2 | xargs`

    local dur=`awk "BEGIN {print $stop-$start+0.7}"`
    local start=`awk "BEGIN {print $start-0.35}"`
    local dur=${dur/,/.}
    local start=${start/,/.}

    if [ `echo $dur | grep '-' -c` -ne 0 ];   then local dur=0; fi
    if [ `echo $start | grep '-' -c` -ne 0 ]; then local start=0; fi

    if [ "$dur" != "0" ]; then
        fl="$start-$dur.wav"
        ffmpeg -y -loglevel panic -i "$1" -f wav -acodec copy -ss $start -t $dur "$fl" < /dev/null

        normalize "$fl"
        txt=$(recognize "$fl")
        if [ ! -z "$txt" ]; then
          echo "${start}c ${stop}c ${txt}"
          echo "${start}c ${stop}c ${txt}" >> "$res"
        fi
        mv "$fl" $SCRIPT_DIR/results/
    fi

  done < <( ffmpeg -i "$1" -af silencedetect=n=$silenceLevel:d=$silenceLength -f null - 2>&1 < /dev/null | \
             grep 'silence_end:\|silence_start:' | tr '\n' ' ' | sed 's/silence_end:/\nsilence_end:/g' | grep 'silence_end' | grep 'silence_start' )

}

find -name "*.wav" |  while read fl; do
  split "$fl"
done
