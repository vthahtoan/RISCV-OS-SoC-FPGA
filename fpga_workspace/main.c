#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stdint.h>

#define BRAM_BASE_ADDR  0xA0000000
#define BRAM_RANGE      0x2000
#define CTRL_BASE_ADDR  0xA0010000
#define CTRL_RANGE      0x10000

#define REG_PC      0
#define REG_RESULT  1
#define REG_EN      2
#define REG_RESET   3

int load_hex_to_bram(const char *filename, volatile uint32_t *bram) {
    FILE *f = fopen(filename, "r");
    if (!f) return -1;
    char line[512];
    uint32_t current_word_idx = 0;
    int total_words = 0;

    while (fgets(line, sizeof(line), f)) {
        if (line[0] == '/' || line[0] == '\n' || line[0] == '\r') continue;
        if (line[0] == '@') {
            current_word_idx = (uint32_t)strtoul(line + 1, NULL, 16);
            continue;
        }
        char *ptr = line;
        while (*ptr) {
            while (*ptr == ' ' || *ptr == '\t') ptr++;
            if (*ptr == '\n' || *ptr == '\r' || *ptr == '\0') break;
            char *end_ptr;
            uint32_t word = (uint32_t)strtoul(ptr, &end_ptr, 16);
            if (end_ptr == ptr) break;
            ptr = end_ptr;
            bram[current_word_idx++] = word;
            total_words++;
        }
    }
    fclose(f);
    return total_words;
}

int main(int argc, char *argv[]) {
    const char *hex_file = "program.hex";
    if (argc >= 2) hex_file = argv[1];

    int fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd < 0) { perror("open /dev/mem"); return 1; }

    volatile uint32_t *bram = (volatile uint32_t *)mmap(NULL, BRAM_RANGE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, BRAM_BASE_ADDR);
    volatile uint32_t *ctrl = (volatile uint32_t *)mmap(NULL, CTRL_RANGE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, CTRL_BASE_ADDR);

    if (bram == MAP_FAILED || ctrl == MAP_FAILED) {
        perror("mmap"); close(fd); return 1;
    }

    ctrl[REG_EN] = 0;
    ctrl[REG_RESET] = 1;
    usleep(10000);

    for (int i = 0; i < BRAM_RANGE / 4; i++) bram[i] = 0;

    printf("[*] Nap '%s'...\n", hex_file);
    int words = load_hex_to_bram(hex_file, bram);
    if (words <= 0) {
        printf("[!] Khong doc duoc hex file!\n");
        munmap((void*)bram, BRAM_RANGE); munmap((void*)ctrl, CTRL_RANGE); close(fd); return 1;
    }

    printf("    -> Da nap %d words vao BRAM.\n", words);
    printf("[*] CPU RISC-V BAT DAU CHAY...\n");
    printf("--------------------------------------------------\n");

    int found_pass = 0;
    int found_fail = 0;

    ctrl[REG_RESET] = 0;
    usleep(1000);
    ctrl[REG_EN] = 1;

    for (int i = 0; i < 5000000; i++) {
        uint32_t res = ctrl[REG_RESULT];

        if (res == 0xDEADBEEF) {
            ctrl[REG_EN] = 0;
            usleep(10);
            found_fail = 1;
            break;
        }
        else if (res == 0x600DCAFE) {
            ctrl[REG_EN] = 0;
            usleep(10);
            found_pass = 1;
            break;
        }

        if (i % 1000 == 0) usleep(1);
    }

    ctrl[REG_EN] = 0;

    printf("--------------------------------------------------\n");
    if (found_fail) {
        printf("  >>> [FAIL] CPU CHAY SAI (Phat hien DEADBEEF)\n");
    } else if (found_pass) {
        printf("  >>> [PASS] CPU CHAY DUNG (Phat hien GOODCAFE)\n");
        printf("  >>> CPU DA VUOT QUA BAI TEST VA DUNG LAI\n");
    } else {
        printf("  >>> [CHECK] CPU TRA VE KET QUA: 0x%08X\n", ctrl[REG_RESULT]);
    }
    printf("==================================================\n\n");

    munmap((void*)bram, BRAM_RANGE);
    munmap((void*)ctrl, CTRL_RANGE);
    close(fd);
    return 0;
}