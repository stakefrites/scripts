#!/bin/bash

newUserCrypto="$1"
daemonName="$2"
# Self deleting function at exit if needed --- voir la fin du script
currentscript="$0"
function customFinish {
    echo "Securely shredding ${currentscript}"; shred -u ${currentscript};
}

function checkArgs() {
    echo "[*] Check number or arguments in th cmd..."
    if [ $# -le 1 ]; then
        echo "Not enough arguments provided..." && echo "Ex: ./finish-node.sh newUserCrypto daemonName " && echo "Ex:  ./finish-node.sh evmos evmosd"
        exit 1
    fi
}

function checkSudo() {
    echo "[*] Gonna check if you are root"
    if [[ $EUID -ne 0 ]]; then
        echo "[x] This script must be run as root... Configuration need root priv... Quitting!"
        exit 1
    fi
}


function doAction() {
    checkSudo
    checkArgs "$@"
    echo "[*] Moving the config folder to the volume"
    mv /var/lib/$newUserCrypto/.$daemonName /mnt/$daemonName/
    echo "[*] Creating symlink in the service's home directory"
    ln -s /mnt/$daemonName/.$daemonName /var/lib/$newUserCrypto/.$daemonName
    echo "[*] Updating the services's persmissions"
    chown -R $newUserCrypto:$newUserCrypto /var/lib/$newUserCrypto
    # echo "[*] Deleting install script"
    customFinish
}

doAction "$@"