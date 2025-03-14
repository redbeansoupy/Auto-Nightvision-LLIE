#!/bin/bash

free_swap=$(free -m | awk '/Swap:/ {print $4}')
if [ $free_swap -ge 8600 ]; then
    printf "sufficient swap space. skipping swap space increase\n"
else
    printf "increasing swap space... this will take a few minutes...\n" 
    sudo swapoff -a
    sudo dd if=/dev/zero of=/swapfile bs=1M count=16000
    sudo chmod 0600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    printf "completed swap space expansion\n"
fi

# export CUDA_LAUNCH_BLOCKING=1

sudo systemctl restart nvargus-daemon

python3 demo_mp.py

