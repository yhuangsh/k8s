#!/bin/sh

# Setup Kubernetes runtime certificates and config yamls
echo "Setting up /var/lib/kubernetes"
sudo mkdir -p /var/lib/kubernetes/
sudo cp \
    _certs/ca.pem _certs/ca-key.pem \
    _certs/kube-apiserver.pem _certs/kube-apiserver-key.pem \
    _certs/service-account.pem _certs/service-account-key.pem \
    _yaml/encryption-config.yaml \
    /var/lib/kubernetes
sudo cp \ 
    _kubeconifg/kube-controller-manager.kubeconfig \
    _kubeconifg/kube-scheduler.kubeconfig \
    /var/lib/kubernetes/

# Setup Kubernetes' own config file location
echo "Setting up /etc/kuberbetes/config"
sudo mkdir -p /etc/kubernetes/config
sudo cp _yaml/kube-scheduler.yaml /etc/kubernetes/config

# Setup the systemd services: kube-apiserver, kube-controller-manager, kube-scheduler
echo "Setting up /etc/systemd/system"
sudo cp \
    _scripts/out/kube-apiserver.service \
    _scripts/out/kube-controller-manager.service \
    _Scripts/out/kube-scheduler.service \
    /etc/systemd/system
