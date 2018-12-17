#!/bin/sh

# Run this script on masters 
sudo mkdir -p /etc/etcd /var/lib/etcd
sudo cp \
  _certs/ca.pem _certs/ca-key.pem \
  _certs/kube-apiserver.pem _certs/kube-apiserver-key.pem \
  /etc/etcd
sudo cp _scripts/out/etcd.service /etc/systemd/system/etcd.service
sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl start etcd
sudo ETCDCTL_API=3 etcdctl member list \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/kube-apiserver.pem \
  --key=/etc/etcd/kube-apiserver-key.pem