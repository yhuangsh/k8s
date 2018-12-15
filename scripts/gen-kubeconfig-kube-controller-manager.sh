#!/bin/sh

CLUSTERNAME=k8s-davidhuang
CERTSDIR=certs/out
KUBECONFIG=kubeconfig/kube-controller-manager.kubeconfig

kubectl config set-cluster $CLUSTERNAME \
  --certificate-authority=$CERTSDIR/ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=$KUBECONFIG

kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=$CERTSDIR/kube-controller-manager.pem \
  --client-key=$CERTSDIR/kube-controller-manager-key.pem \
  --embed-certs=true \
  --kubeconfig=$KUBECONFIG

kubectl config set-context default \
  --cluster=$CLUSTERNAME \
  --user=system:kube-controller-manager \
  --kubeconfig=$KUBECONFIG

kubectl config use-context default \
  --kubeconfig=$KUBECONFIG