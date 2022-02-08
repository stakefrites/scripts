read -p "What is the daemon name? (binary ex: chihuahuad):" DAEMON_NAME
read -p "What is your user's name? (ex: chihuahua):" USER_NAME
read -p "What is your home config folder? (ex: .lumd):" HOME_CONFIG


cat << EOF > /etc/systemd/system/cosmovisor.service
[Unit]
Description=cosmovisor
After=network-online.target

[Service]
User=<your-user>
ExecStart=/var/lib/$USER_NAME/go/bin/cosmovisor start
Restart=always
RestartSec=3
LimitNOFILE=4096
Environment="DAEMON_NAME=$DAEMON_NAME"
Environment="DAEMON_HOME=/var/lib/$USER_NAME/$HOME_CONFIG"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=false"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable cosmovisor
systemctl start cosmovisor
systemctl status cosmovisor