#!/bin/bash
echo "=== [1] NAP CAU HINH PHAN CUNG FPGA ==="
sudo sh -c "echo 0 > /sys/class/fpga_manager/fpga0/flags"
sudo cp rv32imc_soc_wrapper.bit /lib/firmware/
sudo sh -c "echo rv32imc_soc_wrapper.bit > /sys/class/fpga_manager/fpga0/firmware"
cat /sys/class/fpga_manager/fpga0/state

echo "=== [2] DICH CODE RISC-V SANG MA MAY ==="
riscv64-unknown-elf-objcopy -R .riscv.attributes riscv_code/crt0.o
riscv64-unknown-elf-gcc -march=rv32imc -mabi=ilp32 -O0 -nostdlib -T riscv_code/link.ld riscv_code/crt0.o riscv_code/test_cpu.c -o riscv_code/test_cpu.elf

# Xu?t ra Binary chu?n
riscv64-unknown-elf-objcopy -O binary riscv_code/test_cpu.elf program.bin

# Dùng Python ép Binary thành file program.hex 32-bit hoàn h?o (Ðã fix l?i Syntax)
python3 -c '
import sys
with open("program.bin", "rb") as f:
    data = f.read()
for i in range(0, len(data), 4):
    chunk = data[i:i+4]
    chunk += b"\x00" * (4 - len(chunk))
    val = int.from_bytes(chunk, "little")
    print("%08x" % val)
' > program.hex

echo "-> Da tao thanh cong program.hex (Chuan 32-bit)"

echo "=== [3] DICH CODE DIEU KHIEN ARM ==="
gcc arm_code/main.c -o run_riscv
echo "-> Da tao thanh cong run_riscv"

echo "=== [4] NAP XUONG BRAM VA KHOI CHAY RISC-V ==="
sudo ./run_riscv program.hex