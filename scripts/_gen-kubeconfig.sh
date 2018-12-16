#!/bin/sh

rm kubeconfig/*
scripts/_gen-kubeconfig-w0.sh
scripts/_gen-kubeconfig-kube-proxy.sh
scripts/_gen-kubeconfig-kube-controller-manager.sh
scripts/_gen-kubeconfig-kube-scheduler.sh
scripts/_gen-kubeconfig-admin.sh

