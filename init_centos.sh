#!/bin/bash
#
#
#

set -e
set -x


# set yum repo to tsinghua
echo "set yum repo to tsinghua"
sed -e 's|^mirrorlist=|#mirrorlist=|g' \
    -e 's|^#baseurl=http://mirror.centos.org|baseurl=https://mirrors.tuna.tsinghua.edu.cn|g' \
    -i.bak \
    /etc/yum.repos.d/CentOS-*.repo

yum makecache


# install git

