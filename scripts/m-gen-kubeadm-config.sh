#!/bin/sh

A0_IP=172.17.94.124
M0_IP=172.17.59.89
M1_IP=172.17.94.123
M2_IP=172.17.197.159

mkdir -p /home/huang/_yaml
cat <<EOF | tee _yaml/kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1alpha3
kind: ClusterConfiguration
kubernetesVersion: stable
apiServerCertSANs:
- ${A0_IP}
- a0.davidhuang.top
- a0
controlPlaneEndpoint: "${A0_IP}:6443"
etcd:
  external:
    endpoints:
    - https://${M0_IP}:2379
    - https://${M1_IP}:2379
    - https://${M2_IP}:2379
    caFile: /etc/etcd/ca.pem
    certFile: /etc/etcd/kubernetes.pem
    keyFile: /etc/etcd/kubernetes-key.pem
networking:
  podSubnet: 10.30.0.0/24
apiServerExtraArgs:
  apiserver-count: "3"
EOF