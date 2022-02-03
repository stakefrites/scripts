#!/bin/bash

curl -s https://raw.githubusercontent.com/Staketab/node-tools/main/logo.sh | bash

RED="\033[31m"
YELLOW="\033[33m"
GREEN="\033[32m"
NORMAL="\033[0m"
UPARROW="\U2B06\n"
DOWNARROW="\U2B07\n"

function line {
    echo "-------------------------------------------------------------------"
}
function setup {
  binary "${1}"
  sleepTime "${2}"
  rpcport "${3}"
  discordhook "${4}"
}
function binary {
  BINARY=${1}
}
function sleepTime {
  STIME=${1:-"10s"}
}
function rpcport {
  RPC_PORT=${1:-"26657"}
}

function discordhook {
  DISCORD_HOOK=${1}
}

function sendDiscord {
  if [[ ${DISCORD_HOOK} != "" ]]; then
    local discord_msg="$@"
    curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$discord_msg\"}" $DISCORD_HOOK -so /dev/null
  fi
}

function launch {
setup "${1}" "${2}" "${3}" "${4}"

line
echo -e "$GREEN Start checking Node Status... $NORMAL"
line

while true
do

POWER=$(curl -s http://localhost:${RPC_PORT}/status | jq -r ".result.validator_info.voting_power")
sleep $STIME

NEW_POWER=$(curl -s http://localhost:${RPC_PORT}/status | jq -r ".result.validator_info.voting_power")
if [ "$NEW_POWER" -eq "$POWER" ]; then
  line
  echo -e "$YELLOW No changes in Voting Power... $NORMAL"
  line
elif [ "$NEW_POWER" -gt "$POWER" ]; then
  CURRENT_VP="$((NEW_POWER - POWER))"
  echo -e "$YELLOW VP increased by:$NORMAL$GREEN $CURRENT_VP $NORMAL"
  line
  MSG=$(echo -e "${BINARY} Voting Power $(printf ${UPARROW}) by $CURRENT_VP now at $NEW_POWER")
  sendDiscord ${MSG}
elif [ "$NEW_POWER" -lt "$POWER" ]; then
  CURRENT_VP="$((NEW_POWER - POWER))"
  echo -e "$YELLOW VP decreased by:$NORMAL$GREEN $CURRENT_VP $NORMAL"
  line
  MSG=$(echo -e "${BINARY} Voting Power $(printf ${DOWNARROW}) by $CURRENT_VP now at $NEW_POWER")
  sendDiscord ${MSG}
else
  echo -e "$RED Something wrong. Exited...$NORMAL"
  exit 0
fi
done
}

while getopts ":b:s:p:d:" o; do
  case "${o}" in
    b)
      b=${OPTARG}
      ;;
    s)
      s=${OPTARG}
      ;;
    p)
      p=${OPTARG}
      ;;
    d)
      d=${OPTARG}
      ;;
  esac
done
shift $((OPTIND-1))

launch "${b}" "${s}" "${p}" "${d}"