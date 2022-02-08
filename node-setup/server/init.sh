#!/bin/bash

newUserJE="jeen"
newUserNic="somecanadian"
pubKeyJE="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCuV7zTvrJS/orxdrzZnPimY2URNIKjlBe574G+vJZsUmE2TB/TbhE47ifwkonerL50N+2/eYnmEY8rVENvSK14kK0XHd+Zdxo9rhsamzQrftGdEt7piiPjU8hL3j4EvHs89DeT3FEOCGbwoZdUTBtkIZ/qvWtQdpcKFBcuXne7RyrAIr0QzzzxCkT1I/Be2fc/EjzIvi5aQq0z/As8DWx/7s0sfWmBoGJ6YwBUg+1ZjIjMHqsBqUAPUQMVe/Yc/VoxCdfckp1dzmu2qO5uHox9oU1wnA23Jzy2M9972ppthVOKi9cxXMinbhcqJaSOccyCTwlYLl6asYt+n9XlJ8XH8tcajN2mQdr0R1e5WgU5A5L+l8l0hU97sMltSvSR4vmECGyF0GZoFQsUxkdLZrbM43OeFgICraA0g4/9GhZGmoaCKziPieW6aqgQJBDUf1v4HRXm3XBJe1smzTlF0JUWqV4wsQs84/KGEkpKLiiWZG4VbSM9H6tcIwQz/tNo0+s="
pubKeyNic="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC2M01axIQBOyGNmzONjYvKCjQgdGOFrU4d1NVHyxo9ZtFYao6BJEYcMDj7E5oSIMcGTNd5qu+HUNgzSKcklQeVGlhgwLSAVMv6JC7Er8gFt304f7Wr+kS6W7Eeb+HQ3dV+MaG6DWYWacCYM+k0NIMHm7SMdajSeJVmIu1XWZnFkYdFY9QF5SM9j1Wm0KYrL5gS4B71ev/RjTAlwVY5b+QqIgMb/vyT51EmhR1M3hHJ1JkAUF1qyH9+1cb2h8Of3YLb+KmwyEC5U1WXyMEuZ1S0PbvX3oQRAEQN7vThtUt6Zd5tGLFtghDgh0eo3jifiX45qynEDjN9FXRfZxNAMxsrT1jkCFCuK6ZA4sQyDTejmmTgHsIsMhUDxHdbbCG5TmC3InJrOZmBB7JanR6AsKBB3ticG8v+WCWPWtgIVDdlhj3ZWxkX/WtORqR1mWA6PMHmOOp67PvkHIX8Q1HuupceCME7oLGV6zJkZp+fnzbrqcwTrpan6gA91pIaGCI2Kb43giOIoS2lu3n2JdyEQgRy6/zXVLjzLebeibqrn6e0guNwYNqOqZtfhRe0mAPHIGRe12dhTOzofcUrOz5jA7vXhFBxTGsmh3vLhTUMbcbOG5K0tEfFwDuiUz6f1zHz54C56pKr7zUv4hw3uOepFFSXBXLYxBkKZkTkmeGVP2SKgw=="
#profileFile="mateo-var.sh"

newUserCrypto="$1"

function line() {
    echo "--------------------------------------------------------------------------------"
}

# Self deleting function at exit if needed --- voir la fin du script
currentscript="$0"
function customFinish {
    echo "Securely shredding ${currentscript}"; shred -u ${currentscript};
}

function checkSudo() {
    echo "[*] Validating root permissions"
    line
    if [[ $EUID -ne 0 ]]; then
        echo "[x] This script must be run as root... Configuration need root priv... Quitting!"
        line
        exit 1
    fi
}

function checkArgs() {
    echo "[*] Check number or arguments in th cmd..."
    if [ $# -le 0 ]; then
        echo "Not enough arguments provided..." && echo "Ex: sudo ./init-node.sh servicename username" && echo "Ex: sudo ./init-node.sh expressd express"
        exit 1
    fi
}

function setRequirements() {
    sudo apt-get update
    sudo apt-get upgrade -y
    sudo apt-get dist-upgrade -y
    sudo apt-get clean all
    sudo apt-get autoremove -y
    sudo apt install nodejs npm chrony git build-essential ufw curl jq wget liblz4-tool aria2 pixz pigz net-tools libssl-dev pkg-config -y
}


function setUsers() {
    # crypto user
    sudo adduser --gecos "" --home /var/lib/$newUserCrypto --disabled-password --quiet $newUserCrypto
    chmod 0700 /var/lib/$newUserCrypto
    # jeen et somecanadian
    sudo adduser --gecos "" --disabled-password --quiet $newUserJE
    sudo adduser --gecos "" --disabled-password --quiet $newUserNic
    usermod -a -G sudo $newUserJE
    usermod -a -G sudo $newUserNic
}

function sudoersFu() {
    # Take a backup of sudoers file and change the backup file.
    cp /etc/sudoers /tmp/sudoers.bak && sudo sed -i -e "s/%sudo/#%sudo/g" /tmp/sudoers.bak
    {
        echo "$newUserJE ALL=(ALL) NOPASSWD:ALL"
        echo "$newUserNic ALL=(ALL) NOPASSWD:ALL"
    } >>/tmp/sudoers.bak
    # Check syntax of the backup file to make sure it is correct.
    sudo visudo -cf /tmp/sudoers.bak
    if [ $? -eq 0 ]; then
        # Replace the sudoers file with the new only if syntax is correct.
        sudo cp /tmp/sudoers.bak /etc/sudoers && sudo rm /tmp/sudoers.bak
    else
        echo "Could not modify /etc/sudoers file. Please do this manually." && sudo rm /tmp/sudoers.bak
    fi
}

function setupSSHkeys() {
    mkdir /home/$newUserJE/.ssh
    touch /home/$newUserJE/.ssh/authorized_keys
    echo "$pubKeyJE" >>/home/$newUserJE/.ssh/authorized_keys
    chmod 700 /home/$newUserJE/.ssh
    chown "$newUserJE:$newUserJE" -R /home/$newUserJE/.ssh
    #
    mkdir /home/$newUserNic/.ssh
    touch /home/$newUserNic/.ssh/authorized_keys
    echo "$pubKeyNic" >>/home/$newUserNic/.ssh/authorized_keys
    chmod 700 /home/$newUserNic/.ssh
    chown "$newUserNic:$newUserNic" -R /home/$newUserNic/.ssh
}

function rootLogin() {
    cat /etc/ssh/sshd_config | sed "s/PermitRootLogin yes/PermitRootLogin no/" > /etc/ssh/sshd_config.new
    mv /etc/ssh/sshd_config /etc/ssh/sshd_config-OG.bak
    mv /etc/ssh/sshd_config.new /etc/ssh/sshd_config
    sudo systemctl enable ssh
    sudo systemctl restart ssh
}

function setTimezone() {
    sudo timedatectl set-timezone America/Toronto
}





function askReboot() {
    echo ""
    echo "Do you want to reboot ?"
    select yn in "Yes" "No"; do
        case $yn in
        Yes) sleep 5 ; reboot &&  trap customFinish EXIT;;
        No) exit ;;
        esac
    done
}

function doAction() {
    checkSudo
    checkArgs "$@"
    line
    echo "[*] Setting Requirements"
    setRequirements
    line
    echo "[*] Setting Users"
    setUsers
    line
    echo "[*] Setting Sudoers"
    sudoersFu
    line
    echo "[*] Setting SSHkeys"
    setupSSHkeys
    rootLogin
    line
    echo "[*] Setting Timezone"
    setTimezone
    line
    echo "The END"
    echo "Please go delete init-node.sh script when re-logging in the /root dir"
    echo "Note: You won't be able to login with root again"
    askReboot
}
doAction "$@"