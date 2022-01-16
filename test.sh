#!/bin/bash

newUserCrypto="akash"
serviceName="akash"

cat << EOF > test.txt
[Unit]
Description=$serviceName service
After=network-online.target
[Service]
User=$newUserCrypto
ExecStart=/root/go/bin/akash start
Restart=always
RestartSec=3
LimitNOFILE=4096
[Install]
WantedBy=multi-user.target
EOF