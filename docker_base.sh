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

read -p "Enter "
echo $D_VOLUME_BASE

