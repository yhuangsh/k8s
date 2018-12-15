#!/bin/sh

CLUSTERNAME=k8s-davidhuang
CERTSDIR=certs/out
KUBECONFIG=kubeconfig/admin.kubeconfig

kubectl config set-cluster $CLUSTERNAME \
  --certificate-authority=$CERTSDIR/ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=$KUBECONFIG

kubectl config set-credentials admin \
  --client-certificate=$CERTSDIR/admin.pem \
  --client-key=$CERTSDIR/admin-key.pem \
  --embed-certs=true \
  --kubeconfig=$KUBECONFIG

kubectl config set-context default \
  --cluster=$CLUSTERNAME \
  --user=admin \
  --kubeconfig=$KUBECONFIG

kubectl config use-context default \
  --kubeconfig=$KUBECONFIG