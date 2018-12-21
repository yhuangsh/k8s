#!/bin/sh

echo "Copying binary files to m0"
ssh w0 mkdir -p /home/huang/_bin
scp bin/* w0:/home/huang/_bin

echo "Copying binary files to m1"
ssh w1 mkdir -p /home/huang/_bin
scp bin/* w1:/home/huang/_bin

echo "Copying binary files to m2"
ssh w2 mkdir -p /home/huang/_bin
scp bin/* w2:/home/huang/_bin
