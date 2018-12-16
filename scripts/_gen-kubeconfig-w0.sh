#!/bin/sh

WORKERNAME=w0
TARGET_MASTER=https://m0:6443 

CLUSTERNAME=k8s-davidhuang
CERTSDIR=certs/out
KUBECONFIG=kubeconfig/$WORKERNAME.kubeconfig

kubectl config set-cluster $CLUSTERNAME \
  --certificate-authority=$CERTSDIR/ca.pem \
  --embed-certs \
  --server=$TARGET_MASTER \
  --kubeconfig=$KUBECONFG

kubectl config set-credentials system:node:$WORKERNAME \
  --client-certificate=$CERTSDIR/$WORKERNAME.pem \
  --client-key=$CERTSDIR/$WORKERNAME-key.pem \
  --embed-certs=true \
  --kubeconfig=$KUBECONFIG

kubectl config set-context default \
  --cluster=$CLUSTERNAME\
  --user=system:node:$WORKERNAME \
  --kubeconfig=$KUBECONFIG

kubectl config use-context default \
  --kubeconfig=$KUBECONFIG