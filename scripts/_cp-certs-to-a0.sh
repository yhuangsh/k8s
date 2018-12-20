#!/bin/sh

ssh huang@a0 mkdir -p /home/huang/k8s/certs/out
scp certs/out/* huang@a0:/home/huang/k8s/certs/out