#!/bin/bash

RED="\033[31m"
YELLOW="\033[33m"
GREEN="\033[32m"
NORMAL="\033[0m"
UPARROW="\U2B06\n"
DOWNARROW="\U2B07\n"

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
configFile="$DIR/config.json"
profileFile="mateo-var.sh"

function getVar() {
  goVersion=$(jq -r '.goversion' "$configFile")
}

function line {
  echo "-------------------------------------------------------------------"
}

function checkSudo() {
  echo "[*] Validating root permissions"
  line
  if [[ $EUID -ne 0 ]]; then
    echo "[x] This script must be run as root... Configuration need root priv... Quitting!"
    line
    exit 1
  fi
}

line
echo -e "$GREEN Install Requirements $NORMAL"
line

function setRequirements() {
  sudo apt-get update
  sudo apt-get upgrade -y
  sudo apt-get dist-upgrade -y
  sudo apt-get clean all
  sudo apt-get autoremove -y
  sudo apt install gcc make chrony git build-essential ufw curl jq snapd wget liblz4-tool aria2 pixz pigz net-tools libssl-dev pkg-config clang -y
}

function sendDiscord {
  if [[ ${DISCORD_HOOK} != "" ]]; then
    local discord_msg="$@"
    curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$discord_msg\"}" $DISCORD_HOOK -so /dev/null
  fi
}

line
echo -e "$GREEN Install et setup GO $NORMAL"
line

function setupLatestGO() {
  wget https://go.dev/dl/go"$goVersion".linux-amd64.tar.gz
  # check if old go is already there
  if [ -d "/usr/local/go" ]; then
    rm -rf /usr/local/go
  fi
  tar -C /usr/local -xzf go"$goVersion".linux-amd64.tar.gz
  rm go"$goVersion".linux-amd64.tar.gz
  # Set GOPATH
  touch /etc/profile.d/$profileFile
  GOBIN="\$HOME/go/bin"
  GOROOT="\$HOME/go"
  {
    echo "export GO111MODULE=on"
    echo "export GOPATH=\$HOME/go"
    echo "export GOBIN=$GOBIN"
    echo "export PATH=$GOBIN:$GOROOT:/usr/local/go/bin:$PATH"
  } >>/etc/profile.d/$profileFile
  echo "export PATH=/usr/local/go/bin:$PATH" >>/root/.bashrc
}
