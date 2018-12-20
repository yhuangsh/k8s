#!/bin/sh

# Use VPN
KUBE_VER=v1.13.1
docker pull k8s.gcr.io/kube-apiserver:${KUBE_VER} 
docker pull k8s.gcr.io/kube-controller-manager:${KUBE_VER}
docker pull k8s.gcr.io/kube-scheduler:${KUBE_VER}  
docker pull k8s.gcr.io/kube-proxy:${KUBE_VER} 
docker pull k8s.gcr.io/pause:3.1 
docker pull k8s.gcr.io/etcd:3.2.24 
docker pull k8s.gcr.io/coredns:1.2.6 