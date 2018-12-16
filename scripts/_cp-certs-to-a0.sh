#!/bin/sh

ssh huang@a0.davidhuang.top mkdir -p /home/huang/k8s/certs/out
scp certs/out/* huang@a0.davidhuang.top:/home/huang/k8s/certs/out