#!/bin/bash

cat >/etc/yum.repos.d/sngrep.repo <<EOL
[irontec]
name=Irontec RPMs repository
baseurl=http://packages.irontec.com/centos/\$releasever/\$basearch/
EOL
rpm --import http://packages.irontec.com/public.key
yum update
yum install sngrep -y
