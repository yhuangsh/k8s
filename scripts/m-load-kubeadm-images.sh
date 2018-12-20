#!/bin/sh
KUBE_VER=v1.13.1
sudo docker load < _bin/kube-apiserver_${KUBE_VER}
sudo docker load < _bin/kube-controller-manager_${KUBE_VER}
sudo docker load < _bin/kube-scheduler_${KUBE_VER}
sudo docker load < _bin/kube-proxy_${KUBE_VER}
sudo docker load < _bin/pause_3.1
sudo docker load < _bin/etcd_3.2.24
sudo docker load < _bin/coredns_1.2.6

sudo docker load < _bin/weaveworks_weave-kube_2.5.0
sudo docker load < _bin/weaveworks_weave-npc_2.5.0