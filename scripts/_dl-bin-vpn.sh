#!/bin/sh

mkdir -p bin/download

# Download Kubernetes binaries, Start VPN when in China
KUBE_VER=v1.13.0
URL=https://storage.googleapis.com/kubernetes-release/release/${KUBE_VER}/bin/linux/amd64
curl ${URL}/kube-apiserver > bin/kube-apiserver
curl ${URL}/kube-controller-manager > bin/kube-controller-manager
curl ${URL}/kube-scheduler > bin/kube-scheduler
curl ${URL}/kubectl > bin/kubectl

chmod +x bin/kube-apiserver bin/kube-controller-manager bin/kube-scheduler bin/kubectl
