#!/bin/bash
# Generated using ChatGPT with minor tweaks
# This script runs test_from_dataset.py using each .pth model file found in the specified directory.
# For each model, it:
#   1. Runs a 5-second tegrastats pretest and saves the log.
#   2. Runs tegrastats concurrently with the test run (using the current .pth file as weights).
#   3. Stops tegrastats and parses both log files using read_tegrastats.py.
#   4. Labels the output files based on the model's filename.

# Directories (adjust these if necessary)
MODELS_DIR=~/Desktop/LLIE_models/LLIE_models/Structured
OUTPUT_DIR=~/Desktop/Auto-Nightvision-LLIE/multi_level_tests
TEST_SCRIPT_DIR=~/Desktop/Retinexformer

tegrastats --stop

# Loop over each .pth file in the models directory
for model in "$MODELS_DIR"/*.pth; do
    # Get the base name of the model without the .pth extension for labeling
    MODEL_NAME=$(basename "$model" .pth)
    echo "Running test for model: $MODEL_NAME"
    touch $OUTPUT_DIR/tegra_pretest_$MODEL_NAME.log
    touch $OUTPUT_DIR/tegra_test_$MODEL_NAME.log
    touch test_output_$MODEL_NAME.txt

    # Pretest: Run tegrastats for 5 seconds and log output
    echo "Starting tegrastats pretest..."
    timeout 5s tegrastats --logfile "$OUTPUT_DIR/tegra_pretest_$MODEL_NAME.log"
    echo "Pretest complete for model: $MODEL_NAME"
    
    # Change to the directory where the test script is located
    cd "$TEST_SCRIPT_DIR"
    
    # Start tegrastats logging for the test run
    echo "Starting tegrastats for test run..."
    tegrastats --start --logfile "$OUTPUT_DIR/tegra_test_$MODEL_NAME.log"
    
    # Run the test script using the current .pth model weights
    python3 Enhancement/test_from_dataset.py --opt Options/goober_LOL_v1.yml --weights "$model" --dataset LOLv1
    
    # Stop tegrastats logging
    tegrastats --stop
    echo "Test run complete for model: $MODEL_NAME; now parsing tegrastats output..."
    
    # Change back to the output directory
    cd "$OUTPUT_DIR"
    
    # Parse the pretest and test tegrastats log files and save output with the model label
    python3 ~/Desktop/Auto-Nightvision-LLIE/read_tegrastats.py "tegra_pretest_$MODEL_NAME.log" "tegra_test_$MODEL_NAME.log" > "test_output_$MODEL_NAME.txt"
    
    echo "Results for $MODEL_NAME saved in test_output_$MODEL_NAME.txt"
    echo "----------------------------------------------"
done

echo "All model tests complete."
