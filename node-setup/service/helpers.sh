#!/bin/bash

read -p "Do we want to create the validator? yes-y | n-no : " isCreateValidator

function line() {
    echo "--------------------------------------------------------------------------------"
}
function createValidator() {
    read -p "What is the validator creation rate (amount)?" creatingRate
    line
    read -p "What is the commission rate?" commissionRate
    line
    read -p "What is the commission change rate?" commissionChangeRate
    line
    read -p "What is the commission max rate?" commissionMaxRate
    line

    $DAEMON tx staking create-validator \
        --amount=$creatingRate$DENOM \
        --pubkey=$($DAEMON tendermint show-validator) \
        --moniker="$MONIKER" \
        --website $WEBSITE \
        --chain-id=$CHAIN_ID \
        --commission-rate=$commissionRate \
        --commission-max-rate=$commissionMaxRate \
        --commission-max-change-rate=$commissionChangeRate \
        --min-self-delegation="1000000" \
        --gas="auto" \
        --gas-adjustment=2.0 \
        --gas-prices="0.025$DENOM" \
        --from=$OPERATOR_KEY
}


function delegateValidator() {
    read -p "what is the operator's addresse" operatorAddress
    line
    $DAEMON q bank balances $operatorAddress
    read -p "What is the delegation amount? yes-y | n-no : " delegationAmount
    line
    $DAEMON tx staking delegate \
        $($DAEMON keys show $O_KEY --bech=val --address) \
        $delegationAmount$DENOM \
        --gas="auto" \
        --gas-adjustment=2.0 \
        --gas-prices="0.025$DENOM" \
        --chain-id $CHAIN_ID \
        --from $OPERATOR_KEY
}

function doAction() {
    read -p "Do we want to create the validator? yes-y | n-no : " isCreateValidator
    line
    if [ $isCreateValidator == yes ] || [ $isCreateValidator == y ]; then
        createValidator
    else
        echo "We are not creating the validator"
        line
    fi
    read -p "Do we want to delegate to the validator? yes-y | n-no : " isDelegateValidator
    line
    if [ $isDelegateValidator == yes ] || [ $isDelegateValidator == y ]; then
        delegateValidator
    else
        echo "We are not delegating to the validator"
        line
    fi
    read -p "Do we want to get sync settings? yes-y | n-no : " isDelegateValidator
    line
    if [ $isDelegateValidator == yes ] || [ $isDelegateValidator == y ]; then
        delegateValidator
    else
        echo "We are not delegating to the validator"
    fi

}

doAction

LAST_HEIGHT=$(wget -qO- $RPC_SERVER/commit | jq '.result.signed_header.header.height | tonumber') && \
TRUSTED_HEIGHT=$((LAST_HEIGHT-250)) && echo "trust_hash=$TRUSTED_HASH" && echo "trust_height= $TRUSTED_HEIGHT"
#
TRUSTED_HEIGHT="4372800" && \
TRUSTED_HASH=$(wget -qO- $RPC_SERVER/commit?height=$TRUSTED_HEIGHT| jq -r .result.signed_header.commit.block_id.hash) && \
echo "trust_hash=$TRUSTED_HASH" && echo "trust_height= $TRUSTED_HEIGHT" && \
dasel put int -f $CONFIG_HOME/config/config.toml .statesync.trust_height $TRUSTED_HEIGHT && \
dasel put string -f $CONFIG_HOME/config/config.toml .statesync.trust_hash $TRUSTED_HASH && \
dasel put string -f $CONFIG_HOME/config/config.toml .statesync.rpc_servers "$RPC_SERVER,$RPC_SERVER"