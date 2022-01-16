#!/bin/bash

read -p "Do we want to create the validator? yes-y | n-no : " isCreateValidator

function createValidator() {
    read -p "What is the operator key's name ?" operatorKey
    read -p "What is the commission rate?" commissionRate
    read -p "What is the commission change rate?" commissionChangeRate
    read -p "What is the commission max rate?" commissionMaxRate

    $DAEMON tx staking create-validator \
        --amount=1000000000000$DENOM \
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
        --from=$operatorKey
}