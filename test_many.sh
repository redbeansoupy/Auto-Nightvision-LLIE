#!/bin/bash
# Generated using ChatGPT with minor tweaks
# This script runs test_from_dataset.py using each .pth model file found in the specified directory.
# For each model, it:
#   1. Runs tegrastats concurrently with the test run (using the current .pth file as weights).
#   2. Stops tegrastats and parses both log files using read_tegrastats.py.
#   3. Labels the output files based on the model's filename.
# Optionally, the pretest section can be uncommented to subtract the OS resource usage from the inference resource usage

# Directories (adjust these if necessary)
MODEL_DIRS=(~/Desktop/LLIE_models/LLIE_models/Structured ~/Desktop/LLIE_models/LLIE_models/Unstructured/Global ~/Desktop/LLIE_models/LLIE_models/Unstructured/Local)
OUTPUT_DIRS=(~/Desktop/Auto-Nightvision-LLIE/tests_no_psnr/structured ~/Desktop/Auto-Nightvision-LLIE/tests_no_psnr/unstructured/global ~/Desktop/Auto-Nightvision-LLIE/tests_no_psnr/unstructured/local)
TEST_SCRIPT_DIR=~/Desktop/Retinexformer
SCRIPT_LOCATION=~/Desktop/Auto-Nightvision-LLIE

echo "model directories: ${MODEL_DIRS[0]} ${MODEL_DIRS[1]} ${MODEL_DIRS[2]}"
echo "output directories: ${OUTPUT_DIRS[0]} ${OUTPUT_DIRS[1]} ${OUTPUT_DIRS[2]}"

tegrastats --stop

for i in ${!MODEL_DIRS[@]}; do
    MODEL_DIR=${MODEL_DIRS[$i]}
    OUTPUT_DIR=${OUTPUT_DIRS[$i]}
    
    echo "Testing models in $MODEL_DIR > $OUTPUT_DIR"

    # Loop over each .pth file in the models directory
    for model in "$MODEL_DIR"/*.pth; do
        # Get the base name of the model without the .pth extension for labeling
        MODEL_NAME=$(basename "$model" .pth)
        echo "Running test for model: $MODEL_NAME in $MODEL_DIR"

        # Create log files
        # touch "$OUTPUT_DIR/tegra_pretest_$MODEL_NAME.log"
        touch "$OUTPUT_DIR/tegra_test_$MODEL_NAME.log"
        touch "output_$MODEL_NAME.txt"

        # # Pretest: Run tegrastats for 5 seconds and log output
        # echo "Starting tegrastats pretest..."
        # timeout 5s tegrastats --logfile "$OUTPUT_DIR/tegra_pretest_$MODEL_NAME.log"
        # echo "Pretest complete for model: $MODEL_NAME"
        
        # Change to the directory where the test script is located
        cd "$TEST_SCRIPT_DIR"
        
        # Start tegrastats logging for the test run
        echo "Starting tegrastats for test run..."
        tegrastats --start --logfile "$OUTPUT_DIR/tegra_test_$MODEL_NAME.log"
        
        # Run the test script using the current .pth model weights
        python3 Enhancement/test_from_dataset2.py --opt Options/goober_LOL_v1.yml --weights "$model" --dataset LOLv1
        
        # Stop tegrastats logging
        tegrastats --stop
        
        cd "$OUTPUT_DIR"
        # python3 ~/Desktop/Auto-Nightvision-LLIE/read_tegrastats.py tegra_pretest_$MODEL_NAME.log tegra_test_$MODEL_NAME.log > output_$MODEL_NAME.txt
	    python3 $SCRIPT_LOCATION/read_tegrastats.py tegra_test_$MODEL_NAME.log > output_$MODEL_NAME.txt
        echo "Test run complete for model: $MODEL_NAME in $MODEL_DIR"
    done
done



echo "All model tests complete."
