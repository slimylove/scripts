#!/bin/bash

set -e
set -x

# install depend
yum install -y zlib-devel bzip2-devel openssl-devel ncurses-devel gcc perl-ExtUtils-MakeMaker \
    package curl-devel expat-devel gettext-devel


# remove git
yum remove -y git


# download git tar
wget https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.28.0.tar.gz



# install git
tar -zxvf git-2.28.0.tar.gz && cd git-2.28.0 \
    && ./configure --prefix=/usr/local/git all \
    && make \
    && make install


# export git to PATH
tee -a /etc/bashrc <<< "export PATH=$PATH:/usr/local/git/bin"


# check
source /etc/bashrc
git --version | tee


