#!/bin/sh

ssh m0 mkdir -p /home/huang/_scripts
ssh m1 mkdir -p /home/huang/_scripts
ssh m2 mkdir -p /home/huang/_scripts

echo "Copying certs and scripts files to w0"
scp scripts/w-* w0:/home/huang/_scripts
ssh m0 chmod +x _scripts/*

echo "Copying certs and scripts files to w1"
scp scripts/w-* w1:/home/huang/_scripts
ssh m1 chmod +x _scripts/*

echo "Copying certs and scripts files to w2"
scp scripts/w-* w2:/home/huang/_scripts
ssh m2 chmod +x _scripts/*
