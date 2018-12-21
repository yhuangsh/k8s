#!/bin/sh

echo "Did you copied the first master's Kubernetes certs to here"
rm ~/pki/apiserver.*
sudo mv ~/pki /etc/kubenetes/
echo "If everything's ok, do the following"
echo "sudo kubeadm --config=_yaml/kubeadm-config.yaml --ignore-preflight-errors=NumCPU"
