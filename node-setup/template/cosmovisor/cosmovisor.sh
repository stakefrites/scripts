go install github.com/cosmos/cosmos-sdk/cosmovisor/cmd/cosmovisor@latest
line read -p "What is the chain daemon name (binary ex: chihuahuad/lumd/akash):" DAEMON_NAME
line read -p "What is the chain home config folder (ex: chihuahua):" USER
line read -p "What is the chain home config folder (ex: .lumd):" HOME_CONFIG
mkdir -p /var/lib/$USER/$HOME_CONFIG/cosmovisor/genesis/bin
mkdir -p /var/lib/$USER/$HOME_CONFIG/cosmovisor/upgrades
cp /var/lib/$USER/go/bin/$DAEMON_NAME /var/lib/$USER/$HOME_CONFIG/cosmovisor/genesis/bin/