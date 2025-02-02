#!/bin/bash
# This runs a test script with tegrastats in the background
# I haven't made this usable for arbitrary script yet but I could do it if necessary

# Needed in general but I set this permanently on the Jetson
# export OPENBLAS_CORETYPE=ARMV8

# Run tegrastats for 5 seconds
# File is located on jetson nano
echo tegrastats pretest...
timeout 5s tegrastats --logfile ~/Desktop/Auto-Nightvision-LLIE/tegra_pretest.log
echo pretest complete!

Run tegrastats while running test script from Retinexformer
cd ~/Desktop/Retinexformer
echo tegrastats started...
tegrastats --start --logfile ~/Desktop/Auto-Nightvision-LLIE/tegra_test.log
timeout 180s python3 Enhancement/test_from_dataset.py --opt Options/RetinexFormer_LOL_v1.yml --weights pretrained_weights/LOL_v1.pth --dataset LOL_v1
tegrastats --stop
echo test complete, parsing output

# Parse log files and print averages using python script
cd ~/Desktop/Auto-Nightvision-LLIE
python3 read_tegrastats.py tegra_pretest.log tegra_test.log > ~/Desktop/Auto-Nightvision-LLIE/test_output.txt

