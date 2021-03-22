#!/bin/bash
########################
#   安装基础docker容器   #
########################

source ~/.bashrc > /dev/null 
set -e

read -p "Enter your UID (or default $(id -u)): " D_PUID
D_PUID="${D_PUID:-$(id -u)}"
echo "D_PUID: ${D_PUID}"

read -p "Enter your GID (or default $(id -g)): " D_PGID
D_PGID="${D_PGID:-$(id -g)}"
echo "D_PGID: ${D_PGID}"

read -p "Enter volume base path (or default .): " D_VOLUME_BASE
D_VOLUME_BASE="${D_VOLUME_BASE:-"."}"
echo "D_VOLUME_BASE: ${D_VOLUME_BASE}"

read -p "Enter jellyfin Movie path (or default ./movies): " D_VOLUME_MOVIE
D_VOLUME_MOVIE="${D_VOLUME_MOVIE:-"./movies"}"
echo "D_VOLUME_MOVIE: $D_VOLUME_MOVIE"

read -p "Enter jellyfin Tv path (or default ./tvshows): " D_VOLUME_TV
D_VOLUME_TV="${D_VOLUME_TV:-"./tvshows"}"
echo "D_VOLUME_TV: ${D_VOLUME_TV}"

read -s -p "Enter aria2 rpc secret (or default abcdefghijklmn): " D_ARIA_RPC_SECRET
echo
D_ARIA_RPC_SECRET="${D_ARIA_RPC_SECRET:-"abcdefghijklmn"}"
if [[ $D_ARIA_RPC_SECRET != "abcdefghijklmn" ]]; then
    read -s -p "Re-Enter aria2 rpc secret: " D_ARIA_RPC_SECRET_2
    echo
    if [[ $D_ARIA_RPC_SECRET != $D_ARIA_RPC_SECRET_2 ]]; then
        echo "Two inputs are inconsistent"
        exit 1
    fi
fi

read -s -p "Enter ssh key (or default abcdefghijklmn): " D_SSHW_KEY
echo
D_SSHW_KEY="${D_SSHW_KEY:-"abcdefghijklmn"}"
if [[ $D_SSHW_KEY != "abcdefghijklmn" ]]; then
    read -s -p "Re-Enter ssh key: " D_SSHW_KEY_2
    echo
    if [[ $D_SSHW_KEY != $D_SSHW_KEY_2 ]]; then
        echo "Two inputs are inconsistent"
        exit 2
    fi
fi

echo "Enter key is allow signups (true or default false)"
read -p "Please note that first needed be true to admin signup: " D_KEY_SIG
D_KEY_SIG="${D_KEY_SIG:-"false"}"
echo "D_KEY_SIG: ${D_KEY_SIG}"

read -p "Enter network is external (false or default true): " D_NETWROK_EXTERNAL
D_NETWROK_EXTERNAL="${D_NETWROK_EXTERNAL:-"true"}"
echo "D_NETWROK_EXTERNAL: ${D_NETWROK_EXTERNAL}"

read -p "Enter network name (or default my-net): " D_NETWROK_NAME
D_NETWROK_NAME="${D_NETWROK_NAME:-"my-net"}"
echo "D_NETWROK_NAME: ${D_NETWROK_NAME}"


[[ ! -f .env ]] && touch .env
echo "D_PUID=${D_PUID}" > .env
echo "D_PGID=${D_PGID}" >> .env
echo "D_VOLUME_BASE=${D_VOLUME_BASE}" >> .env
echo "D_VOLUME_MOVIE=${D_VOLUME_MOVIE}" >> .env
echo "D_VOLUME_TV=${D_VOLUME_TV}" >> .env
echo "D_ARIA_RPC_SECRET=${D_ARIA_RPC_SECRET}" >> .env
echo "D_SSHW_KEY=${D_SSHW_KEY}" >> .env
echo "D_KEY_SIG=${D_KEY_SIG}" >> .env
echo "D_NETWROK_EXTERNAL=${D_NETWROK_EXTERNAL}" >> .env
echo "D_NETWROK_NAME=${D_NETWROK_NAME}" >> .env