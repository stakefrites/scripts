read -p "What is this coin's denom? (ex: uatom):" DENOM
read -p "What is the bech prefix (ex: atom):" PREFIX
wget https://github.com/solarlabsteam/cosmos-exporter/releases/download/v0.2.2/cosmos-exporter_0.2.2_Linux_x86_64.tar.gz \ 
tar xvfz cosmos-exporter-0.2.2-Linux-x86_64.tar.gz \
sudo cp ./cosmos-exporter /usr/bin \
cat << EOF > /etc/systemd/system/cosmos-exporter.service
[Unit]
Description=Cosmos Exporter
After=network-online.target

[Service]
User=<username>
TimeoutStartSec=0
CPUWeight=95
IOWeight=95
ExecStart=cosmos-exporter --denom $DENOM --denom-coefficient 1000000 --bech-prefix $PREFIX
Restart=always
RestartSec=2
LimitNOFILE=800000
KillSignal=SIGTERM

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable cosmos-exporter
systemctl start cosmos-exporter
systemctl status cosmos-exporter