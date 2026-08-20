# Delayed-reboot final salvage

The infrastructure, driver, formal identity, and boot continuity gates are valid. The NVP/video functional gate fails:

    INIT_DONE=1
    INIT_ERROR=1
    NACK_COUNT=9
    TIMEOUT_COUNT=0
    FIRST_ERROR_VALID=1
    FIRST_ERROR_CODE=0x01
    FIRST_ERROR_STEP=0x35
    FIRST_ERROR_META_BANK=0x05
    FIRST_ERROR_PHYSICAL_BANK=0x05
    FIRST_ERROR_REGISTER=0x90
    FIRST_ERROR_VALUE=0x01
    NVP_RESET_RELEASED=1
    NVP_POWER_VDD1X=1
    NVP_POWER_VDD3X=1
    VCLK_DELTA=150881506
    SAV_DELTA=0
    FRAME_DELTA=0

    SAMPLE_SALVAGE_CLASSIFICATION=DELAYED_REBOOT_SAMPLE_SALVAGED_FAIL
    DELAYED_REBOOT_FUNCTIONAL_CLASSIFICATION=DELAYED_REBOOT_DOES_NOT_RECOVER_V41_NVP_BASELINE_SALVAGED_SAMPLE
    SIMPLE_EARLY_REBOOT_OVERLAP=WEAKENED_NOT_ELIMINATED

The exact pinned driver was loaded after the original infrastructure gate, in the same preserved boot and FPGA image, with no intervening reboot, FPGA program, or PCI reset/rescan.

