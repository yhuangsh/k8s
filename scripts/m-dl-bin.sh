#!/bin/sh

mkdir -p bin/download

ETCD_VER=v3.3.10
URL=https://github.com/etcd-io/etcd/releases/download

#curl -L ${URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o bin/download/etcd-${ETCD_VER}-linux-amd64.tar.gz
tar xzvf bin/download/etcd-${ETCD_VER}-linux-amd64.tar.gz etcd-${ETCD_VER}-linux-amd64/etcd -O > bin/etcd
tar xzvf bin/download/etcd-${ETCD_VER}-linux-amd64.tar.gz etcd-${ETCD_VER}-linux-amd64/etcdctl -O > bin/etcdctl

chmod +x bin/etcd bin/etcdctl
bin/etcd --version
bin/etcdctl --version

