#!/bin/bash

# function
prompt_yn() {
    while true; do
        read -p "continue? [y/n]: " response
        case "$response" in 
            [yY]) printf "proceeding!\n"; return 0;;
            [nN]) printf "exiting...\n"; return 1;; 
            *) printf "please enter y or n --> "
        esac
    done
}


# Check Ubuntu 20.04 is installed
ubuntu_version=$(lsb_release -sr)
if ["$ubuntu_version" != "20.04"]; then
    printf "Please use the prebuilt image that can be found here: \n\n"
    printf "https://github.com/Qengineering/Jetson-Nano-Ubuntu-20-image \n"
    exit 1
fi 

# Check that Python 3.8 is installed
python_version=$(python3 -V)
if ["$python_version" != "Python 3.8.4"]; then
    printf "Please use the prebuilt image that can be found here: \n\n"
    printf "https://github.com/Qengineering/Jetson-Nano-Ubuntu-20-image \n"
    exit 1
fi 

printf "now installing jetson packages (pytorch, torchvision, opencv)\n"
printf "this script will automatically say 'yes' to all new installations. if this is not okay, please install manualling using the guide. \n"
prompt_yn || exit 0 # execute prompt and exit if response is no
cd ~/Downloads

# Install PyTorch 1.11 using wheel from Qengineering
# This is an exact copy of the tutorial here: https://qengineering.eu/install-pytorch-on-jetson-nano.html plus the version check
printf "checking pytorch version... this may take a minute...\n"
pytorch_verson=$(python3 -c "import torch; print(torch.__version__)")
if ["$pytorch_version" = "1.11.0"]; then
    printf "correct version of pytorch already installed. skipping installation\n"
else
    printf "installing pytorch 1.11.0\n"
    sudo apt-get install -y python3-pip libjpeg-dev libopenblas-dev libopenmpi-dev libomp-dev
    sudo -H pip3 install -y future
    sudo pip3 install -U --user -y wheel mock pillow
    sudo -H pip3 install -y testresources
    sudo -H pip3 install -y --allow-downgrades setuptools==58.3.0
    sudo -H pip3 install -y Cython
    gdown https://drive.google.com/uc?id=1AQQuBS9skNk1mgZXMp0FmTIwjuxc81WY
    sudo -H pip3 install -y --allow-downgrades torch-1.11.0a0+gitbc2c6ed-cp38-cp38-linux_aarch64.whl
    rm torch-1.11.0a0+gitbc2c6ed-cp38-cp38-linux_aarch64.whl
fi

# Install Torchvision 0.12.0 using wheel from Qengineering (same tutorial)
printf "checking torchvision version...\n"
pytorch_verson=$(python3 -c "import torch; print(torch.__version__)")
if ["$pytorch_version" = "0.12.0"]; then
    printf "correct version of torchvision already installed. skipping installation\n"
else
    printf "installing torchvision 0.12.0\n"
sudo apt-get install -y zlib1g-dev libpython3-dev
sudo apt-get install -y libavcodec-dev libavformat-dev libswscale-dev
gdown https://drive.google.com/uc?id=1BaBhpAizP33SV_34-l3es9MOEFhhS1i2
sudo -H pip3 install -y --allow-downgrades torchvision-0.12.0a0+9b5a3fe-cp38-cp38-linux_aarch64.whl
rm torchvision-0.12.0a0+9b5a3fe-cp38-cp38-linux_aarch64.whl

# Prepare to install OpenCV
#   increase swap space to 10GB
#   source: https://askubuntu.com/questions/178712/how-to-increase-swap-space
printf "increasing swap space... this will take a few minutes...\n" 
sudo swapoff -a
sudo dd if=/dev/zero of=/swapfile bs=1M count=10240
sudo chmod 0600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
printf "completed swap space expansion\n"

#   uninstall opencv
