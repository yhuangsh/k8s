#!/bin/sh

M0_IP=172.17.59.89
M1_IP=172.17.94.123
M2_IP=172.17.197.159
INTERNAL_IP=$M0_IP

mkdir -p /home/huang/_scripts/out
cat <<EOF | tee _scripts/out/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \\
  --config=/etc/kubernetes/config/kube-scheduler.yaml \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF