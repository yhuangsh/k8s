#!/bin/sh

mkdir -p bin/download

# Download Kubernetes binaries, Start VPN when in China
KUBE_VER=v1.13.0
URL=https://storage.googleapis.com/kubernetes-release/release/${KUBE_VER}/bin/linux/amd64
curl -i -L ${URL}/kube-apiserver -o bin/kube-apiserver
curl -i -L ${URL}/kube-controller-manager -o bin/kube-controller-manager
curl -i -L ${URL}/kube-scheduler -o bin/kube-scheduler

chmod +x bin/kube-apiserver bin/kube-controller-manager bin/kube-scheduler
