goLatestVersion="1.17.4"
profileFile="mateo-var.sh"
function setupLatestGO() {
    wget https://go.dev/dl/go"$goLatestVersion".linux-amd64.tar.gz
    # check if old go is already there
    if [ -d "/usr/local/go" ]; then
        rm -rf /usr/local/go
    fi
    tar -C /usr/local -xzf go"$goLatestVersion".linux-amd64.tar.gz
    rm go"$goLatestVersion".linux-amd64.tar.gz
    # Set GOPATH
    touch /etc/profile.d/$profileFile
    GOBIN="\$HOME/go/bin"
    GOROOT="\$HOME/go"
    {
        echo "export GO111MODULE=on"
        echo "export GOPATH=\$HOME/go"
        echo "export GOBIN=$GOBIN"
        echo "export PATH=$GOBIN:$GOROOT:/usr/local/go/bin:$PATH"
    } >>/etc/profile.d/$profileFile
}

setupLatestGO

