#!/bin/bash
# Generated using ChatGPT with minor tweaks
# This script runs test_from_dataset.py using each .pth model file found in the specified directory.
# For each model, it:
#   1. Runs a 5-second tegrastats pretest and saves the log.
#   2. Runs tegrastats concurrently with the test run (using the current .pth file as weights).
#   3. Stops tegrastats and parses both log files using read_tegrastats.py.
#   4. Labels the output files based on the model's filename.

# Directories (adjust these if necessary)
MODELS_DIR=~/Desktop/LLIE_models/LLIE_models/Unstructured/Global
OUTPUT_DIR=~/Desktop/Auto-Nightvision-LLIE/multi_level_tests
TEST_SCRIPT_DIR=~/Desktop/Retinexformer

tegrastats --stop

# Loop over each .pth file in the models directory
for model in "$MODELS_DIR"/*.pth; do
    # Get the base name of the model without the .pth extension for labeling
    MODEL_NAME=$(basename "$model" .pth)
    echo "Running test for model: $MODEL_NAME"
    
    # Change to the directory where the test script is located
    cd "$TEST_SCRIPT_DIR"
    
    # Run the test script using the current .pth model weights
    mkdir -p ~/Desktop/output_imgs/$MODEL_NAME
    timeout 180 python3 Enhancement/test_from_dataset.py --opt Options/goober_LOL_v1.yml --weights "$model" --dataset LOLv1 --output_dir "/home/jetson/Desktop/output_imgs/$MODEL_NAME"
    
    if [ -z "$( ls -A ~/Desktop/output_imgs/$MODEL_NAME )" ]; then
    	echo "Images did not save"
    	exit 1
    fi
    echo "Test run complete for model: $MODEL_NAME"
    echo "----------------------------------------------"
done

echo "All model tests complete."
