/*
 * ============================================================================
 * dsp_cli.c - DE10-Nano ARM Cortex-A9 Supervisory CLI for 16-Tap FIR Filter
 * 
 * Target Architecture: Intel Cyclone V SoC (5CSEBA6U23I7)
 * Bus Interface     : Lightweight HPS-to-FPGA (LWH2F) AXI Bridge
 * Base Address      : 0xFF200000
 * Span              : 0x00200000 (2 MB)
 *
 * Register Specifications:
 *   Offset 0x00 (Control Reg):
 *     Bit 0 : Core Reset (1 = Hold Reset, 0 = Normal Operation)
 *     Bit 1 : Bypass Mode (1 = Filter OFF/Raw Noise, 0 = Filter ACTIVE)
 *   Offset 0x04 (Status Reg):
 *     Bits [7:0] : Instantaneous Rectified Amplitude Metric
 * ============================================================================
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <signal.h>

#define LWH2F_BASE       0xFF200000
#define LWH2F_SPAN       0x00200000
#define FIR_OFFSET       0x00000000

#define REG_CONTROL      0  /* Offset 0x00 */
#define REG_STATUS       1  /* Offset 0x04 */

static volatile sig_atomic_t stop_stream = 0;

void sigint_handler(int sig) {
    (void)sig;
    stop_stream = 1;
}

/* Helper to convert uint8_t amplitude into 8-bit binary string [LED7..LED0] */
void format_binary8(uint8_t val, char *str) {
    for (int i = 7; i >= 0; i--) {
        str[7 - i] = (val & (1 << i)) ? '1' : '0';
    }
    str[8] = '\0';
}

/* Helper to render visual ASCII amplitude bar */
void print_bar(uint8_t val) {
    int bar_len = (int)(val * 30 / 125);
    if (bar_len > 30) bar_len = 30;

    printf("[");
    for (int i = 0; i < 30; i++) {
        if (i < bar_len) printf("#");
        else printf(" ");
    }
    printf("]");
}

int main(int argc, char *argv[]) {
    (void)argc;
    (void)argv;

    int fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd < 0) {
        perror("[-] Error: Failed to open /dev/mem (Please run as root)");
        return EXIT_FAILURE;
    }

    void *virtual_base = mmap(NULL, LWH2F_SPAN, PROT_READ | PROT_WRITE, MAP_SHARED, fd, LWH2F_BASE);
    if (virtual_base == MAP_FAILED) {
        perror("[-] Error: mmap failed");
        close(fd);
        return EXIT_FAILURE;
    }

    volatile uint32_t *fir_regs = (volatile uint32_t *)((char *)virtual_base + FIR_OFFSET);

    printf("\n=======================================================\n");
    printf("   DE10-Nano Real-Time FIR Audio Filter Supervisory CLI \n");
    printf("=======================================================\n");
    printf(" LWH2F Base Physical Address : 0x%08X\n", LWH2F_BASE);
    printf(" Memory Span Mapped          : 0x%08X (2 MB)\n", LWH2F_SPAN);
    printf(" FIR Core Peripheral Offset  : 0x%08X\n", FIR_OFFSET);
    printf("-------------------------------------------------------\n");
    printf(" Type 'help' to see all available commands.\n\n");

    char input[128];
    char bin_str[9];

    while (1) {
        printf("DSP> ");
        fflush(stdout);

        if (!fgets(input, sizeof(input), stdin))
            break;

        /* Strip trailing newlines / carriage returns */
        input[strcspn(input, "\r\n")] = '\0';

        if (strcmp(input, "exit") == 0 || strcmp(input, "quit") == 0) {
            printf("[*] Exiting DSP Supervisory Console.\n");
            break;
        } 
        else if (strcmp(input, "help") == 0) {
            printf("\nAvailable Commands:\n");
            printf("  status        : Read registers, decimal amplitude, and binary LED states\n");
            printf("  filter on     : Enable FIR filtering mode (attenuate 12.5 kHz noise)\n");
            printf("  filter off    : Bypass filter (pass raw high-frequency noise)\n");
            printf("  reset         : Issue a visible 100 ms pulse reset to FIR core\n");
            printf("  hold reset    : Assert and HOLD reset permanently (all 8 LEDs turn OFF)\n");
            printf("  release reset : Deassert reset and resume DSP audio pipeline\n");
            printf("  monitor       : Stream real-time amplitude metrics & binary LED states\n");
            printf("  exit / quit   : Unmap physical memory and exit\n\n");
        } 
        else if (strcmp(input, "status") == 0) {
            uint32_t ctrl = fir_regs[REG_CONTROL];
            uint32_t stat = fir_regs[REG_STATUS];
            uint8_t amp = (uint8_t)(stat & 0xFF);
            format_binary8(amp, bin_str);

            printf("\n--- System Status ---\n");
            printf(" Control Reg [0x00] : 0x%08X\n", ctrl);
            printf("   * Reset State    : %s\n", (ctrl & 0x01) ? "ASSERTED (Logic HELD in Reset)" : "DEASSERTED (Running)");
            printf("   * Filter State   : %s\n", (ctrl & 0x02) ? "BYPASS (Filter OFF - Noise Passed)" : "ACTIVE (Filter ON - 500 Hz Tone)");
            printf(" Status Reg  [0x04] : 0x%08X\n", stat);
            printf("   * Amplitude (Dec): %u / 255\n", amp);
            printf("   * LEDs [7..0] Bin: %s\n", bin_str);
            printf("   * Visual Level   : ");
            print_bar(amp);
            printf("\n\n");
        } 
        else if (strcmp(input, "filter on") == 0) {
            /* Preserve reset state, clear bypass bit (bit 1 = 0) */
            uint32_t current_ctrl = fir_regs[REG_CONTROL];
            fir_regs[REG_CONTROL] = current_ctrl & ~0x02;
            printf("[+] FIR Filter ACTIVE. High frequencies attenuated (Smooth 500 Hz pattern, peak amplitude ~75).\n\n");
        } 
        else if (strcmp(input, "filter off") == 0) {
            /* Preserve reset state, set bypass bit (bit 1 = 1) */
            uint32_t current_ctrl = fir_regs[REG_CONTROL];
            fir_regs[REG_CONTROL] = current_ctrl | 0x02;
            printf("[+] FIR Filter BYPASSED. Raw 12.5 kHz noise passing directly to LEDs (Peak amplitude ~125).\n\n");
        } 
        else if (strcmp(input, "reset") == 0) {
            /* Issue a visible 100 ms pulse */
            uint32_t current_bypass = fir_regs[REG_CONTROL] & 0x02;
            fir_regs[REG_CONTROL] = current_bypass | 0x01; // Assert reset
            printf("[*] Reset pulse asserted (all LEDs dark)...\n");
            fflush(stdout);
            usleep(100000); // 100 ms (human-visible)
            fir_regs[REG_CONTROL] = current_bypass;        // Deassert reset
            printf("[+] Reset pulse finished. Core resumed.\n\n");
        } 
        else if (strcmp(input, "hold reset") == 0) {
            /* Set bit 0 to 1 and keep it asserted */
            uint32_t current_bypass = fir_regs[REG_CONTROL] & 0x02;
            fir_regs[REG_CONTROL] = current_bypass | 0x01;
            printf("[+] Reset is now HELD ASSERTED.\n");
            printf("    All internal pipeline registers and generators are frozen.\n");
            printf("    All 8 on-board LEDs are held OFF (Amplitude = 0, Binary: 00000000).\n");
            printf("    Type 'release reset' to resume operation.\n\n");
        } 
        else if (strcmp(input, "release reset") == 0) {
            /* Clear bit 0 */
            uint32_t current_bypass = fir_regs[REG_CONTROL] & 0x02;
            fir_regs[REG_CONTROL] = current_bypass;
            printf("[+] Reset RELEASED. FIR filter core and tone generators resumed.\n\n");
        } 
        else if (strcmp(input, "monitor") == 0) {
            printf("[*] Real-Time Signal Amplitude Monitor (Press Ctrl+C to stop)\n");
            printf("----------------------------------------------------------------------\n");

            stop_stream = 0;
            signal(SIGINT, sigint_handler);

            while (!stop_stream) {
                uint32_t stat = fir_regs[REG_STATUS];
                uint8_t amp = (uint8_t)(stat & 0xFF);
                format_binary8(amp, bin_str);

                printf("\rAmplitude: %3u | Binary: [%s] | ", amp, bin_str);
                print_bar(amp);
                fflush(stdout);

                usleep(50000); // 50 ms update rate (20 Hz)
            }

            signal(SIGINT, SIG_DFL);
            printf("\n[*] Stream stopped.\n\n");
        } 
        else if (strlen(input) > 0) {
            printf("[-] Unknown command: '%s'. Type 'help' for options.\n\n", input);
        }
    }

    /* Unmap memory and close file descriptor */
    munmap(virtual_base, LWH2F_SPAN);
    close(fd);
    return EXIT_SUCCESS;
}
