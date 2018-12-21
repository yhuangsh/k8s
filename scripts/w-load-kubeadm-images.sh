#!/bin/sh
KUBE_VER=v1.13.1
sudo docker load < _bin/kube-proxy_${KUBE_VER}
sudo docker load < _bin/pause_3.1

sudo docker load < _bin/weaveworks_weave-kube_2.5.0
sudo docker load < _bin/weaveworks_weave-npc_2.5.0