#!/bin/sh

ssh m0 mkdir -p /home/huang/_certs
ssh m0 mkdir -p /home/huang/_bin
ssh m0 mkdir -p /home/huang/_kubeconfig
ssh m0 mkdir -p /home/huang/_yaml
ssh m0 mkdir -p /home/huang/_scripts

ssh m1 mkdir -p /home/huang/_certs
ssh m1 mkdir -p /home/huang/_bin
ssh m1 mkdir -p /home/huang/_kubeconfig
ssh m1 mkdir -p /home/huang/_yaml
ssh m1 mkdir -p /home/huang/_scripts

ssh m2 mkdir -p /home/huang/_certs
ssh m2 mkdir -p /home/huang/_bin
ssh m2 mkdir -p /home/huang/_kubeconfig
ssh m2 mkdir -p /home/huang/_yaml
ssh m2 mkdir -p /home/huang/_scripts

scp certs/out/* m0:/home/huang/_certs
scp bin/etcd bin/etcdctl \
    bin/kube-apiserver bin/kube-controller-manager bin/kube-scheduler \
    m0:/home/huang/_bin
scp kubeconfig/admin.kubeconfig \
    kubeconfig/kube-controller-manager.kubeconfig \
    kubeconfig/kube-scheduler.kubeconfig \
    m0:/home/huang/_kubeconfig
scp yaml/* m0:/home/huang/_yaml
scp scripts/m* m0:/home/huang/_scripts

scp certs/out/* m1:/home/huang/_certs
scp bin/etcd bin/etcdctl \
    bin/kube-apiserver bin/kube-controller-manager bin/kube-scheduler \
    m1:/home/huang/_bin
scp kubeconfig/admin.kubeconfig \
    kubeconfig/kube-controller-manager.kubeconfig \
    kubeconfig/kube-scheduler.kubeconfig \
    m1:/home/huang/_kubeconfig
scp yaml/* m1:/home/huang/_yaml
scp scripts/m* m1:/home/huang/_scripts

scp certs/out/* m2:/home/huang/_certs
scp bin/etcd bin/etcdctl \
    bin/kube-apiserver bin/kube-controller-manager bin/kube-scheduler \
    m2:/home/huang/_bin
scp kubeconfig/admin.kubeconfig \
    kubeconfig/kube-controller-manager.kubeconfig \
    kubeconfig/kube-scheduler.kubeconfig \
    m2:/home/huang/_kubeconfig
scp yaml/* m2:/home/huang/_yaml
scp scripts/m* m2:/home/huang/_scripts

