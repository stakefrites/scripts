#!/bin/bash

read -p "Do we want to create the validator? yes-y | n-no : " isCreateValidator

function createValidator() {
    read -p "What is the validator creation rate (amount)?" creatingRate
    read -p "What is the commission rate?" commissionRate
    read -p "What is the commission change rate?" commissionChangeRate
    read -p "What is the commission max rate?" commissionMaxRate

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
    $DAEMON q bank balances $operatorAddress
    read -p "What is the delegation amount? yes-y | n-no : " delegationAmount
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
    if [ $isCreateValidator == yes ] || [ $isCreateValidator == y ]; then
        createValidator
    else
        echo "We are not creating the validator"
    fi
    read -p "Do we want to delegate to the validator? yes-y | n-no : " isDelegateValidator
    if [ $isDelegateValidator == yes ] || [ $isDelegateValidator == y ]; then
        delegateValidator
    else
        echo "We are not delegating to the validator"
    fi

}

doAction