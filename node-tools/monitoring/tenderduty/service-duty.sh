read -p "What is the valcons address? :" address

cat << EOF > /etc/systemd/system/tenderduty.service
[Unit]
Description=Tenderduty
After=network-online.target

[Service]
User=root
TimeoutStartSec=0
CPUWeight=95
IOWeight=95
ExecStart=tenderduty -c $address -p 91f9cbd6ff6d4c00d06c2fc47ca00a5f -u http://127.0.0.1:26657 -threshold 5
Restart=always
RestartSec=2
LimitNOFILE=800000
KillSignal=SIGTERM

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable tenderduty
systemctl start tenderduty
systemctl status tenderduty