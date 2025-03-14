#!/bin/bash
# MIT License
# Copyright (c) 2019-2022 JetsonHacks

# Using a CSI camera (such as the Raspberry Pi Version 2) connected to a
# NVIDIA Jetson Nano Developer Kit using OpenCV
# Drivers for the camera and OpenCV are included in the base image

import cv2
from ultralytics import YOLO

# RetinexFormer requirements
import numpy as np
import torch.nn as nn
import torch
import yaml
from yaml import Loader

import time
import multiprocessing as mp
import os

""" 
gstreamer_pipeline returns a GStreamer pipeline for capturing from the CSI camera
Flip the image by setting the flip_method (most common values: 0 and 2)
display_width and display_height determine the size of each camera pane in the window on the screen
Default 1920x1080 displayd in a 1/4 size window
"""

window_title_cam = "CSI Camera"
window_title_yolo = "YOLO output"

def gstreamer_pipeline(
    sensor_id=0,
    capture_width=1280,
    capture_height=720,
    display_width=640,
    display_height=360,
    framerate=2,
    flip_method=2,
):
    return (
        "nvarguscamerasrc exposuretimerange='33333 33333' aelock=true sensor-id=%d ! "
        "video/x-raw(memory:NVMM), width=(int)%d, height=(int)%d, framerate=(fraction)%d/1 ! "
        "nvvidconv flip-method=%d ! "
        "video/x-raw, width=(int)%d, height=(int)%d, format=(string)BGRx ! "
        "videoconvert ! "
        "video/x-raw, format=(string)BGR ! "
        "appsink "
        % (
            sensor_id,
            capture_width,
            capture_height,
            framerate,
            flip_method,
            display_width,
            display_height,
        )
    )

def load_retinexformer():
    from basicsr.models import create_model
    from basicsr.utils.options import dict2str, parse
    print("check pid loading retinexformer: ", os.getpid())

    yaml_file = "RetinexFormer_LOL_v1.yml"
    # weights_file = "LOL_v1.pth"
    weights_file = "/home/jetson/Desktop/LLIE_models/LLIE_models/Structured/90_ninf_dim1.pth"
    
    opt = parse(yaml_file, is_train=False)
    opt['dist'] = False

    x = yaml.load(open(yaml_file, mode='r'), Loader=Loader)
    s = x['network_g'].pop('type')

    model_restoration = create_model(opt).net_g
    checkpoint = torch.load(weights_file)

    if 'params' in checkpoint:
        model_restoration.load_state_dict(checkpoint['params'])
    else:
        model_restoration.load_state_dict(checkpoint, strict=False) # For pruned models

    return model_restoration

def inference_process(frame_queue):
    # BasicSR needs to be initialized *after* the video capture or else video capture will not work
    print("check process number: ", os.getpid())

    # Load models
    print("Loading models...")
    # model_retinexformer = load_retinexformer()
    model_yolo = YOLO("/home/jetson/Desktop/yolo11n.pt")
    print("Completed loading models!")

    window_handle = cv2.namedWindow(window_title_cam, cv2.WINDOW_AUTOSIZE)
    window_handle2 = cv2.namedWindow(window_title_yolo, cv2.WINDOW_AUTOSIZE)

    while True:
        frame = frame_queue.get()
        if frame is None:  # Shutdown signal
            break
        
        original_frame = frame.copy()
        start = time.time()

        # # Run RetinexFormer on this frame
        # # Code adapted from test_from_dataset.py
        # with torch.no_grad():
           # torch.cuda.ipc_collect()
           # torch.cuda.empty_cache()

           # img = np.float32(frame) / 255.0
           # img = torch.from_numpy(img).permute(2, 0, 1)
           # input_ = img.unsqueeze(0).to('cuda', non_blocking=True)

           # restored = model_retinexformer(input_)

           # frame = (
               # torch.clamp(restored, 0, 1)
               # .cpu()
               # .detach()
               # .permute(0, 2, 3, 1)
               # .squeeze(0)
               # .numpy()
           # )
        # Run YOLO on this frame -- YOLO only takes like 3500/3956MB of available memory
        results = model_yolo(frame)

        # Source: https://medium.com/@Mert.A/how-to-use-yolov11-for-object-detection-924aa18ac86f
        for result in results:
            for box in result.boxes:
                frame = cv2.rectangle(frame, (int(box.xyxy[0][0]), int(box.xyxy[0][1])),
                    (int(box.xyxy[0][2]), int(box.xyxy[0][3])), (255, 0, 0), 3)
                frame = cv2.putText(frame, f"{result.names[int(box.cls[0])]}",
                    (int(box.xyxy[0][0]), int(box.xyxy[0][1]) - 10),
                    cv2.FONT_HERSHEY_PLAIN, 1, (255, 255, 255), 3)
        
        print(f"Inference time: {(time.time() - start):.2f} seconds")
        
        if cv2.getWindowProperty(window_title_cam, cv2.WND_PROP_AUTOSIZE) >= 0: # Check if window has been closed
            cv2.imshow(window_title_cam, original_frame)
        else:
            break
        
        if cv2.getWindowProperty(window_title_yolo, cv2.WND_PROP_AUTOSIZE) >= 0:
            cv2.imshow(window_title_yolo, frame)
        else:
            break
            
        keyCode = cv2.waitKey(10) & 0xFF
        # Stop the program on the ESC key or 'q'
        if keyCode == 27 or keyCode == ord('q'):
            break
        

if __name__ == "__main__":
    print(f"Primary process started: pid={os.getpid()}")

    # Video Capture
    video_capture = cv2.VideoCapture(gstreamer_pipeline(), cv2.CAP_GSTREAMER)
    
    if not video_capture.isOpened():
        print("error: could not open video stream :(")
        exit()

    frame_queue = mp.Queue(maxsize=2)
    windows_have_opened = False
    process = mp.Process(target=inference_process, args=(frame_queue,))
    process.start()
    print(f"Inference process created: pid={process.pid}")

    while True:
        ret, frame = video_capture.read()
        if not ret:
            print("error: frame not read")
            break

        try:
            frame_queue.put(frame, timeout=0)
        except Exception:
            print("Warning: Inference queue full, dropping frame")


    frame_queue.put(None)
    process.join()
    video_capture.release()
    cv2.destroyAllWindows()
