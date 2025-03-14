sudo swapoff -a
sudo dd if=/dev/zero of=/swapfile bs=1M count=16000
sudo chmod 0600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
printf "completed swap space expansion\n"
