#!/bin/sh

echo "Copying binary files to w0"
ssh w0 mkdir -p /home/huang/_bin
scp bin/*.deb w0:/home/huang/_bin

echo "Copying binary files to w1"
ssh w1 mkdir -p /home/huang/_bin
scp bin/*.deb w1:/home/huang/_bin

echo "Copying binary files to w2"
ssh w2 mkdir -p /home/huang/_bin
scp bin/*.deb w2:/home/huang/_bin
