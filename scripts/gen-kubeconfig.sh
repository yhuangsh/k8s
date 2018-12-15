#!/bin/sh

rm kubeconfig/*
scripts/gen-kubeconfig-w0.sh
scripts/gen-kubeconfig-kube-proxy.sh
scripts/gen-kubeconfig-kube-controller-manager.sh
scripts/gen-kubeconfig-kube-scheduler.sh
scripts/gen-kubeconfig-admin.sh

