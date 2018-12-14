#!/bin/sh

# Generate the self-signed CA certificate. 
# It will be used to sign/verify all other certificates
cfssl gencert \
  -initca \
  ca-csr.json | cfssljson -bare out/ca

# Generate the admin client certificate. This certificate will be used by the kubectl 
# from your local machine to access kube-apiserver on your Alibaba cloud VMs
cfssl gencert \
  -ca=out/ca.pem \
  -ca-key=out/ca-key.pem \
  -config=ca-config.json \
  admin-csr.json | cfssljson -bare out/admin

# Generate certificates for each worker node VMs. You need to know the cloud internal IP 
# address of these nodes
cfssl gencert \
  -ca=out/ca.pem \
  -ca-key=out/ca-key.pem \
  -config=ca-config.json \
  w0-csr.json | cfssljson -bare out/w0

# Generate client certificate for Kube Controller Manager. It is used by the controller manager to 
# access other kube-* servers
cfssl gencert \
  -ca=out/ca.pem \
  -ca-key=out/ca-key.pem \
  -config=ca-config.json \
  kube-ctrl-mgr-csr.json | cfssljson -bare out/kube-ctrl-mgr

# Generate client certificate for Kube Proxy. It is used by kube-proxy to access other kube-* servers
cfssl gencert \
  -ca=out/ca.pem \
  -ca-key=out/ca-key.pem \
  -config=ca-config.json \
  kube-proxy-csr.json | cfssljson -bare out/kube-proxy

# Generate client certificate for Kube Scheduler. It is used by the scheduler to access other kube-* 
# servers
cfssl gencert \
  -ca=out/ca.pem \
  -ca-key=out/ca-key.pem \
  -config=ca-config.json \
  kube-scheduler-csr.json | cfssljson -bare out/kube-scheduler

# Generate server certificate for Kube API Server. This certificate will be verified by connecting 
# kube-* clients
cfssl gencert \
  -ca=out/ca.pem \
  -ca-key=out/ca-key.pem \
  -config=ca-config.json \
  kube-apiserver-csr.json | cfssljson -bare out/kube-apiserver

# Generate service account 
cfssl gencert \
  -ca=out/ca.pem \
  -ca-key=out/ca-key.pem \
  -config=ca-config.json \
  service-account-csr.json | cfssljson -bare out/service-account