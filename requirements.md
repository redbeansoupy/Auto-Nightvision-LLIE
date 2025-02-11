The way that we were able to successfully run Retinexformer involved reflashing the Jetson with a prebuilt image with Ubuntu 20.04 installed. Please consider backing up your files somewhere besides the Jetson or manually upgrade to Ubuntu 20.04. This also does not use conda. 

Last tested February 10th, 2025

## Quickstart
1. Download the prebuilt image from this github: https://github.com/Qengineering/Jetson-Nano-Ubuntu-20-image
	- I downloaded the split image and re-zipped it using 7za on macOS and the command: ```7za x JetsonNanoUb_3b.img.xz.001```
2. Flash the image onto your >=64GB SD card using BalenaEtcher or method of choice
	- The image comes with pre-installed Python 3.8 and many ML libraries
3. Boot the Jetson Nano and run ```sudo apt install gparted; gparted```, and resize the main partition to fill the entire available space.
4. Run install_dependencies.sh with root permissions. This should only be done on a freshly flashed card. It will take about 4 hours.
5. Download the desired dataset according to the Retinexformer README
6. Test using the commands found in the Retinexformer README

## Steps to run Retinexformer on Jetson Nano:
1. Download the prebuilt image from this github: https://github.com/Qengineering/Jetson-Nano-Ubuntu-20-image
	- I downloaded the split image and re-zipped it using 7za on macOS and the command: 
	```7za x JetsonNanoUb_3b.img.xz.001```
2. Flash the image onto your >=64GB SD card using BalenaEtcher or method of choice
	- The image comes with pre-installed Python 3.8 and many ML libraries
3. Boot the Jetson Nano and run ```sudo apt install gparted; gparted```, and resize the main partition to fill the entire available space.
4. Install PyTorch 1.11.0 using this tutorial: https://qengineering.eu/install-pytorch-on-jetson-nano.html
5. Install the matching torchvision wheel (0.12.0) using this tutorial: https://qengineering.eu/install-pytorch-on-jetson-nano.html
6. Increase the swap space to 10GB using the following commands:
    ```bash
    $ sudo swapoff -a
    $ sudo dd if=/dev/zero of=/swapfile bs=1M count=10240
    $ sudo chmod 0600 /swapfile
    $ sudo mkswap /swapfile
    $ sudo swapon /swapfile
    ```
7. **NEED TO CHECK:** Uninstall the pre-installed version of OpenCV using pip3 uninstall python3-opencv
8. Install OpenCV 4.11.0 using this tutorial: https://qengineering.eu/install-opencv-on-jetson-nano.html
	- Using the dphys-swapfile did not work for me–please skip the dphys parts since we already increased swap space in step 6.
	- I edited the script to get rid of 74something because this is not supported by Ubuntu 20.04.
9. Add ```export OPENBLAS_CORETYPE=ARMV8``` to the end of ~/.bashrc
    - This makes it so that you do not need to use ```export OPENBLAS_CORETYPE=ARMV8``` every time you run Python scripts.
10. Run ```git pull https://github.com/caiyuanhao1998/Retinexformer.git``` to download the Retinexformer github
11. Install BasicSR with these commands: 
    ```bash
    $ cd /path/to/Retinexformer
    $ sudo OPENBLAS_CORETYPE=ARMV8 BASICSR_EXT=True python3 setup.py develop --no_cuda_ext
    ```
12. Download your desired dataset and organize it as specified by Retinexformer
13. Run test script. 
