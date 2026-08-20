# T4 delayed-reboot sample salvage and infrastructure forensic

The delayed sample remained continuous, but it could not be functionally salvaged. The exact accepted driver and loader were proven; however, the sole authorized recovery transaction stopped before `insmod` because the preserved accepted loader was not executable. No retry was made. The boot, endpoint, and FPGA image evidence remained undisturbed.

The XDMA boot failure is classified as the pinned module not being configured for boot, with a same-name Ubuntu platform-driver collision hazard. No remediation was installed.

Separately, Vivado 2025.2 and its signed `xv_common.dll` are present. A controlled version query through the supported settings and batch launcher passed. The owner-observed dialog is therefore most consistent with launching the raw internal executable without its required environment; it is not an NVP result and does not invalidate the recorded EOS/DONE evidence.

    TASK=
        T4_DELAYED_REBOOT_SAMPLE_SALVAGE_AND_INFRASTRUCTURE_FORENSIC

    ORIGINAL_TEST_EVIDENCE_COMMIT=
        ea56071672cfb15634cd7deeece87f26b566ac63

    ORIGINAL_BOOT_ID=
        20ce3f85-63d7-4d02-a3ad-9c87de8ad794

    CURRENT_BOOT_ID=
        20ce3f85-63d7-4d02-a3ad-9c87de8ad794

    SAMPLE_CONTINUITY=
        SAMPLE_CONTINUITY_PROVEN

    CURRENT_ENDPOINT=0000:01:00.0_10ee:7011_10ee:0007_058000
    CURRENT_LINK=GEN1_X1
    CURRENT_BAR0=128_KIB
    CURRENT_BAR1=64_KIB
    CURRENT_BOUND_DRIVER=NONE

    PINNED_XDMA_SOURCE_COMMIT=
        8721136e74a66500b02d16cb41922d966139cd46

    PINNED_XDMA_MODULE_PATH=/home/vcdeagent1/FPGA_AHD_HOST/dma_ip_drivers/XDMA/linux-kernel/xdma/xdma.ko
    PINNED_XDMA_MODULE_SHA256=1AEF06244DF308FEE544A2662B73855C81BEB88BC929E7885D8D113E474B320A
    PINNED_XDMA_VERMAGIC=7.0.0-29-generic_SMP_preempt_mod_unload_modversions
    PINNED_XDMA_LOADER_AUDIT=PASS_CONTENT_FAIL_EXECUTABILITY_MODE_0644

    XDMA_BOOT_FAILURE_CLASSIFICATION=PINNED_MODULE_NOT_CONFIGURED_FOR_BOOT

    WRONG_XDMA_MODULE_UNLOADED=NO_NOT_LOADED
    PINNED_DRIVER_LOAD_ATTEMPTS=1_TRANSACTION_0_INSMOD
    PINNED_DRIVER_RECOVERY=BLOCKED_ACCEPTED_LOADER_NOT_EXECUTABLE_NO_RETRY
    PCI_RESET_OR_RESCAN_ACTIONS=
        0

    FORMAL_IDENTITY_AFTER_RECOVERY=NOT_READ_MEASUREMENT_CHANNEL_ABSENT
    DIAGNOSTIC_MAGIC_AFTER_RECOVERY=NOT_READ_MEASUREMENT_CHANNEL_ABSENT

    INIT_DONE=NOT_READ
    INIT_ERROR=NOT_READ
    NACK_COUNT=NOT_READ
    TIMEOUT_COUNT=NOT_READ
    FIRST_ERROR=NOT_READ
    VCLK_DELTA=NOT_READ
    SAV_DELTA=NOT_READ
    FRAME_DELTA=NOT_READ

    SAMPLE_SALVAGE_CLASSIFICATION=DELAYED_REBOOT_SAMPLE_SALVAGE_INCONCLUSIVE_DRIVER
    DELAYED_REBOOT_FUNCTIONAL_CLASSIFICATION=INCONCLUSIVE_DELAYED_REBOOT_INFRASTRUCTURE

    VIVADO_EXPECTED_VERSION=
        2025.2

    VIVADO_FAILING_EXE_PATH=C:\AMDDesignTools\2025.2\Vivado\bin\unwrapped\win64.o\vivado.exe
    XV_COMMON_DLL_FOUND=YES
    XV_COMMON_DLL_PATH=C:\AMDDesignTools\2025.2\Vivado\lib\win64.o\xv_common.dll
    XV_COMMON_DLL_SHA256=70385600D41DFD037FE572467CE146043ED0FF5D30AEBA1FF0403C35E5A29771
    SETTINGS64_BAT_FOUND=YES
    CONTROLLED_VIVADO_VERSION_LAUNCH=PASS_VIVADO_2025_2
    VIVADO_FORENSIC_CLASSIFICATION=VIVADO_CONTROLLED_LAUNCH_PASS_ROOT_CAUSE_LIKELY_BAD_LAUNCHER

    VIVADO_ERROR_IS_NVP_RESULT=
        NO

    VIVADO_ERROR_INVALIDATES_RECORDED_EOS_DONE=
        NO

    UBUNTU_REBOOTS_THIS_TASK=
        0

    FPGA_PROGRAMS_THIS_TASK=
        0

    JTAG_PROGRAM_OPERATIONS=
        0

    PCI_REMOVE_RESCAN_RESETS=
        0

    AXI_LITE_WRITES=
        0

    C2H_TRANSFERS=
        0

    H2C_TRANSFERS=
        0

    SOURCE_CHANGES=
        0

    BUILDS=
        0

    FORMAL_REPOSITORY_MUTATION=
        0

    PHASE3_RESUMED=
        NO

    PHASE4_STARTED=
        NO

    NEXT_ACTION=OWNER_REVIEW_OF_FAIL_CLOSED_BOOT_LOADER_PLAN_BEFORE_ANY_NEW_ATTEMPT

