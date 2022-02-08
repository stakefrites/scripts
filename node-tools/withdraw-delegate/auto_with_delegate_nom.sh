#!/bin/bash

curl -s https://raw.githubusercontent.com/Staketab/node-tools/main/logo.sh | bash

RED="\033[31m"
YELLOW="\033[33m"
GREEN="\033[32m"
NORMAL="\033[0m"

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
  STIME=${1:-"60m"}
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

COIN="unom"
echo -e "$GREEN Enter Fees in ${COIN}.$NORMAL"
read -p "Fees: " FEES
FEE=${FEES}${COIN}
VALIDATOR_ADDR=$(nomic balance | grep "address:" | cut -d" " -f2)
CHAIN=$(${BINARY} status --node http://localhost:${RPC_PORT} 2>&1 | jq -r .NodeInfo.network)

echo "-------------------------------------------------------------------"
echo -e "$YELLOW Check you Validator data: $NORMAL"
echo -e "$GREEN Valoper: $VALIDATOR_ADDR $NORMAL"
echo -e "$GREEN Chain: $CHAIN $NORMAL"
echo -e "$GREEN Coin: $COIN $NORMAL"
echo -e "$GREEN Sleep Time: $STIME $NORMAL"
echo "-------------------------------------------------------------------"
echo -e "$YELLOW If your Data is right type$RED yes$NORMAL.$NORMAL"
echo -e "$YELLOW If your Data is wrong type$RED no$NORMAL$YELLOW and check it.$NORMAL $NORMAL"
read -p "Your answer: " ANSWER

if [ "$ANSWER" == "yes" ]; then
    while true
    do
    echo "-------------------------------------------------------------------"
    echo -e "$RED$(date +%F-%H-%M-%S)$NORMAL $YELLOW Withdraw commission and rewards $NORMAL"
    echo "-------------------------------------------------------------------"
    echo nomic claim | grep "raw_log\|txhash"

    sleep 1m

    AMOUNT=$(nomic balance | grep "balance:" | cut -d" " -f2)
    DELEGATE=$((AMOUNT - 1000000))

    if [[ $DELEGATE > 0 && $DELEGATE != "null" ]]; then
        echo "-------------------------------------------------------------------"
        echo -e "$RED$(date +%F-%H-%M-%S)$NORMAL $YELLOW Stake ${DELEGATE} ${COIN} $NORMAL"
        echo "-------------------------------------------------------------------"
        echo ""
        echo "Delegate Before:"
        nomic delegations
        echo ""
        nomic delegate ${VALIDATOR_ADDR} ${DELEGATE}
        sleep 30s
        echo "-------------------------------------------------------------------"
        echo -e "$GREEN Balance after delegation:$NORMAL"
        echo ""
        echo "Delegate After:"
        nomic delegations
        AMOUNT=$(nomic balance | grep "balance:" | cut -d" " -f2)

        MSG=$(echo -e "${BINARY} | $(date +%F-%H-%M-%S) | Delegated: ${DELEGATE} ${COIN} | Balance after delegation: ${AMOUNT} ${COIN}")
        sendDiscord ${MSG}
    else
        MSG=$(echo -e "${BINARY} | $(date +%F-%H-%M-%S) | Insufficient balance for delegation")
        sendDiscord ${MSG}
        echo "-------------------------------------------------------------------"
        echo -e "$RED Insufficient balance for delegation $NORMAL"
        echo "-------------------------------------------------------------------"
    fi
        echo "-------------------------------------------------------------------"
        echo -e "$GREEN Sleep for ${STIME} $NORMAL"
        echo "-------------------------------------------------------------------"
        sleep ${STIME}
    done
elif [ "$ANSWER" == "no" ]; then
    echo -e "$RED Exited...$NORMAL"
    exit 0
else
    echo -e "$RED Answer wrong. Exited...$NORMAL"
    exit 0
fi
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