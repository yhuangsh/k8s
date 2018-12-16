#!/bin/sh

mkdir -p bin/download

# Download etcd binaries, github is slow from time to time in China. Use VPN
ETCD_VER=v3.3.10
URL=https://github.com/etcd-io/etcd/releases/download
curl -L ${URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o bin/download/etcd-${ETCD_VER}-linux-amd64.tar.gz
tar xzf bin/download/etcd-${ETCD_VER}-linux-amd64.tar.gz 
cp etcd-${ETCD_VER}-linux-amd64/etcd bin/
cp etcd-${ETCD_VER}-linux-amd64/etcdctl bin/
rm -fR etcd-${ETCD_VER}-linux-amd64

chmod +x bin/etcd bin/etcdctl


