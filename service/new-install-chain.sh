#!/bin/bash

# evmos, akash, chihuaha, lum network, osmosis, desmos, cosmos

# https://github.com/cosmos/chain-registry

# check if go dir exist
if [ ! -d "$HOME/go" ]; then
    mkdir go
fi

myChainReg="chain-registry"
# current script dir
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function setupChainRegistry() {
    mkdir temp
    cd temp
    git clone https://github.com/cosmos/chain-registry.git
    cd $DIR
    ## Choosing the chain
    echo "Choosing the chain"
    chainFolder="$DIR/temp/chain-registry"
    unset options i
    while IFS= read -r -d $'\0' f; do
        options[i++]="$f"
    done < <(find "$chainFolder" -maxdepth 1 -type d -print0)

    select opt in "${options[@]}" "Stop the script"; do
    case $opt in
    *)
      echo ""
      echo "Your data source will be: $opt"
      myChain=$(basename "$opt")
      break
      ;;
    "Stop the script")
      echo "[-] You chose to quit."
      break
      ;;
    *)
      echo ""
      echo "[-] You choice is not valid."
      ;;
    esac
  done
  echo "$myChainReg"
  mv "$chainFolder/$myChain" "$DIR/$myChainReg"
  mv "$chainFolder/assetlist.schema.json" "$DIR/$myChainReg/assetlist.schema.json"
  mv "$chainFolder/chain.schema.json" "$DIR/$myChainReg/chain.schema.json"
  rm -rf "$chainFolder"
}


function setRequirements() {
    echo ""
    echo "[*] Installing Dasel"
    go install github.com/tomwright/dasel/cmd/dasel@master
}

function setRegistryVar() {
    setupChainRegistry
    genesisUrl=$(dasel select -p json -f "$DIR/$myChainReg/chain.json" ".genesis.genesis_url")
    rpcServer=$(dasel select -p json -f "$DIR/$myChainReg/chain.json" ".apis.rpc[0].address")
    githubUrl=$(dasel select -p json -f "$DIR/$myChainReg/chain.json" ".codebase.git_repo")
    version=$(dasel select -p json -f "$DIR/$myChainReg/chain.json" ".codebase.recommended_version")
    peers=$(dasel -p json -f "$DIR/$myChainReg/chain.json" -m --format '{{selectMultiple ".seeds.[*]" | format "{{select \".id\" }}@{{select \".address\" }}{{ if not isLast }},{{ end }}" }}' ".peers")
    chainIDvar=$(jq ".chain_id" "$DIR/$myChainReg/chain.json")
    daemonVAR=$(jq ".daemon_name" "$DIR/$myChainReg/chain.json")
    nodeHomeVAR=$(jq ".node_home" "$DIR/$myChainReg/chain.json")
    {
        echo "export CHAIN_ID=$chainIDvar"
        echo "export PEERS=$peers"
        echo "export GENESIS_URL=$genesisUrl"
        echo "export GIT_REPO=$githubUrl"
        echo "export VERSION=$version"
        echo "export DAEMON=$daemonVAR"
        echo "export CONFIG_HOME=$nodeHomeVAR"
        echo "export RPC_SERVER=$rpcServer"
        echo "export RPC_SERVER_LIST=$rpcServer,$rpcServer"
    } >> "$HOME/.bashrc"
}

function SetManualVar() {
    read -p "What is the chain ID : " chainIDvar
    read -p "What is the daemon name : " daemonVAR
    read -p "What is the node home : " nodeHomeVAR
    read -p "What is the gitrepo url : " gitRepo
    read -p "What is the recommended version : " version
    read -p "What is the genesis.json url (RAW) : " genesisUrl
    read -p "What is the RPC server we trust : " RPC_SERVER
    read -p "Please paste the peers list : " peers
    {
        echo "export CHAIN_ID=$chainIDvar"
        echo "export PEERS=$peers"
        echo "export DAEMON=$daemonVAR"
        echo "export CONFIG_HOME=$nodeHomeVAR"
        echo "export GIT_REPO=$gitRepo"
        echo "export VERSION=$version"
        echo "export RPC_SERVER=$RPC_SERVER"
        echo "export RPC_SERVER_LIST=$RPC_SERVER,$RPC_SERVER"
        echo "export GENESIS_URL='$genesisUrl'"
    } >> "$HOME/.bashrc"
}

function setVariables() {
    {
        echo "export MONIKER='Stake Frites'"
        echo "export WEBSITE='https://stakefrites.co'"
        echo "export DESCRIPTION='PoS Validators & Web3 developpers'"
        echo "export identity='7817CA2B0981F769'"
        echo "export OPERATOR_KEY='mateo"
    } >> "$HOME/.bashrc"
    read -p "Are we using the chain registry? yes-y | n-no : " isChainRegistry
    if [ $isChainRegistry == yes ] || [ $isChainRegistry == y ]; then
        echo "We are using the chain registry"
        SetRegistryVar
    else 
        echo "We need some information to continue"
        SetManualVar
    fi
    source "$HOME/.bashrc"
}

function createKeys() {
    echo "CREATING THE OPERATOR KEY....."
    read -p "Do we need to import an existing key? (y/n) : " isRecover
    if [ $isRecover == y ] || [ $isRecover == yes ]; then
        $DAEMON keys add "$OPERATOR_KEY" --recover
    else
        $DAEMON keys add "$OPERATOR_KEY"
    fi
}

function initNode() {
    echo "INITIALIZING THE NODE....."
    $DAEMON init "$MONIKER" --chain-id $CHAIN_ID
}

function downloadGenesis() {
    echo "GETTING THE GENESIS FILE....."
    wget $GENESIS_URL > $CONFIG_HOME/config/genesis.json
}

function installBinaries() {
    git clone "$GIT_REPO.git"
    gitName=$(basename "$GIT_REPO")
    cd "$gitName"
    git checkout "$VERSION"
    make install
}

function showNodeId() {
    echo "Here is the node's id for sentry/validator config....."
    echo $($DAEMON tendermint show-node-id)
}


function queryRPC() {
    echo "Querying the RPC server....."
    LAST_HEIGHT=$(wget -qO- $RPC_SERVER/commit | jq '.result.signed_header.header.height | tonumber')
    TRUSTED_HEIGHT=$((LAST_HEIGHT-250))
    TRUSTED_HASH=$(wget -qO- $RPC_SERVER/commit?height=$TRUSTED_HEIGHT| jq .result.signed_header.commit.block_id.hash)
    echo "trust_hash=$TRUSTED_HASH"
    echo "trust_height= $TRUSTED_HEIGHT"
    dasel put int -f $HOME/.desmos/config/config.toml .statesync.trust_height $TRUSTED_HEIGHT
    dasel put string -f $HOME/.desmos/config/config.toml .statesync.trust_hash $TRUSTED_HASH
    dasel put string -f $HOME/.desmos/config/config.toml .statesync.rpc_servers "$RPC_SERVER,$RPC_SERVER"
}

function setPeerSettings() {
    echo "We are setting up the peer settings....."
    read -p "What type of node are we setting up? sentry-s | v-validator | a-archive: " nodeType
    if [ $nodeType == sentry ] || [ $nodeType == s ]; then
        echo "We are setting up a sentry node....."
        dasel put bool -f $HOME/.desmos/config/config.toml .p2p.pex true
        dasel put bool -f $HOME/.desmos/config/config.toml .p2p.addr_book_strict false
    elif [ $nodeType == validator ] || [ $nodeType == v ]; then
        echo "We are setting up a validator node....."
        dasel put bool -f $HOME/.desmos/config/config.toml .p2p.pex false
        dasel put bool -f $HOME/.desmos/config/config.toml .p2p.addr_book_strict false
    else
        echo "We are setting up an archive node....."
    fi
}

function syncNode() {
    read -p "What type of sync are we doig? statesync-s | snapshot-snap | genesis-g : " syncType
     if [ $syncType == statesync ] || [ $syncType == s ]; then
        echo "We are state syncing"
        queryRPC
    elif [ $syncType == snapshot ] || [ $syncType == snap ]; then
        echo "We will download the snapshot"
    else 
        echo "We are not syncing"
    fi
}

function cleanUp() {
    rm -rf temp
}



function doAction() {
    setRequirements
    setVariables
    installBinaries
    initNode
    createKeys
    downloadGenesis
    setPeerSettings
    syncNode
    showNodeId
    cleanUp
}

doAction
