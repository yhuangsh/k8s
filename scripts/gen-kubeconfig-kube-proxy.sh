#!/bin/sh

CLUSTERNAME=k8s-davidhuang
CERTSDIR=certs/out
KUBECONFIG=kubeconfig/kube-proxy.kubeconfig

kubectl config set-cluster $CLUSTERNAME \
  --certificate-authority=$CERTSDIR/ca.pem \
  --embed-certs=true \
  --server=https://m0:6443 \
  --kubeconfig=$KUBECONFIG

  kubectl config set-credentials system:kube-proxy \
    --client-certificate=$CERTSDIR/kube-proxy.pem \
    --client-key=$CERTSDIR/kube-proxy-key.pem \
    --embed-certs=true \
    --kubeconfig=$KUBECONFIG

  kubectl config set-context default \
    --cluster=$CLUSTERNAME \
    --user=system:kube-proxy \
    --kubeconfig=$KUBECONFIG

  kubectl config use-context default \
    --kubeconfig=$KUBECONFIG