#!/bin/sh

ssh m0 mkdir -p /home/huang/_certs
ssh m0 mkdir -p /home/huang/_kubeconfig
ssh m0 mkdir -p /home/huang/_yaml
ssh m0 mkdir -p /home/huang/_scripts

ssh m1 mkdir -p /home/huang/_certs
ssh m1 mkdir -p /home/huang/_kubeconfig
ssh m1 mkdir -p /home/huang/_yaml
ssh m1 mkdir -p /home/huang/_scripts

ssh m2 mkdir -p /home/huang/_certs
ssh m2 mkdir -p /home/huang/_kubeconfig
ssh m2 mkdir -p /home/huang/_yaml
ssh m2 mkdir -p /home/huang/_scripts

echo "Copying files to m0"
scp certs/out/* m0:/home/huang/_certs
scp kubeconfig/admin.kubeconfig \
    kubeconfig/kube-controller-manager.kubeconfig \
    kubeconfig/kube-scheduler.kubeconfig \
    m0:/home/huang/_kubeconfig
scp yaml/* m0:/home/huang/_yaml
scp scripts/m-* m0:/home/huang/_scripts
scp scripts/m0* m0:/home/huang/_scripts

echo "Copying files to m1"
scp certs/out/* m1:/home/huang/_certs
scp kubeconfig/admin.kubeconfig \
    kubeconfig/kube-controller-manager.kubeconfig \
    kubeconfig/kube-scheduler.kubeconfig \
    m1:/home/huang/_kubeconfig
scp yaml/* m1:/home/huang/_yaml
scp scripts/m-* m0:/home/huang/_scripts
scp scripts/m1* m1:/home/huang/_scripts

echo "Copying files to m2"
scp certs/out/* m2:/home/huang/_certs
scp kubeconfig/admin.kubeconfig \
    kubeconfig/kube-controller-manager.kubeconfig \
    kubeconfig/kube-scheduler.kubeconfig \
    m2:/home/huang/_kubeconfig
scp yaml/* m2:/home/huang/_yaml
scp scripts/m-* m0:/home/huang/_scripts
scp scripts/m2* m2:/home/huang/_scripts

