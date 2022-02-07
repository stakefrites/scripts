wget https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-amd64.tar.gz
tar xvfz node_exporter-1.3.1.linux-amd64.tar.gz
mv node_exporter-1.3.1.linux-amd64/node_exporter /usr/bin/
rm node_exporter-1.3.1.linux-amd64.tar.gz
rm -rf node_exporter-1.3.1.linux-amd64
cat << EOF > /etc/systemd/system/node-exporter.service
[Unit]
Description=Node Exporter
After=network-online.target

[Service]
User=root
TimeoutStartSec=0
CPUWeight=95
IOWeight=95
ExecStart=node_exporter
Restart=always
RestartSec=2
LimitNOFILE=800000
KillSignal=SIGTERM

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable node-exporter
systemctl start node-exporter
systemctl status node-exporter