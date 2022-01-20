# scripts


## TO-DO
- Implement Cosmovisor setup
    - https://docs.cosmos.network/master/run-node/cosmovisor.html
    - Add the service file 
    - move binaries
- Implement Snapshot download [in progress]
    - Akash didn't work
- Add a config.toml file that will configure basic settings


## How to use
1. Setup the droplet
2. Copy the script in the root folder and run it as root to setup the machine
3. Accept the prompt
4. Accept the reboot
5. Re-login as your user
6. Copy both scripts in the "service" folder
7. Run install-chain.sh to do a full node setup
8. Start the sync