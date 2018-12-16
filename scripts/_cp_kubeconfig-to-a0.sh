#!/bin/sh

ssh huang@a0.davidhuang.top mkdir -p /home/huang/k8s/kubeconfig/
scp kubeconfig/* huang@a0.davidhuang.top:/home/huang/k8s/kubeconfig