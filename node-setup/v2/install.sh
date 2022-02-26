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
  discordHook=$(jq -r ".discord_hook" "$configFile")
  #system
  systemVolume=$(jq -r ".node_info.volume" "$configFile")
  languageName=$(jq -r ".system.language.name" "$configFile")
  languageVersion=$(jq -r ".system.language.version" "$configFile")
  # node_info
  nodeType=$(jq -r ".node_info.type" "$configFile")
  nodeWebsite=$(jq -r ".node_info.website" "$configFile")
  nodeMoniker=$(jq -r ".node_info.moniker" "$configFile")
  nodeIdentity=$(jq -r ".node_info.identity" "$configFile")
  # sync
  syncType=$(jq -r ".sync.type" "$configFile")
  syncTrusted_rpc=$(jq -r ".sync.trusted_rpc" "$configFile")
  syncSnapshot_url=$(jq -r ".sync.trusted_rpc" "$configFile")
  # user
  countUser=$(jq -r ".users | length" "$configFile")
  counterUser=0
  while [[ "$counterUser" -lt "$countUser" ]]; do
    userName=$(jq -r ".users[$counterUser].name" "$configFile")
    userSSH=$(jq -r ".users[$counterUser].ssh" "$configFile")
    # insert cmd to create a user here
    counterUser=$((counterUser + 1))
  done
  # monitoring
  # stake_net
}

function line {
  echo "-------------------------------------------------------------------"
}

function checkSudo() {
  echo -e "$YELLOW [*] Validating root permissions $NORMAL"
  line
  if [[ $EUID -ne 0 ]]; then
    echo -e "$RED [x] This script must be run as root... Configuration need root priv... Quitting! $NORMAL"
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
  sudo apt install gcc make chrony git build-essential ufw curl jq snapd wget liblz4-tool aria2 pixz pigz net-tools libssl-dev pkg-config clang httpie -y
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

function setupLatestRust() {
    echo "[*] Setting rust..."
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    rustup default nightly
}

