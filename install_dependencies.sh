#!/bin/bash

# function
prompt_yn() {
    while true; do
        read -p "[y/n]: " response
        case "$response" in 
            [yY]) printf "proceeding!\n"; return 0;;
            [nN]) printf "exiting...\n"; return 1;; 
            *) printf "please enter y or n --> "
        esac
    done
}


# Check Ubuntu 20.04 is installed
ubuntu_version=$(lsb_release -sr)
if [[ "$ubuntu_version" != "20.04" ]]; then
    printf "Please use the prebuilt image that can be found here: \n\n"
    printf "https://github.com/Qengineering/Jetson-Nano-Ubuntu-20-image \n"
    exit 1
fi 

# Check that Python 3.8 is installed
python_version=$(python3 -V)
if [[ "$python_version" != "Python 3.8.10" ]]; then
    printf "Please use the prebuilt image that can be found here: \n\n"
    printf "https://github.com/Qengineering/Jetson-Nano-Ubuntu-20-image \n"
    exit 1
fi 

printf "now installing jetson packages (pytorch, torchvision, opencv)\n"
printf "this script will automatically say 'yes' to all new installations. if this is not okay, please install manually using the guide. continue? "
prompt_yn || exit 0 # execute prompt and exit if response is no
echo "the entire process can take 4 hours. you can let this run and there may be one user input at the very end."
cd ~/Downloads

# Add OPENBLAS_CORETYPE=ARMV8 to the end of .bashrc
openblas_set=$(grep OPENBLAS_CORETYPE ~/.bashrc)
if [[ "$openblas_set" != "export OPENBLAS_CORETYPE=ARMV8" ]]; then
	echo "export OPENBLAS_CORETYPE=ARMV8" >> ~/.bashrc
fi

export OPENBLAS_CORETYPE=ARMV8 # for good measure


# Install PyTorch 1.11 using wheel from Qengineering
# This is an exact copy of the tutorial here: https://qengineering.eu/install-pytorch-on-jetson-nano.html plus the version check
printf "checking pytorch version... this may take a minute...\n"
pytorch_version=$(python3 -c "import torch; print(torch.__version__)" 2>/dev/null)
if [[ "$pytorch_version" = "1.11.0a0+gitbc2c6ed" ]]; then
    printf "correct version of pytorch already installed. skipping installation\n"
else
    # Check if wheel is downloaded first
    if test -f "torch-1.11.0a0+gitbc2c6ed-cp38-cp38-linux_aarch64.whl"; then
        printf "installing pytorch 1.11.0\n"
    else
        printf "Please download the PyTorch wheel file from https://drive.google.com/uc?id=1AQQuBS9skNk1mgZXMp0FmTIwjuxc81WY to the Downloads folder and run again.\n"
        exit 0
    fi
    
    sudo apt-get install -y python3-pip libjpeg-dev libopenblas-dev libopenmpi-dev libomp-dev
    sudo -H pip3 install future
    sudo pip3 install -U --user wheel mock pillow
    sudo -H pip3 install testresources
    sudo -H pip3 install setuptools==58.3.0
    sudo -H pip3 install Cython
    sudo -H pip3 install torch-1.11.0a0+gitbc2c6ed-cp38-cp38-linux_aarch64.whl
    rm torch-1.11.0a0+gitbc2c6ed-cp38-cp38-linux_aarch64.whl
fi

# Install Torchvision 0.12.0 using wheel from Qengineering (same tutorial)
printf "checking torchvision version...\n"
tv_version=$(python3 -c "import torchvision; print(torchvision.__version__)" 2>/dev/null)
if [[ "$tv_version" = "0.12.0a0+9b5a3fe" ]]; then
    printf "correct version of torchvision already installed. skipping installation\n"
else
    # Check if wheel is downloaded first
    if test -f "torchvision-0.12.0a0+9b5a3fe-cp38-cp38-linux_aarch64.whl"; then
        printf "installing torchvision 0.12.0\n"
    else
        printf "Please download the torchvision wheel file from https://drive.google.com/uc?id=1BaBhpAizP33SV_34-l3es9MOEFhhS1i2 to the Downloads folder and run again.\n"
        exit 0
    fi

    sudo apt-get install -y zlib1g-dev libpython3-dev
    sudo apt-get install -y libavcodec-dev libavformat-dev libswscale-dev
    sudo -H pip3 install torchvision-0.12.0a0+9b5a3fe-cp38-cp38-linux_aarch64.whl
    rm torchvision-0.12.0a0+9b5a3fe-cp38-cp38-linux_aarch64.whl
fi

# Install OpenCV
# This entire script is ripped from the Qengineering installation tutorial, but removed the package that is not available for Ubuntu 20.04 (v4l2ucp) and added swap space increase

set -e
install_opencv () {
  # Check if the file /proc/device-tree/model exists
  if [ -e "/proc/device-tree/model" ]; then
      # Read the model information from /proc/device-tree/model and remove null bytes
      model=$(tr -d '\0' < /proc/device-tree/model)
      # Check if the model information contains "Jetson Nano Orion"
      echo ""
      if [[ $model == *"Orin"* ]]; then
          echo "Detecting a Jetson Nano Orin."
	  # Use always "-j 4"
          NO_JOB=4
          ARCH=8.7
          PTX="sm_87"
      elif [[ $model == *"Jetson Nano"* ]]; then
          echo "Detecting a regular Jetson Nano."
          ARCH=5.3
          PTX="sm_53"
	  # Use "-j 4" only swap space is larger than 5.5GB
	  FREE_MEM="$(free -m | awk '/^Swap/ {print $2}')"
	  if [[ "FREE_MEM" -gt "5500" ]]; then
	    NO_JOB=4
	  else
	    echo "Due to limited swap, make only uses 1 core"
	    NO_JOB=1
	  fi
      else
          echo "Unable to determine the Jetson Nano model."
          exit 1
      fi
      echo ""
  else
      echo "Error: /proc/device-tree/model not found. Are you sure this is a Jetson Nano?"
      exit 1
  fi
  
  # Prepare to install OpenCV
  #   increase swap space to 10GB
  #   source: https://askubuntu.com/questions/178712/how-to-increase-swap-space
  free_swap=$(free -m | awk '/Swap:/ {print $4}')
  if [ $free_swap -ge 86000 ]; then
    printf "sufficient swap space. skipping swap space increase\n"
  else
    printf "increasing swap space... this will take a few minutes...\n" 
    sudo swapoff -a
    sudo dd if=/dev/zero of=/swapfile bs=1M count=10240
    sudo chmod 0600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    printf "completed swap space expansion\n"
  fi
  
  echo "Installing OpenCV 4.11.0 on your Nano"
  echo "It will take 3.5 hours !"
  
  # reveal the CUDA location
  cd ~
  sudo sh -c "echo '/usr/local/cuda/lib64' >> /etc/ld.so.conf.d/nvidia-tegra.conf"
  sudo ldconfig
  
  # install the Jetson Nano dependencies first
  if [[ $model == *"Jetson Nano"* ]]; then
    sudo apt-get install -y build-essential git unzip pkg-config zlib1g-dev
    sudo apt-get install -y python3-dev python3-numpy
    sudo apt-get install -y python-dev python-numpy
    sudo apt-get install -y gstreamer1.0-tools libgstreamer-plugins-base1.0-dev
    sudo apt-get install -y libgstreamer1.0-dev libgstreamer-plugins-good1.0-dev
    sudo apt-get install -y libtbb2 libgtk-3-dev libxine2-dev
  fi
  
  if [ -f /etc/os-release ]; then
      # Source the /etc/os-release file to get variables
      . /etc/os-release
      # Extract the major version number from VERSION_ID
      VERSION_MAJOR=$(echo "$VERSION_ID" | cut -d'.' -f1)
      # Check if the extracted major version is 22 or earlier
      if [ "$VERSION_MAJOR" = "22" ]; then
          sudo apt-get install -y libswresample-dev libdc1394-dev
      else
	  sudo apt-get install -y libavresample-dev libdc1394-22-dev
      fi
  else
      sudo apt-get install -y libavresample-dev libdc1394-22-dev
  fi

  # install the common dependencies
  sudo apt-get install -y cmake
  sudo apt-get install -y libjpeg-dev libjpeg8-dev libjpeg-turbo8-dev
  sudo apt-get install -y libpng-dev libtiff-dev libglew-dev
  sudo apt-get install -y libavcodec-dev libavformat-dev libswscale-dev
  sudo apt-get install -y libgtk2.0-dev libgtk-3-dev libcanberra-gtk*
  sudo apt-get install -y python3-pip
  sudo apt-get install -y libxvidcore-dev libx264-dev
  sudo apt-get install -y libtbb-dev libxine2-dev
  sudo apt-get install -y libv4l-dev v4l-utils qv4l2
  sudo apt-get install -y libtesseract-dev libpostproc-dev
  sudo apt-get install -y libvorbis-dev
  sudo apt-get install -y libfaac-dev libmp3lame-dev libtheora-dev
  sudo apt-get install -y libopencore-amrnb-dev libopencore-amrwb-dev
  sudo apt-get install -y libopenblas-dev libatlas-base-dev libblas-dev
  sudo apt-get install -y liblapack-dev liblapacke-dev libeigen3-dev gfortran
  sudo apt-get install -y libhdf5-dev libprotobuf-dev protobuf-compiler
  sudo apt-get install -y libgoogle-glog-dev libgflags-dev
 
  # remove old versions or previous builds
  cd ~ 
  sudo rm -rf opencv*
  # download the latest version
  git clone --depth=1 https://github.com/opencv/opencv.git
  git clone --depth=1 https://github.com/opencv/opencv_contrib.git
  
  # set install dir
  cd ~/opencv
  mkdir build
  cd build
  
  # run cmake
  cmake -D CMAKE_BUILD_TYPE=RELEASE \
  -D CMAKE_INSTALL_PREFIX=/usr \
  -D OPENCV_EXTRA_MODULES_PATH=~/opencv_contrib/modules \
  -D EIGEN_INCLUDE_PATH=/usr/include/eigen3 \
  -D WITH_OPENCL=OFF \
  -D CUDA_ARCH_BIN=${ARCH} \
  -D CUDA_ARCH_PTX=${PTX} \
  -D WITH_CUDA=ON \
  -D WITH_CUDNN=ON \
  -D WITH_CUBLAS=ON \
  -D ENABLE_FAST_MATH=ON \
  -D CUDA_FAST_MATH=ON \
  -D OPENCV_DNN_CUDA=ON \
  -D ENABLE_NEON=ON \
  -D WITH_QT=OFF \
  -D WITH_OPENMP=ON \
  -D BUILD_TIFF=ON \
  -D WITH_FFMPEG=ON \
  -D WITH_GSTREAMER=ON \
  -D WITH_TBB=ON \
  -D BUILD_TBB=ON \
  -D BUILD_TESTS=OFF \
  -D WITH_EIGEN=ON \
  -D WITH_V4L=ON \
  -D WITH_LIBV4L=ON \
  -D WITH_PROTOBUF=ON \
  -D OPENCV_ENABLE_NONFREE=ON \
  -D INSTALL_C_EXAMPLES=OFF \
  -D INSTALL_PYTHON_EXAMPLES=OFF \
  -D PYTHON3_PACKAGES_PATH=/usr/lib/python3/dist-packages \
  -D OPENCV_GENERATE_PKGCONFIG=ON \
  -D BUILD_EXAMPLES=OFF \
  -D CMAKE_CXX_FLAGS="-march=native -mtune=native" \
  -D CMAKE_C_FLAGS="-march=native -mtune=native" ..
 
  make -j ${NO_JOB} 
  
  directory="/usr/include/opencv4/opencv2"
  if [ -d "$directory" ]; then
    # Directory exists, so delete it
    sudo rm -rf "$directory"
  fi
  
  sudo make install
  sudo ldconfig
  
  # cleaning (frees 320 MB)
  make clean
  sudo apt-get update
  
  echo "Congratulations!"
  echo "You've successfully installed OpenCV 4.11.0 on your Nano"
  
  # Clean up swapfile and OpenCV
  swapoff -a
  sudo rm /swapfile
  
}

cd ~

# Check if already installed
cv_version=$(python3 -c "import cv2; print(cv2.__version__)" 2>/dev/null)
if [[ "$cv_version" = "4.12.0-dev" ]]; then
    printf "Correct version of OpenCV already installed. Skipping installation\n"
# Skipping check for existing opencv build since we already checked the version
#elif [ -d ~/opencv/build ]; then
  #echo " "
  #echo "You have a directory ~/opencv/build on your disk."
  #echo "Continuing the installation will replace this folder."
  #echo " "
  
  #printf "Do you wish to continue (Y/n)?"
  #read answer

  #if [ "$answer" != "${answer#[Nn]}" ] ;then 
      #echo "Leaving without installing OpenCV"
  #else
      #install_opencv
  #fi
else
    install_opencv
fi

# Install other dependencies for Retinexformer
pip3 install matplotlib scikit-learn scikit-image yacs joblib natsort h5py tqdm tensorboard
pip3 install einops addict future lmdb numpy==1.21.1 pyyaml requests scipy yapf lpips thop timm

# Install BasicSR in Retinexformer folder
# Check for existing Retinexformer github
if [ ! -d ~/Desktop/Retinexformer ]; then
	cd ~/Desktop
	git clone https://github.com/caiyuanhao1998/Retinexformer.git
fi
# Check for existing basicsr installation
basicsr_version=$(pip3 list | grep basicsr | awk '{print $2}')
if [[ "$basicsr_version" = "1.2.0-" ]]; then
        echo "basicsr already installed, skipping installation"
else
	echo "Installing BasicSR..."
	cd ~/Desktop/Retinexformer
	sudo OPENBLAS_CORETYPE=ARMV8 BASICSR_EXT=True python3 setup.py develop --no_cuda_ext
fi


echo "dependency installation completed!"

if [ -d ~/opencv ] || [ -d ~/opencv_contrib ]; then
	echo "Do you want to remove the OpenCV build folders to save some disk space?"
	prompt_yn || exit 0
	if [ -d ~/opencv ]; then sudo rm -rf ~/opencv; fi
	if [ -d ~/opencv_contrib ]; then sudo rm -rf ~/opencv_contrib; fi
	echo "finished removing opencv folders"
fi

exit 0

