#!/bin/sh

sudo ETCDCTL_API=3 \
    etcdctl member list \
    --endpoints=https://127.0.0.1:2379 \
    --cacert=/etc/etcd/ca.pem \
    --cert=/etc/etcd/kube-apiserver.pem \
    --key=/etc/etcd/kube-apiserver-key.pem