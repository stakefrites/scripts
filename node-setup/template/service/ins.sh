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

function line() {
    echo "--------------------------------------------------------------------------------"
}

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
    genesisUrl=$(dasel select -p json -f "$DIR/$myChainReg/chain.json" ".genesis.genesis_url" --plain)
    rpcServer=$(dasel select -p json -f "$DIR/$myChainReg/chain.json" ".apis.rpc.[0].address" --plain)
    rpcServerList=$(dasel select -p json -f "$DIR/$myChainReg/chain.json" --format "{{ select \".address\" }},{{ select \".address\" }}" ".apis.rpc.[0]")
    # sed is checking for git url bug (ex: akash)
    githubUrl=$(dasel select -p json -f "$DIR/$myChainReg/chain.json" ".codebase.git_repo" --plain | sed -e "s/[[:punct:]]$//")
    version=$(dasel select -p json -f "$DIR/$myChainReg/chain.json" ".codebase.recommended_version" --plain)
    peers=$(dasel -p json -f "$DIR/$myChainReg/chain.json" -m --format '{{selectMultiple ".seeds.[*]" | format "{{select \".id\" }}@{{select \".address\" }}{{ if not isLast }},{{ end }}" }}' ".peers")
    chainIDvar=$(jq -r ".chain_id" "$DIR/$myChainReg/chain.json")
    daemonVAR=$(jq -r ".daemon_name" "$DIR/$myChainReg/chain.json")
    nodeHomeVAR=$(jq -r ".node_home" "$DIR/$myChainReg/chain.json")
    export CHAIN_ID=$chainIDvar
    export PEERS=$peers
    export GENESIS_URL=$genesisUrl
    export GIT_REPO=$githubUrl
    export VERSION=$version
    export DAEMON=$daemonVAR
    export CONFIG_HOME="$HOME/$(basename $nodeHomeVAR)"
    export RPC_SERVER=$rpcServer
    export RPC_SERVER_LIST=$rpcServerList
    {
        echo "export CHAIN_ID=$chainIDvar"
        echo "export SEEDS=$peers"
        echo "export GENESIS_URL=$genesisUrl"
        echo "export GIT_REPO=$githubUrl"
        echo "export VERSION=$version"
        echo "export DAEMON=$daemonVAR"
        echo "export CONFIG_HOME=$nodeHomeVAR"
        echo "export RPC_SERVER=$rpcServer"
        echo "export RPC_SERVER_LIST=$rpcServerList"
    } >> "$HOME/.bashrc"
}

function setManualVar() {
    read -p "What is the chain ID : " chainIDvar
    read -p "What is the daemon name : " daemonVAR
    read -p "What is the node home ($HOME/.desmos) : " nodeHomeVAR
    read -p "What is the gitrepo url : " gitRepo
    read -p "What is the recommended version : " version
    read -p "What is the genesis.json url (RAW) : " genesisUrl
    read -p "What is the RPC server we trust : " RPC_SERVER
    read -p "Please paste the peers list : " peers
    read -p "Please paste the seeds list : " seeds
    export DAEMON=$daemonVAR
    export CONFIG_HOME=$nodeHomeVAR
    export PEERS=$peers
    export SEEDS=$seeds
    export CHAIN_ID=$chainIDvar
    export GIT_REPO=$gitRepo
    export VERSION=$version
    export RPC_SERVER=$RPC_SERVER
    export RPC_SERVER_LIST=$RPC_SERVER,$RPC_SERVER
    export GENESIS_URL=$genesisUrl
    {
        echo "export CHAIN_ID=$chainIDvar"
        echo "export PEERS=$peers"
        echo "export SEEDS=$seeds"
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
        echo "export OPERATOR_KEY='mateo'"
    } >> "$HOME/.bashrc"
    read -p "Are we using the chain registry? yes-y | n-no : " isChainRegistry
    if [ $isChainRegistry == yes ] || [ $isChainRegistry == y ]; then
        echo "We are using the chain registry"
        setRegistryVar
    else 
        echo "We need some information to continue"
        setManualVar
    fi
    source "$HOME/.bashrc"
}

function createKeys() {
    echo "CREATING THE OPERATOR KEY....."
    read -p "Do we need to import an existing key? (y/n) :" isRecover
    if [ $isRecover == y ] || [ $isRecover == yes ]; then
        echo "Please paste the key you want to import :"
        $DAEMON keys add "$OPERATOR_KEY" --recover
    else
        echo "we are creating a new one"
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
    echo "${GIT_REPO}.git"
    git clone "${GIT_REPO}.git"
    gitName=$(basename "$GIT_REPO")
    cd "$gitName"
    # checking VERSION format
    first_char="$(printf '%s' "$VERSION" | cut -c1)"
    if [ "$first_char" = v ]; then
        echo 'starts with v' >/dev/null
    else
        VERSION="v$VERSION"
    fi
    git checkout "$VERSION"
    make install
}

function showNodeId() {
    echo "Here is the node's id for sentry/validator config....."
    echo $($DAEMON tendermint show-node-id)
}


function queryRPC() {
    dasel put string -f $CONFIG_HOME/config/config.toml .statesync.enable true
    echo "Querying the RPC server....."
    LAST_HEIGHT=$(wget -qO- $RPC_SERVER/commit | jq '.result.signed_header.header.height | tonumber')
    TRUSTED_HEIGHT=$((LAST_HEIGHT-250))
    TRUSTED_HASH=$(wget -qO- $RPC_SERVER/commit?height=$TRUSTED_HEIGHT| jq -r .result.signed_header.commit.block_id.hash)
    echo "trust_hash=$TRUSTED_HASH"
    echo "trust_height= $TRUSTED_HEIGHT"
    dasel put int -f $CONFIG_HOME/config/config.toml .statesync.trust_height $TRUSTED_HEIGHT
    dasel put string -f $CONFIG_HOME/config/config.toml .statesync.trust_hash $TRUSTED_HASH
    dasel put string -f $CONFIG_HOME/config/config.toml .statesync.rpc_servers $RPC_SERVER_LIST
}

function setPeerSettings() {
    echo "We are setting up the peer settings....."
    read -p "What type of node are we setting up? sentry-s | v-validator | a-archive: " nodeType
    if [ $nodeType == sentry ] || [ $nodeType == s ]; then
        echo "We are setting up a sentry node....."
        dasel put bool -f $CONFIG_HOME/config/config.toml .p2p.pex true
        dasel put string -f $CONFIG_HOME/config/config.toml .p2p.seeds $SEEDS
        dasel put bool -f $CONFIG_HOME/config/config.toml .p2p.addr_book_strict false
    elif [ $nodeType == validator ] || [ $nodeType == v ]; then
        echo "We are setting up a validator node....."
        dasel put bool -f $CONFIG_HOME/config/config.toml .p2p.pex false
        dasel put bool -f $CONFIG_HOME/config/config.toml .p2p.addr_book_strict false
    else
        echo "We are setting up an archive node....."
        dasel put bool -f $CONFIG_HOME/config/app.toml .api.enable true
        # Le int va p-e bugger, valider avec la doc dasel
        dasel put int -f $CONFIG_HOME/config/app.toml .state-sync.snapshot-interval 100
        dasel put int -f $CONFIG_HOME/config/app.toml .state-sync.snapshot-keep-recent 5
        dasel put string -f $CONFIG_HOME/config/app.toml .pruning "nothing"
    fi
}

function syncNode() {
    read -p "What type of sync are we doig? statesync-s | snapshot-snap | genesis-g : " syncType
    line
     if [ $syncType == statesync ] || [ $syncType == s ]; then
        echo "We are state syncing"
        line
        queryRPC
    elif [ $syncType == snapshot ] || [ $syncType == snap ]; then
        echo "We will download the snapshot"
        line
        downloadSnapshot
    else 
        echo "We are not syncing"
    fi
}

function downloadSnapshot() {
    echo "We are downloading the snapshot....."
    read -p "What is the snapshot url? : " snapshotUrl
    line
    cd $CONFIG_HOME
    wget $snapshotUrl
    filename=$(basename "$snapshotUrl")
    echo "We will untar the snapshot"
    tar -I'pixz' -xvf $filename --strip-components=4
    echo "Untar done"
 
}

function cleanUp() {
    rm -rf temp
}



function doAction() {
    echo "[*] Setting requirements"
    line
    setRequirements
    echo "[*] Setting variables"
    line
    setVariables
    echo "[*] Instaling binaries"
    line
    installBinaries
    echo "[*] Initializing node"
    line
    initNode
    #echo "[*] Creating keys"
    #line
    #createKeys
    echo "[*] Downloading genesis file"
    line
    downloadGenesis
    echo "[*] Setting the peer settings"
    line
    setPeerSettings
    echo "[*] Setting up the sync configuration"
    line
    syncNode
    echo "[*] Here is the node id"
    line
    showNodeId
    echo "[*] Cleaning up ..."
    line
    cleanUp
    echo "[*] Setting requirements"
    line
}

doAction
