### Auto Nightvision LLIE

The way that we were able to successfully run Retinexformer involved reflashing the Jetson with a prebuilt image with Ubuntu 20.04 installed. Please consider backing up your files or manually upgrade to Ubuntu 20.04, but this was only tested using the prebuilt image. This also **does not use conda**. 

Last tested February 11th, 2025

## Quickstart
1. Download the prebuilt image from this github: https://github.com/Qengineering/Jetson-Nano-Ubuntu-20-image
	- macOS: I downloaded the split image, installed 7za with brew (```brew install 7za```) and re-zipped it using the command: ```7za x JetsonNanoUb20_3b.img.xz.001```
2. Flash the image onto your >=64GB SD card using BalenaEtcher or method of choice
	- The image comes with pre-installed Python 3.8 and many ML libraries but we need to replace most of these
3. Boot the Jetson Nano and clone this repository on the Jetson Nano.
4. Download the PyTorch and Torchvision wheels from the following links (from Qengineering)
	- PyTorch: https://drive.google.com/uc?id=1AQQuBS9skNk1mgZXMp0FmTIwjuxc81WY
	- Torchvision: https://drive.google.com/uc?id=1BaBhpAizP33SV_34-l3es9MOEFhhS1i2
5. In terminal, run the following:
    ```bash
    $ cd /path/to/Auto-Nightvision-LLIE
    $ sudo chmod +x install_dependencies.sh
    $ ./install_dependencies.sh
    ```
    This will take about 4 hours and only needs user input at the very beginning and end.
6. Download the desired dataset according to the Retinexformer README
7. Restart the terminal and test using the commands found in the Retinexformer README. For me, the LOLv1 test set (15 images) took 3 minutes.

## Steps to run Retinexformer on Jetson Nano:
1. Download the prebuilt image from this github: https://github.com/Qengineering/Jetson-Nano-Ubuntu-20-image
	- I downloaded the split image and re-zipped it using 7za on macOS and the command: 
	```7za x JetsonNanoUb_3b.img.xz.001```
2. Flash the image onto your >=64GB SD card using BalenaEtcher or method of choice
	- The image comes with pre-installed Python 3.8 and many ML libraries
3. Run gparted and extend the application memory to fill your entire card.
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
7. Install OpenCV 4.11.0 using this tutorial: https://qengineering.eu/install-opencv-on-jetson-nano.html
	- Using the dphys-swapfile did not work for me–please skip the dphys parts since we already increased swap space in step 6.
	- I edited the script to get rid of v4l2ucp because this is not supported by Ubuntu 20.04.
    - For Ubuntu 20.04, you do not need to uninstall OpenCV first.
8. Add ```export OPENBLAS_CORETYPE=ARMV8``` to the end of ~/.bashrc
    - This makes it so that you do not need to use ```export OPENBLAS_CORETYPE=ARMV8``` every time you run Python scripts.
9. Run ```git pull https://github.com/caiyuanhao1998/Retinexformer.git``` to download the Retinexformer github
10. Install BasicSR with these commands: 
    ```bash
    $ cd /path/to/Retinexformer
    $ sudo OPENBLAS_CORETYPE=ARMV8 BASICSR_EXT=True python3 setup.py develop --no_cuda_ext
    ```
11. Download your desired dataset and organize it as specified by Retinexformer
12. Restart the terminal and test using the commands found in the Retinexformer README. For me, the LOLv1 test set (15 images) took 3 minutes.
