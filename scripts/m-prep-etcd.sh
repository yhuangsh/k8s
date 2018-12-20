#!/bin/sh

# Run this script on masters 
sudo cp _bin/etcd _bin/etcdctl /usr/local/bin
sudo mkdir -p /etc/etcd /var/lib/etcd
sudo cp \
  _certs/ca.pem _certs/ca-key.pem \
  _certs/kubernetes.pem _certs/kubernetes-key.pem \
  /etc/etcd
sudo cp _scripts/out/etcd.service /etc/systemd/system/etcd.service
sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl start etcd
