#!/bin/sh


ssh m0 mkdir -p /home/huang/_bin
ssh m1 mkdir -p /home/huang/_bin
ssh m2 mkdir -p /home/huang/_bin

scp bin/etcd bin/etcdctl \
    bin/kube-apiserver bin/kube-controller-manager bin/kube-scheduler \
    m0:/home/huang/_bin

scp bin/etcd bin/etcdctl \
    bin/kube-apiserver bin/kube-controller-manager bin/kube-scheduler \
    m1:/home/huang/_bin

scp bin/etcd bin/etcdctl \
    bin/kube-apiserver bin/kube-controller-manager bin/kube-scheduler \
    m2:/home/huang/_bin


