#!/bin/sh
KUBE_VER=v1.13.1
docker load < _bin/kube-apiserver_${KUBE_VER}
docker load < _bin/kube-controller-manager_${KUBE_VER}
docker load < _bin/kube-scheduler_${KUBE_VER}
docker load < _bin/kube-proxy_${KUBE_VER}
docker load < _bin/pause_3.1
docker load < _bin/etcd_3.2.24
docker load < _bin/coredns_1.2.6