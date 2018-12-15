#!/bin/sh

CLUSTERNAME=k8s-davidhuang
CERTSDIR=certs/out
KUBECONFIG=kubeconfig/kube-scheduler.kubeconfig

kubectl config set-cluster $CLUSTERNAME \
  --certificate-authority=$CERTSDIR/ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=$KUBECONFIG

kubectl config set-credentials system:kube-scheduler \
  --client-certificate=$CERTSDIR/kube-scheduler.pem \
  --client-key=$CERTSDIR/kube-scheduler-key.pem \
  --embed-certs=true \
  --kubeconfig=$KUBECONFIG

kubectl config set-context default \
--cluster=$CLUSTERNAME \
--user=system:kube-scheduler \
--kubeconfig=$KUBECONFIG

kubectl config use-context default \
  --kubeconfig=$KUBECONFIG

