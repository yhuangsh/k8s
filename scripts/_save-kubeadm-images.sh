#!/bin/sh
KUBE_VER=v1.13.1
docker save k8s.gcr.io/kube-apiserver:${KUBE_VER} > bin/kube-apiserver_${KUBE_VER}
docker save k8s.gcr.io/kube-controller-manager:${KUBE_VER} > bin/kube-controller-manager_${KUBE_VER}
docker save k8s.gcr.io/kube-scheduler:${KUBE_VER} > bin/kube-scheduler_${KUBE_VER} 
docker save k8s.gcr.io/kube-proxy:${KUBE_VER} > bin/kube-proxy_${KUBE_VER}
docker save k8s.gcr.io/pause:3.1 > bin/pause_3.1
docker save k8s.gcr.io/etcd:3.2.24 > bin/etcd_3.2.24
docker save k8s.gcr.io/coredns:1.2.6 > bin/coredns_1.2.6
docker save weaveworks/weave-kube:2.5.0 > bin/weaveworks_weave-kube_2.5.0
docker save weaveworks/weave-npc:2.5.0 > bin/weaveworks_weave-npc_2.5.0