# Auto Nightvision LLIE

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

## Scripts Included in Repository
### Demo Folder
- **demo.sh**: Checks for swap space and runs demo_mp.py (primary demo script)
    - If there is a camera error, in terminal, run ```nvgstcapture-1.0 sensor-id=N``` where N is the camera port used by the CSI flex-cable camera (read silkscreen on Jetson PCB). For IMX219, follow the instructions [here](https://github.com/pibiger-tech/picam-imx219).
- demo_mp.py: Multiprocessed demo of RetinexFormer on the camera stream. This was used for the final demo. This should be run from demo.sh and not on its own, because there are some requirements that demo.sh checks for.

The following files were not used in the final demo but show some of the works in progress used to make the final demo.
- demo.py: Uniprocessed demo of YOLOv11 on the camera stream
- simple_camera_yolo.py: The name is not descriptive but this includes a working demo of the camera stream into YOLO and blue color detection.
- yolo_mp.py: Multiprocessed demo of YOLOv11 on the camera stream.

### Main folder: Bash
These scripts may not work correctly immediately without changing file paths and the like. Please be forewarned!
- install_dependencies.sh: Installs dependencies for RetinexFormer (please see guide above)
- swapspace.sh: Increases swap space on Jetson Nano
- test_many.sh: Needs to be edited depending on file location of this repository and the RetinexFormer repository. Runs test script and parses tegrastats for many models.
- test_w_img_out.sh: Does the same thing as test_many.sh, but outputs images to a folder
- test.sh: Does the same thing as test_many.sh, but only for a single .pth file. Needs to be edited to use

### Main folder: Python
- test_from_dataset.py: Runs the RetinexFormer to YOLOv11 pipeline and calculates PSNR and SSIM
- test_from_dataset.py2: Runs only RetinexFormer and removed PSNR/SSIM calculation to test speed and resource usage for RetinexFormer alone. Can run pruned models on Jetson Nano.
- read_tegrastats.py: Parses tegrastats output and prints averages for each resource metric.  
    - Usage: ```python3 read_tegrastats.py \<pretest tegrastats log (optional)> [tegrastats log]```. The pretest will be subtracted from the main test if included.
- visualize.py: Provides code for generating graphs from tegrastats output

## Other files
The files in multi_level_tests are the results from benchmarking performance including PSNR calculation. Files ending in ".log" are simply tegrastats outputs, and files ending in ".txt" are the parse outputs from read_tegrastats.py

The files in tests_no_psnr are the results from benchmarking performance without PSNR/SSIM calculation. The naming convention is the same as in multi_level_tests.

The images in visualizations are some of the outputs from visualize.py.

The text files in terminal_logs are the printed outputs from test_from_dataset2.py, which we used to record inference time.
