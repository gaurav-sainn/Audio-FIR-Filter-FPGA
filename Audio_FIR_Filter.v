module Audio_FIR_Filter (
    // 50 MHz FPGA System Clock
    input  wire        FPGA_CLK1_50,
    input  wire [1:0]  KEY,          // Pushbuttons

    // 8 User LEDs (Connected to the FIR filter status/amplitude)
    output wire [7:0]  LED,

    // HPS DDR3 Memory Hard Interface (Exact widths matching soc_system_bb.v)
    output wire [12:0] HPS_DDR3_ADDR,
    output wire [2:0]  HPS_DDR3_BA,
    output wire        HPS_DDR3_CAS_N,
    output wire        HPS_DDR3_CKE,
    output wire        HPS_DDR3_CK_N,
    output wire        HPS_DDR3_CK_P,
    output wire        HPS_DDR3_CS_N,
    output wire        HPS_DDR3_DM,
    inout  wire [7:0]  HPS_DDR3_DQ,
    inout  wire        HPS_DDR3_DQS_N,
    inout  wire        HPS_DDR3_DQS_P,
    output wire        HPS_DDR3_ODT,
    output wire        HPS_DDR3_RAS_N,
    output wire        HPS_DDR3_RESET_N,
    input  wire        HPS_DDR3_RZQ,
    output wire        HPS_DDR3_WE_N,

    // HPS Dedicated Peripheral Pins (SD Card, USB, UART)
    inout  wire        HPS_SD_CMD,
    inout  wire        HPS_SD_CLK,
    inout  wire [3:0]  HPS_SD_DATA,
    input  wire        HPS_UART_RX,
    output wire        HPS_UART_TX,
    inout  wire [7:0]  HPS_USB_DATA,
    input  wire        HPS_USB_CLKOUT,
    output wire        HPS_USB_STP,
    input  wire        HPS_USB_DIR,
    input  wire        HPS_USB_NXT
);

    // Platform Designer SoC system instantiation
    soc_system u0 (
        .clk_clk                               (FPGA_CLK1_50),
        .reset_reset_n                         (1'b1), // Deasserts active-low system reset

        // Avalon conduit connected directly to board LEDs
        .fir_filter_avalon_0_conduit_readdata  (LED),

        // MicroSD Interface
        .hps_io_hps_io_sdio_inst_CMD           (HPS_SD_CMD),
        .hps_io_hps_io_sdio_inst_CLK           (HPS_SD_CLK),
        .hps_io_hps_io_sdio_inst_D0            (HPS_SD_DATA[0]),
        .hps_io_hps_io_sdio_inst_D1            (HPS_SD_DATA[1]),
        .hps_io_hps_io_sdio_inst_D2            (HPS_SD_DATA[2]),
        .hps_io_hps_io_sdio_inst_D3            (HPS_SD_DATA[3]),

        // USB PHY Interface
        .hps_io_hps_io_usb1_inst_D0            (HPS_USB_DATA[0]),
        .hps_io_hps_io_usb1_inst_D1            (HPS_USB_DATA[1]),
        .hps_io_hps_io_usb1_inst_D2            (HPS_USB_DATA[2]),
        .hps_io_hps_io_usb1_inst_D3            (HPS_USB_DATA[3]),
        .hps_io_hps_io_usb1_inst_D4            (HPS_USB_DATA[4]),
        .hps_io_hps_io_usb1_inst_D5            (HPS_USB_DATA[5]),
        .hps_io_hps_io_usb1_inst_D6            (HPS_USB_DATA[6]),
        .hps_io_hps_io_usb1_inst_D7            (HPS_USB_DATA[7]),
        .hps_io_hps_io_usb1_inst_CLK           (HPS_USB_CLKOUT),
        .hps_io_hps_io_usb1_inst_STP           (HPS_USB_STP),
        .hps_io_hps_io_usb1_inst_DIR           (HPS_USB_DIR),
        .hps_io_hps_io_usb1_inst_NXT           (HPS_USB_NXT),

        // Serial Terminal (UART)
        .hps_io_hps_io_uart0_inst_RX           (HPS_UART_RX),
        .hps_io_hps_io_uart0_inst_TX           (HPS_UART_TX),

        // DDR3 Hard Memory Sequencer & Calibration
        .memory_mem_a                          (HPS_DDR3_ADDR),
        .memory_mem_ba                         (HPS_DDR3_BA),
        .memory_mem_ck                         (HPS_DDR3_CK_P),
        .memory_mem_ck_n                       (HPS_DDR3_CK_N),
        .memory_mem_cke                        (HPS_DDR3_CKE),
        .memory_mem_cs_n                       (HPS_DDR3_CS_N),
        .memory_mem_ras_n                      (HPS_DDR3_RAS_N),
        .memory_mem_cas_n                      (HPS_DDR3_CAS_N),
        .memory_mem_we_n                       (HPS_DDR3_WE_N),
        .memory_mem_reset_n                    (HPS_DDR3_RESET_N),
        .memory_mem_dq                         (HPS_DDR3_DQ),
        .memory_mem_dqs                        (HPS_DDR3_DQS_P),
        .memory_mem_dqs_n                      (HPS_DDR3_DQS_N),
        .memory_mem_odt                        (HPS_DDR3_ODT),
        .memory_mem_dm                         (HPS_DDR3_DM),
        .memory_oct_rzqin                      (HPS_DDR3_RZQ)
    );

endmodule