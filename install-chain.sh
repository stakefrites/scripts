#!/bin/bash

# evmos, akash, chihuaha, lum network, osmosis, desmos, cosmos

# https://github.com/cosmos/chain-registry

# check if go dir exist

myChainReg="chain-registry"
# current script dir
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -d "$HOME/go" ]; then
    mkdir go
fi

function setupChainRepo() {
    mkdir temp
    cd temp
    git clone https://github.com/cosmos/chain-registry.git
    cd $DIR
}

function chooseChain() {
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
#setRequirements

function setChainVAR() {
    #githubURL=$(dasel select -p json -f "$DIR/$myChainReg/chain.json" ".codebase.git_repo")
    echo "$githubURL"
    #gitBranch=$(dasel select -p json -f "$DIR/$myChainReg/chain.json" ".codebase.recommended_version")
    echo "$gitBranch"
    #setDenom=$(dasel select -p json -f "$DIR/$myChainReg/chain.json" ".peers")
}
#setChainVAR

function getPeers() {
    peersMax=$(jq ".peers.seeds | length" "$DIR/$myChainReg/chain.json")
    peersCounter=0
    while [[ $peersCounter -lt $peersMax ]]; do
        if [[ $peersCounter == 0 ]]; then
            touch temp.json
        fi
        peersID=$(jq -r ".peers.seeds[$peersCounter].id" "$DIR/$myChainReg/chain.json")
        peersAddress=$(jq -r ".peers.seeds[$peersCounter].address" "$DIR/$myChainReg/chain.json")
        #echo "Counter: $peersCounter"
        echo "$peersID@$peersAddress" | jq -R '.' >> temp.json
        #
        peersCounter=$(( peersCounter + 1 ))
    done
    jq -s '.' temp.json > "$DIR/$myChainReg/peers.json"
    rm temp.json
    jq '.' "$DIR/$myChainReg/peers.json"
}

function getRPC() {
    rpcMax=$(jq ".apis.rpc | length" "$DIR/$myChainReg/chain.json")
    rpcCounter=0
    while [[ $rpcCounter -lt $rpcMax ]]; do
        if [[ $rpcCounter == 0 ]]; then
            touch temp.json
        fi
        rpcAddress=$(jq -r ".apis.rpc[$rpcCounter].address" "$DIR/$myChainReg/chain.json")
        #echo "Counter: $rpcCounter"
        echo "$rpcAddress" | jq -R '.' >> temp.json
        #
        rpcCounter=$(( rpcCounter + 1 ))
    done
    jq -s '.' temp.json > "$DIR/$myChainReg/rpc.json"
    rm temp.json
    jq '.' "$DIR/$myChainReg/rpc.json"
}

function getGenesis() {
    genesisURL=$(jq '.genesis.genesis_url' "$DIR/$myChainReg/chain.json")
    echo "$genesisURL" | jq -s '.' > "$DIR/$myChainReg/genesis-url.json"
}

function setMiscVAR() {
    chainIDvar=$(jq ".chain_id" "$DIR/$myChainReg/chain.json")
    daemonVAR=$(jq ".daemon_name" "$DIR/$myChainReg/chain.json")
    nodeHomeVAR=$(jq ".node_home" "$DIR/$myChainReg/chain.json")
    MONIKER="Stake Frites"
    {
        echo "export CHAIN_ID=$chainIDvar"
        echo "export DAEMON=$daemonVAR"
        echo "export CONFIG_HOME=$nodeHomeVAR"
        echo "export MONIKER=\"$MONIKER\""
        echo "export WEBSITE='https://stakefrites.co'"
        echo "export DESCRIPTION='PoS Validators & Web3 developpers'"
        echo "export identity='7817CA2B0981F769'"
    } >> "$HOME/.bashrc"
    source "$HOME/.bashrc"
}

function getChainRepo() {
    gitRepo=$(jq -r ".codebase.git_repo" "$DIR/$myChainReg/chain.json")
    gitRepoVer=$(jq -r ".codebase.recommended_version" "$DIR/$myChainReg/chain.json")
    git clone "$gitRepo.git"
    gitName=$(basename "$gitRepo")
    cd "$gitName"
    git checkout "$gitRepoVer"
    make install
    $DAEMON init "$MONIKER" --chain-id $CHAIN_ID
}

function cleanUp() {
    rm -rf temp
}

function doAction() {
    setupChainRepo
    chooseChain
    getPeers
    getRPC
    getGenesis
    setMiscVAR
    getChainRepo
    cleanUp
}
doAction
