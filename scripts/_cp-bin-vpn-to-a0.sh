#!/bin/sh

scp bin/kube-apiserver \
    bin/kube-controller-manager \
    bin/kube-scheduler \
    huang@a0.davidhuang.top:/home/huang/k8s/bin