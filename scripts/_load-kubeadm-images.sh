#!/bin/sh
docker load < kube-apiserver_v1.13.0
docker load < kube-controller-manager_v1.13.0
docker load < kube-scheduler_v1.13.0 
docker load < kube-proxy_v1.13.0
docker load < pause_3.1
docker load < etcd_3.2.24
docker load < coredns_1.2.6