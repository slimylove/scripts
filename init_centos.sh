#!/bin/bash
#######################
# 初始化安装centos的脚本
#######################

source ~/.bashrc > /dev/null

readonly SCRIPT_DIR=$(cd "$(dirname "$0")";pwd)
readonly SCRIPT_USER="${SUDO_USER:-$(id -un)}"
readonly SCRIPT_USER_HOME="$(cat /etc/passwd | grep ^${SCRIPT_USER}: | cut -d: -f 6)"
readonly GIT_VERSION="${GIT_VERSION:-"2.28.0"}"
readonly TMUX_VERSION="${TMUX_VERSION:-"2.8"}"
readonly DOCKER_COMPOSE_VERSION="${DOCKER_COMPOSE_VERSION:-"1.28.5"}"

# 判断是否通过外部ssh登陆，否则为1
__INTERACTIVE=""
if [[ -t 1 ]]; then
  __INTERACTIVE="1"
fi

__green() {
  if [[ "${__INTERACTIVE}" = "1" ]]; then
    printf '\033[1;32m%b\033[0m' "$1"
    return
  fi
  printf -- "%b" "$1"
}

__red() {
  if [[ "${__INTERACTIVE}" = "1" ]]; then
    printf '\033[1;31m%b\033[0m' "$1"
    return
  fi
  printf -- "%b" "$1"
}

_err() {
  printf -- "%s" "[$(date)] " >&2
  if [ -z "$2" ]; then
    __red "$1" >&2
  else
    __red "$1='$2'" >&2
  fi
  printf "\n" >&2
}

_info() {
  printf -- "%s" "[$(date)] "
  if [ -z "$2" ]; then
    __green "$1"
  else
    __green "$1='$2'"
  fi
  printf "\n"
}

_exists() {
  cmd="$1"
  if [[ -z "$cmd" ]]; then
    _err "Usage: _exists cmd"
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
  _info "$cmd exists=$ret"
  return $ret
}

_judge() {
  if [[ 0 -eq $? ]]; then
    _info "[OK] $1 完成"
    sleep 1
  else
    _err "[错误] $1 失败"
    exit 1
  fi
}

_check_network() {
  ping -c 1 mirrors.tuna.tsinghua.edu.cn >/dev/null 2>&1 && ping -c 1  www.baidu.com >/dev/null 2>&1

  [[ $? -eq 0 ]] && _info "网络检测正常" || (_err "网络检测异常" && exit -1)
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

  [[ $? -eq 0 ]] && _info "yum check ok" || (_err "yum check fail" && exit -1)
}

_fast_github_release() {
  github_release_url="$1"
  if [[ -z "${github_release_url}" ]]; then
    _err "Usage: _exists github_release_url"
    return 1
  fi

  # https://github.com/hunshcn/gh-proxy
  if ping -c 1 https://gh.api.99988866.xyz > /dev/null 2>&1; then
    _info "https://gh.api.99988866.xyz/${github_release_url}"
  # https://github.com/fhefh2015/Fast-GitHub
  elif ping -c 1 github.91chifun.workers.dev > /dev/null 2>&1; then
    _info "https://github.91chifun.workers.dev/${github_release_url}"
  else
    _err "fast github release fail, use github origin url"
    _err "${github_release_url}"
    return 2
  fi
}

install_base() {
  _check_network && _check_yum

  yum install -y wget vim

  _judge "base安装"
}

install_git() {
  _exists git && git --version | grep ${GIT_VERSION} \
  && _info "git(${GIT_VERSION}) is already installed" && return

  # check network and yum
  _info "check network and yum"
  _check_network && _check_yum
  
  # install depend
  _info "install depend"
  yum install -y zlib-devel bzip2-devel openssl-devel ncurses-devel \
    gcc perl-ExtUtils-MakeMaker \
    package curl-devel expat-devel gettext-devel \
    wget

  # remove git
  _info "remove yum git"
  yum remove -y git

  # download git tar
  _info "download git tar"
  cd $SCRIPT_DIR
  wget https://mirrors.edge.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.gz

  # install git
  _info "install git"
  tar -zxvf git-${GIT_VERSION}.tar.gz && cd git-${GIT_VERSION} \
  && ./configure --prefix=/usr/local/git all \
  && make \
  && make install

  # export git to PATH
  _info "export git to PATH"
  echo $PATH | grep '/usr/local/git/bin' \
  || tee -a /etc/bashrc <<< 'export PATH=/usr/local/git/bin:$PATH'

  # check git version
  _info "check git version"
  source /etc/bashrc > /dev/null 2>&1
  _exists git && git --version | grep ${GIT_VERSION}
  _judge "git安装"
}


install_tmux() {
  _exists tmux && tmux -V | grep ${TMUX_VERSION} \
  && _info "tmux(${TMUX_VERSION}) is already installed" && return

  # check network and yum
  _info "check network and yum"
  _check_network && _check_yum
  
  # install depend
  _info "install depend"
  yum install -y gcc kernel-devel make ncurses-devel curl

  # make install libevent
  _info "make install libevent"
  cd $SCRIPT_DIR \
  && curl -LOk $(_fast_github_release https://github.com/libevent/libevent/releases/download/release-2.1.8-stable/libevent-2.1.8-stable.tar.gz) \
  && tar -xf libevent-2.1.8-stable.tar.gz \
  && cd libevent-2.1.8-stable \
  && ./configure --prefix=/usr/local \
  && make \
  && make install

  # make install tmux
  _info "make install tmux"
  cd $SCRIPT_DIR \
  && curl -LOk $(_fast_github_release https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz) \
  && tar -xf tmux-${TMUX_VERSION}.tar.gz \
  && cd tmux-${TMUX_VERSION} \
  && LDFLAGS="-L/usr/local/lib -Wl,-rpath=/usr/local/lib" ./configure --prefix=/usr/local/tmux \
  && make \
  && make install

  # export tmux to PATH
  _info "export tmux to PATH"
  echo $PATH | grep '/usr/local/tmux/bin' \
  || tee -a /etc/bashrc <<< 'export PATH=/usr/local/tmux/bin:$PATH'

  # check tmux version
  _info "check tmux version"
  source /etc/bashrc > /dev/null 2>&1
  _exists tmux && tmux -V | grep ${TMUX_VERSION}
  _judge "tmux安装"
}

install_docker() {
  _exists docker && docker -v \
  && _info "$(docker -v) is already installed" && return

  # check network and yum
  _info "check network and yum"
  _check_network && _check_yum

  # install depend
  _info "install depend"
  yum install -y yum-utils device-mapper-persistent-data lvm2

  # config docker repo
  _info "config docker repo"
  yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo \
  && yum makecache fast

  # install docker-ce
  _info "install docker-ce"
  echo yes | yum install -y docker-ce

  # add user to docker group
  _info "add user to docker group"
  usermod -aG docker ${SCRIPT_USER}

  # add registry-mirror
  _info "add registry-mirror"
  [[ ! -d /etc/docker/daemon.json ]] && mkdir /etc/docker \
  && [[ ! -f /etc/docker/daemon.json ]] && touch /etc/docker/daemon.json \
  && echo '{
"registry-mirrors": [ "https://pee6w651.mirror.aliyuncs.com", "https://bjtzu1jb.mirror.aliyuncs.com", "https://9cpn8tt6.mirror.aliyuncs.com"]
}' > /etc/docker/daemon.json

  # add docker service to start
  _info "add docker service to start"
  systemctl enable docker && systemctl start docker

  # check docker version
  _info "chekc docker version"
  _exists docker && docker -v > /dev/null 2>&1
  _judge "docker安装"
}

install_docker_compose() {
  _exists docker-compose && docker-compose --version \
  && _info "$(docker-compose --version) is already installed" && return

  # download
  _info "download docker-compose"
  curl -L $(_fast_github_release "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)") \
    -o /usr/local/bin/docker-compose

  # add +x
  _info "add +x to docker-compose"
  chmod +x /usr/local/bin/docker-compose

  # ln -s
  _info "ln -s to /usr/bin"
  ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

  # check version
  _info "check version"
  _exists docker-compose && docker-compose --version > /dev/null 2>&1
  _judge "docker-compose安装"
}

install_all() {
    install_base \
    && install_git \
    && install_tmux \
    && install_docker \
    && install_docker_compose
}

show_help() {
  echo "this is a help message, but nothing show below"
}

main() {
    case "$1" in
    all)
      install_all
      ;;
    git)
      install_git
      ;;
    base)
      install_base
      ;;
    tmux)
      install_tmux
      ;;
    docker)
      install_docker_compose
      ;;
    docker-compose)
      install_docker_compose
      ;;
    *)
      show_help
    esac
}

main "$@"

