import matplotlib.pyplot as plt
import os

def get_logs(dir_):
    paths = []
    for root, _, files in os.walk(dir_):
        for f in files:
            if f.endswith('.log'):
                paths.append(os.path.join(root, f))
    return paths

def plot_pruned_all():
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
        plt.scatter(times[i], ar, color="blue", alpha=1./num_files, s=2)
    plt.title(f"RAM usage: all pruned")
    plt.xlabel('Time (min)')
    plt.ylabel('RAM usage (MB)')
    plt.show()

    plt.figure(figsize=(8,6))
    for i, ar in enumerate(gpus):
        plt.scatter(times[i], ar, color="green", alpha=1./num_files, s=2)
    plt.title(f"GPU usage: all pruned")
    plt.xlabel("Time (min)")
    plt.ylabel("GPU usage (%% of available resources)")
    plt.show()
    
def plot_pruned_singles():
    logs_root = os.path.join(os.getcwd(), "tests_no_psnr")
    logs_subfolders = ["structured", "unstructured/global", "unstructured/local"]

    for subf in logs_subfolders:
        folder_path = os.path.join(logs_root, subf)
        paths = get_logs(folder_path)
        for path in paths:
            ram, gpu, time = get_data(path)
    
            plt.figure(figsize=(8,6))
            plt.scatter(time, ram, color="blue", s=2)
            plt.title(f"RAM usage: {os.path.basename(path)}")
            plt.xlabel("Time (min)")
            plt.ylabel("RAM usage (MB)")
            plt.show()

            plt.figure(figsize=(8,6))
            plt.scatter(time, gpu, color="green", s=2)
            plt.title(f"GPU usage: {os.path.basename(path)}")
            plt.xlabel("Time (min)")
            plt.ylabel("GPU usage (%% of available resources)")
            plt.show()

def plot_unpruned():
    logs_root = os.path.join(os.getcwd(), "tests_no_psnr")
    path = os.path.join(logs_root, "tegra_test_unpruned.log")
    ram, gpu, time = get_data(path)

    plt.figure(figsize=(8,6))
    plt.scatter(time, ram, color="blue", s=2)
    plt.title(f"RAM usage: {os.path.basename(path)}")
    plt.xlabel("Time (min)")
    plt.ylabel("RAM usage (MB)")
    plt.show()

    plt.figure(figsize=(8,6))
    plt.scatter(time, gpu, color="green", s=2)
    plt.title(f"GPU usage: {os.path.basename(path)}")
    plt.xlabel("Time (min)")
    plt.ylabel("GPU usage (%% of available resources)")
    plt.show()

def plot_unpruned_on_pruned():
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

    # unpruned
    path = os.path.join(logs_root, "tegra_test_unpruned.log")
    ram_, gpu_, time_ = get_data(path)

    num_files = len(rams)
    plt.figure(figsize=(8,6))
    for i, ar in enumerate(rams):
        plt.scatter(times[i], ar, color="blue", alpha=1./num_files, s=2)
    plt.scatter(time_, ram_, color="magenta", label="unpruned", alpha=0.5, s=2)
    plt.title(f"RAM usage: all")
    plt.xlabel("Time (min)")
    plt.ylabel('RAM usage (MB)')
    plt.legend()
    plt.show()

    plt.figure(figsize=(8,6))
    for i, ar in enumerate(gpus):
        plt.scatter(times[i], ar, color="green", alpha=1./num_files, s=2)
    plt.scatter(time_, gpu_, color="magenta", label="unpruned", alpha=0.5, s=2)
    plt.title(f"GPU usage: all")
    plt.xlabel("Time (min)")
    plt.ylabel("GPU usage (% of available resources)")
    plt.legend()
    plt.show()

def get_data(path):
    ram = []
    gpu = []
    time = []
    num_lines = 0
    start = min(num_lines - (60*30), 0)
    with open(path, "r") as f:
        lines = f.readlines()
        num_lines = len(lines)
        for i in range(num_lines):
            l = lines[i]
            l = l.split(" ")

            ram_idx = l.index("RAM") + 1
            gpu_idx = l.index("GR3D_FREQ") + 1

            ram_usage = l[ram_idx].split("/")
            ram.append(int(ram_usage[0]))

            gpu.append(int(l[gpu_idx][:-1]))

            time.append(i / 60) #tegrastats for some reason ran very quickly sometimes?

    # Align the timeframe (some start a lot earlier than others)
    max_lines = 60 * 30 + 30 # Basically, just record 3min30s
    start = max(num_lines - max_lines, 0)
    time_end = num_lines - start
    return ram[start:], gpu[start:], time[:time_end]

plot_unpruned_on_pruned()