import matplotlib.pyplot as plt
import os

def get_logs(dir_):
    paths = []
    for root, _, files in os.walk(dir_):
        for f in files:
            if f.endswith('.log'):
                paths.append(os.path.join(root, f))
    return paths

def plot_pruned():
    rams = [] # 2D arrays
    gpus = []
    times = []

    logs_root = os.path.join(os.getcwd(), "tests_no_psnr")
    logs_subfolders = ["structured", "unstructured/global", "unstructured/local"]

    for subf in logs_subfolders:
        folder_path = os.path.join(logs_root, subf)
        paths = get_logs(folder_path)
        for path in paths:
            ram, gpu, time = get_data(path)
            rams.append(ram)
            gpus.append(gpu)
            times.append(time)

    num_files = len(rams)
    plt.figure(figsize=(8,6))
    for i, ar in enumerate(rams):
        plt.plot(times[i], ar, color="blue", alpha=1./num_files)
    plt.title(f"RAM usage: all pruned")
    plt.xlabel('Time (min)')
    plt.ylabel('RAM usage (MB)')
    plt.show()

    plt.figure(figsize=(8,6))
    for i, ar in enumerate(gpus):
        plt.plot(times[i], ar, color="green", alpha=1./num_files)
    plt.title(f"GPU usage: all pruned")
    plt.xlabel("Time (min)")
    plt.ylabel("GPU usage (%% of available resources)")
    plt.show()
    
def get_data(path):
    ram = []
    gpu = []
    time = []

    with open(path, "r") as f:
        lines = f.readlines()
        for i in range(len(lines)):
            l = lines[i]
            l = l.split(" ")

            ram_idx = l.index("RAM") + 1
            gpu_idx = l.index("GR3D_FREQ") + 1

            ram_usage = l[ram_idx].split("/")
            ram.append(int(ram_usage[0]))

            gpu.append(int(l[gpu_idx][:-1]))

            time.append((5. * i)/60.) #tegrastats run ever 5 sec

    return ram, gpu, time

