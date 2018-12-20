#!/bin/sh

CERTSDIR=certs

rm $CERTSDIR/out
mkdir -p $CERTSDIR/out

# Generate the self-signed CA certificate. 
# It will be used to sign/verify all other certificates
cfssl gencert \
  -initca \
  $CERTSDIR/ca-csr.json | cfssljson -bare $CERTSDIR/out/ca

# Generate the admin client certificate. This certificate will be used by the kubectl 
# from your local machine to access kube-apiserver on your Alibaba cloud VMs
#cfssl gencert \
#  -ca=$CERTSDIR/out/ca.pem \
#  -ca-key=$CERTSDIR/out/ca-key.pem \
#  -config=$CERTSDIR/ca-config.json \
#  $CERTSDIR/admin-csr.json | cfssljson -bare $CERTSDIR/out/admin

# Generate certificates for each worker node VMs. You need to know the cloud internal IP 
# address of these nodes
#cfssl gencert \
#  -ca=$CERTSDIR/out/ca.pem \
#  -ca-key=$CERTSDIR/out/ca-key.pem \
#  -config=$CERTSDIR/ca-config.json \
#  $CERTSDIR/w0-csr.json | cfssljson -bare $CERTSDIR/out/w0

# Generate client certificate for Kube Controller Manager. It is used by the controller manager to 
# access other kube-* servers
#cfssl gencert \
#  -ca=$CERTSDIR/out/ca.pem \
#  -ca-key=$CERTSDIR/out/ca-key.pem \
#  -config=$CERTSDIR/ca-config.json \
#  $CERTSDIR/kube-controller-manager-csr.json | cfssljson -bare $CERTSDIR/out/kube-controller-manager

# Generate client certificate for Kube Proxy. It is used by kube-proxy to access other kube-* servers
#cfssl gencert \
#  -ca=$CERTSDIR/out/ca.pem \
#  -ca-key=$CERTSDIR/out/ca-key.pem \
#  -config=$CERTSDIR/ca-config.json \
#  $CERTSDIR/kube-proxy-csr.json | cfssljson -bare $CERTSDIR/out/kube-proxy

# Generate client certificate for Kube Scheduler. It is used by the scheduler to access other kube-* 
# servers
#cfssl gencert \
#  -ca=$CERTSDIR/out/ca.pem \
#  -ca-key=$CERTSDIR/out/ca-key.pem \
#  -config=$CERTSDIR/ca-config.json \
#  $CERTSDIR/kube-scheduler-csr.json | cfssljson -bare $CERTSDIR/out/kube-scheduler

A0_IP=172.17.94.124
M0_IP=172.17.59.89
M1_IP=172.17.94.123
M2_IP=172.17.197.159
# Generate server certificate for Kube API Server. This certificate will be verified by connecting 
# kube-* clients
cfssl gencert \
  -ca=$CERTSDIR/out/ca.pem \
  -ca-key=$CERTSDIR/out/ca-key.pem \
  -config=$CERTSDIR/ca-config.json \
  -hostname=${A0_IP},${M0_IP},${M1_IP},${M2_IP},127.0.0.1,kubernetes.default \
  $CERTSDIR/kubernetes-csr.json | cfssljson -bare $CERTSDIR/out/kubernetes

# Generate service account 
#cfssl gencert \
#  -ca=$CERTSDIR/out/ca.pem \
#  -ca-key=$CERTSDIR/out/ca-key.pem \
#  -config=$CERTSDIR/ca-config.json \
#  $CERTSDIR/service-account-csr.json | cfssljson -bare $CERTSDIR/out/service-account