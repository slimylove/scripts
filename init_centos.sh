#!/bin/bash
#
#
#

source ~/.bashrc > /dev/null
set -e
set -x

readonly SCRIPT_DIR=$(cd "$(dirname "$0")";pwd)
readonly SCRIPT_USER="${SUDO_USER:$(id -un)}"
readonly SCRIPT_USER_HOME="$(cat /etc/passwd | grep ^${SCRIPT_USER}: | cut -d: -f 6)"
readonly GIT_VERSION="2.28.0"
readonly TMUX_VERSION="2.8"

_exists() {
  cmd="$1"
  if [ -z "$cmd" ]; then
    _usage "Usage: _exists cmd"
    return 1
  fi

  if eval type type >/dev/null 2>&1; then
    eval type "$cmd" >/dev/null 2>&1
  elif command >/dev/null 2>&1; then
    command -v "$cmd" >/dev/null 2>&1
  else
    which "$cmd" >/dev/null 2>&1
  fi
  ret="$?"
  printf "$cmd exists=$ret\n"
  return $ret
}

_check_network() {
    ping -c 1 mirrors.tuna.tsinghua.edu.cn >/dev/null 2>&1 && ping -c 1  www.baidu.com >/dev/null 2>&1

    [[ $? -eq 0 ]] && echo "网络检测正常" || (echo "网络检测异常" && exit -1)
}

_check_yum() {
    # set yum repo to tsinghua
    yum repolist -v | grep "mirrors.tuna.tsinghua.edu.cn" > /dev/null 2>&1 \
    || (
        sed -e 's|^mirrorlist=|#mirrorlist=|g' \
            -e 's|^#baseurl=http://mirror.centos.org|baseurl=https://mirrors.tuna.tsinghua.edu.cn|g' \
            -i.bak \
            /etc/yum.repos.d/CentOS-*.repo \
        && yum clean all \
        && yum makecache
    )
}

install_base() {
    _check_network && _check_yum

    yum install -y wget vim
}

install_git() {
    _exists git && git --version | grep ${GIT_VERSION} \
    && printf "git(${GIT_VERSION}) is already installed\n" && return

    # check network and yum
    printf "check network and yum\n"
    _check_network && _check_yum
    
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
    cd $SCRIPT_DIR
    wget https://mirrors.edge.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.gz

    # install git
    printf "install git\n"
    tar -zxvf git-${GIT_VERSION}.tar.gz && cd git-${GIT_VERSION} \
    && ./configure --prefix=/usr/local/git all \
    && make \
    && make install

    # export git to PATH
    printf "export git to PATH\n"
    echo $PATH | grep '/usr/local/git/bin' \
    || tee -a /etc/bashrc <<< 'export PATH=/usr/local/git/bin:$PATH'

    # check git version
    printf "check git version\n"
    source /etc/bashrc > /dev/null 2>&1
    (_exists git && git --version | grep ${GIT_VERSION}) \
    && echo "git install ok" \
    || echo "git install fail"
}


function install_tmux() {
    _exists tmux && tmux -V | grep ${TMUX_VERSION} \
    && printf "tmux(${TMUX_VERSION}) is already installed\n" && return

    # check network and yum
    printf "check network and yum\n"
    _check_network && _check_yum
    
    # install depend
    printf "install depend\n"
    yum install -y gcc kernel-devel make ncurses-devel curl

    # make install libevent
    printf "make install libevent\n"
    cd $SCRIPT_DIR \
    && curl -LOk https://github.com/libevent/libevent/releases/download/release-2.1.8-stable/libevent-2.1.8-stable.tar.gz \
    && tar -xf libevent-2.1.8-stable.tar.gz \
    && cd libevent-2.1.8-stable \
    && ./configure --prefix=/usr/local \
    && make \
    && make install

    # make install tmux
    printf "make install tmux\n"
    cd $SCRIPT_DIR \
    && curl -LOk https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz \
    && tar -xf tmux-${TMUX_VERSION}.tar.gz \
    && cd tmux-${TMUX_VERSION} \
    && LDFLAGS="-L/usr/local/lib -Wl,-rpath=/usr/local/lib" ./configure --prefix=/usr/local/tmux \
    && make \
    && make install

    # export tmux to PATH
    printf "export tmux to PATH\n"
    echo $PATH | grep '/usr/local/tmux/bin' \
    || tee -a /etc/bashrc <<< 'export PATH=/usr/local/tmux/bin:$PATH'

    # check tmux version
    printf "check tmux version\n"
    source /etc/bashrc > /dev/null 2>&1
    (_exists tmux && tmux -V | grep ${TMUX_VERSION}) \
    && echo "tmux install ok" \
    || echo "tmux install fail"
}

install_docker() {
    _exists docker && docker -v \
    && printf "$(docker -v) is already installed\n" && return

    # check network and yum
    printf "check network and yum\n"
    _check_network && _check_yum

    # install depend
    printf "install depend\n"
    yum install -y yum-utils device-mapper-persistent-data lvm2

    # config docker repo
    printf "config docker repo\n"
    yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo \
    && yum makecache fast

    # install docker-ce
    printf "install docker-ce\n"
    echo yes | yum install -y docker-ce

    # add user to docker group
    printf "add user to docker group\n"
    usermod -aG docker ${SCRIPT_USER}

    # add registry-mirror
    printf "add registry-mirror\n"
    [[ ! -d /etc/docker/daemon.json ]] && mkdir /etc/docker \
    && [[ ! -f /etc/docker/daemon.json ]] && touch /etc/docker/daemon.json \
    && echo '{
  "registry-mirrors": [ "https://pee6w651.mirror.aliyuncs.com", "https://bjtzu1jb.mirror.aliyuncs.com", "https://9cpn8tt6.mirror.aliyuncs.com"]
}' > /etc/docker/daemon.json

    # add docker service to start
    printf "add docker service to start\n"
    systemctl enable docker && systemctl start docker

    # check docker version
    printf "chekc docker version\n"
    (_exists docker && docker -v > /dev/null 2>&1) \
    && echo "docker($(docker -v)) install ok" \
    || echo "docker install fail"
}

install_all() {
    install_base \
    && install_git \
    && install_tmux \
    && install_docker
}

main() {
    "$@"
}

main "$@"

