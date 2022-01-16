#!/bin/bash

read -p "Are we using the chain registry? yes-y | n-no : " isChainRegistry

if [isChainRegistry == yes || isChainRegistry == y]; then
    echo "We are using the chain registry"
    setupChainRepo
    chooseChain
    setRequirements
fi