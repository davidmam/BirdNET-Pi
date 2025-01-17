#!/usr/bin/env bash
# Uninstall script to remove everything
#set -x # Uncomment to debug
trap 'rm -f ${TMPFILE}' EXIT
my_dir=/home/pi/BirdNET-Pi/scripts
source /etc/birdnet/birdnet.conf &> /dev/null
SCRIPTS=($(ls -1 ${my_dir}) ${HOME}/.gotty)
set -x
services=($(awk '/service/ && /systemctl/ && !/php/ {print $3}' ${my_dir}/install_services.sh | sort))

remove_services() {
  for i in "${services[@]}"; do
    if [ -L /etc/systemd/system/multi-user.target.wants/"${i}" ];then
      sudo systemctl disable --now "${i}"
    fi
    if [ -f /etc/systemd/system/"${i}" ];then
      sudo rm /etc/systemd/system/"${i}"
    fi
    if [ -d /etc/systemd/system/"${i}" ];then
      sudo rm -drf /etc/systemd/system/"${i}"
    fi
  done
  set +x
  remove_icecast
  remove_crons
}

remove_crons() {
  TMPFILE=$(mktemp)
  crontab -l | sed -e '/birdnet/,+1d' > "${TMPFILE}"
  crontab "${TMPFILE}"
}

remove_icecast() {
  if [ -f /etc/init.d/icecast2 ];then
    sudo /etc/init.d/icecast2 stop
    sudo systemctl disable --now icecast2
  fi
}

remove_scripts() {
  for i in "${SCRIPTS[@]}";do
    if [ -L "/usr/local/bin/${i}" ];then
      sudo rm -v "/usr/local/bin/${i}"
    fi
  done
}

remove_services
remove_scripts
if [ -d /etc/birdnet ];then sudo rm -drf /etc/birdnet;fi
if [ -f ${HOME}/BirdNET-Pi/birdnet.conf ];then sudo rm -f ${HOME}/BirdNET-Pi/birdnet.conf;fi
echo "Uninstall finished. Remove this directory with 'rm -drfv' to finish."
