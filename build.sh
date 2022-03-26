#!/bin/bash
export LC_ALL=ru_RU.UTF-8

sleepinterval=10
eventfile='/opt/voicetech/compiled/log.txt'
compiller='/root/compileProject.sh'
allowed_branches='devel dl'

function start_build {
  cbranch=`cat $eventfile`
  rm $eventfile

  if [ `echo $allowed_branches | grep -c $cbranch` -eq 1 ]; then
    echo "= = = = = = = = = Build branch $cbranch started `date` = = = = = = = = ="
    $compiller build "$cbranch" &> /var/log/build/build_${cbranch}_$(date +%Y-%m-%d_%H-%M-%S).log
  else
    echo "Build branch $cbranch passed `date`"
    echo "[WARNING] The branch $cbranch not in allowed_branches"
  fi
}

echo "Autobuild service started at $(date)"
while [ true ]; do
  while [ `ps -ax | grep yarn | grep -v grep -c` -ne 0 ]; do
    echo "Waiting for previous build finish"
   sleep 5
  done
  if [ -f $eventfile ]; then
    start_build
  fi
 sleep $sleepinterval
done
