# MIT License
# Copyright (c) 2019-2022 JetsonHacks

# Using a CSI camera (such as the Raspberry Pi Version 2) connected to a
# NVIDIA Jetson Nano Developer Kit using OpenCV
# Drivers for the camera and OpenCV are included in the base image

import cv2
from ultralytics import YOLO

import numpy as np
import torch
import yaml
from yaml import Loader

""" 
gstreamer_pipeline returns a GStreamer pipeline for capturing from the CSI camera
Flip the image by setting the flip_method (most common values: 0 and 2)
display_width and display_height determine the size of each camera pane in the window on the screen
Default 1920x1080 displayd in a 1/4 size window
"""

def gstreamer_pipeline(
    sensor_id=0,
    capture_width=1920,
    capture_height=1080,
    display_width=960,
    display_height=540,
    framerate=30,
    flip_method=0,
):
    return (
        "nvarguscamerasrc exposuretimerange='33333 33333' aelock=true sensor-id=%d ! "
        "video/x-raw(memory:NVMM), width=(int)%d, height=(int)%d, framerate=(fraction)%d/1 ! "
        "nvvidconv flip-method=%d ! "
        "video/x-raw, width=(int)%d, height=(int)%d, format=(string)BGRx ! "
        "videoconvert ! "
        "video/x-raw, format=(string)BGR ! appsink "
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

def detect_blue(frame):
    # adapted from https://www.geeksforgeeks.org/multiple-color-detection-in-real-time-using-python-opencv/
    hsvFrame = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV) 
    blurred_frame = cv2.blur(hsvFrame, (7, 7)) # eliminate a little bit of color noise

    # Set range for blue color and define mask 
    blue_lower = np.array([94, 80, 2], np.uint8) 
    blue_upper = np.array([120, 255, 255], np.uint8) 
    blue_mask = cv2.inRange(hsvFrame, blue_lower, blue_upper) 

    kernel = np.ones((3, 3), "uint8") #dilation kernel

    blue_mask = cv2.dilate(blue_mask, kernel) 

    contours, hierarchy = cv2.findContours(blue_mask, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE) 

    return contours
    
def show_blue_contours(contours):
    for _, contour in enumerate(contours): 
        area = cv2.contourArea(contour) 
        if(area > 1000): 
            x, y, w, h = cv2.boundingRect(contour) 
            frame = cv2.rectangle(frame, (x, y), (x + w, y + h), (255, 0, 0), 2) 
            cv2.putText(frame, "Blue Colour", (x, y), cv2.FONT_HERSHEY_SIMPLEX, 1.0, (255, 0, 0)) 

def show_camera(model, video_capture):
    window_title_cam = "CSI Camera"
    window_title_yolo = "YOLO output"

    # To flip the image, modify the flip_method parameter (0 and 2 are the most common)
    if video_capture.isOpened():
        try:
            window_handle = cv2.namedWindow(window_title_cam, cv2.WINDOW_AUTOSIZE)
            window_handle2 = cv2.namedWindow(window_title_yolo, cv2.WINDOW_AUTOSIZE)
            while True:
                ret_val, frame = video_capture.read()
                original_frame = frame

                # Run YOLO on this frame
                results = model(frame)
                # Source: https://medium.com/@Mert.A/how-to-use-yolov11-for-object-detection-924aa18ac86f
    
                for result in results:
                    for box in result.boxes:
                        frame = cv2.rectangle(frame, (int(box.xyxy[0][0]), int(box.xyxy[0][1])),
                          (int(box.xyxy[0][2]), int(box.xyxy[0][3])), (0, 0, 255), 3)
                        frame = cv2.putText(frame, f"{result.names[int(box.cls[0])]}",
                          (int(box.xyxy[0][0]), int(box.xyxy[0][1]) - 10),
                           cv2.FONT_HERSHEY_PLAIN, 1, (255, 255, 255), 3)
                           
                # Check to see if the user closed the window
                # Under GTK+ (Jetson Default), WND_PROP_VISIBLE does not work correctly. Under Qt it does
                # GTK - Substitute WND_PROP_AUTOSIZE to detect if window has been closed by user
                
                frame = detect_blue(frame)

                if cv2.getWindowProperty(window_title_cam, cv2.WND_PROP_AUTOSIZE) >= 0:
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
        finally:
            video_capture.release()
            cv2.destroyAllWindows()
    else:
        print("Error: Unable to open camera")


if __name__ == "__main__":
    # Load YOLO
    model_yolo = YOLO("/home/jetson/Desktop/yolo11n.pt")
    print("Completed loading YOLO!")

    # Video Capture
    video_capture = cv2.VideoCapture(gstreamer_pipeline(flip_method=0), cv2.CAP_GSTREAMER)

    # BasicSR needs to be initialized *after* the video capture or else video capture will not work
    from basicsr.models import create_model
    from basicsr.utils.options import dict2str, parse

    show_camera(model_yolo, video_capture)
