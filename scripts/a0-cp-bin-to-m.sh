#!/bin/sh

echo "Copying binary files to m0"
ssh m0 mkdir -p /home/huang/_bin
scp bin/* m0:/home/huang/_bin

echo "Copying binary files to m1"
ssh m1 mkdir -p /home/huang/_bin
scp bin/* m1:/home/huang/_bin

echo "Copying binary files to m2"
ssh m2 mkdir -p /home/huang/_bin
scp bin/* m2:/home/huang/_bin
