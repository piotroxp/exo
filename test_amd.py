#!/usr/bin/env python3

import subprocess

print("Testing AMD detection...")

# Test pyamdgpuinfo
try:
    import pyamdgpuinfo
    gpu_raw_info = pyamdgpuinfo.get_gpu(0)
    gpu_name = gpu_raw_info.name
    gpu_memory_info = gpu_raw_info.memory_info["vram_size"]
    print(f"pyamdgpuinfo - name: {repr(gpu_name)}, memory: {gpu_memory_info}")
except Exception as e:
    print(f"pyamdgpuinfo failed: {e}")

# Test rocm-smi
try:
    result = subprocess.run(['rocm-smi', '--showproductname'], capture_output=True, text=True, timeout=5)
    print(f"rocm-smi return code: {result.returncode}")
    print(f"rocm-smi output: {repr(result.stdout)}")
    
    if result.returncode == 0:
        for line in result.stdout.split('\n'):
            if 'Card Series:' in line:
                parts = line.split('Card Series:')
                if len(parts) > 1:
                    gpu_name = parts[1].strip()
                    print(f"Parsed GPU name: {repr(gpu_name)}")
                break
except Exception as e:
    print(f"rocm-smi failed: {e}") 