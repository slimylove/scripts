#!/bin/bash

set -e
set -x

# install depend
printf "install depend\n"
yum install -y zlib-devel bzip2-devel openssl-devel ncurses-devel \
    gcc perl-ExtUtils-MakeMaker \
    package curl-devel expat-devel gettext-devel \
    wget


# remove git
printf "remove yum git\n"
yum remove -y git


# download git tar
printf "download git tar\n"
wget https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.28.0.tar.gz



# install git
printf "install git\n"
tar -zxvf git-2.28.0.tar.gz && cd git-2.28.0 \
    && ./configure --prefix=/usr/local/git all \
    && make \
    && make install


# export git to PATH
printf "export git to PATH\n"
tee -a /etc/bashrc <<< "export PATH=$PATH:/usr/local/git/bin"


# check git version
printf "check git version\n"
source /etc/bashrc
git --version | tee


