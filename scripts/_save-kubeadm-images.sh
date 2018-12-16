#!/bin/sh
docker save k8s.gcr.io/kube-apiserver:v1.13.0 > kube-apiserver_v1.13.0
docker save k8s.gcr.io/kube-controller-manager:v1.13.0 > kube-controller-manager_v1.13.0
docker save k8s.gcr.io/kube-scheduler:v1.13.0 > kube-scheduler_v1.13.0 
docker save k8s.gcr.io/kube-proxy:v1.13.0 > kube-proxy_v1.13.0
docker save k8s.gcr.io/pause:3.1 > pause_3.1
docker save k8s.gcr.io/etcd:3.2.24 > etcd_3.2.24
docker save k8s.gcr.io/coredns:1.2.6 > coredns_1.2.6