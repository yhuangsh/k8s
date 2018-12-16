#!/bin/sh

ssh huang@a0.davidhuang.top mkdir -p /home/huang/k8s/bin/
scp bin/etcd bin/etcdctl \
    bin/kube-apiserver bin/kube-controller-manager bin/kube-scheduler bin/kubectl \
    huang@a0.davidhuang.top:/home/huang/k8s/bin