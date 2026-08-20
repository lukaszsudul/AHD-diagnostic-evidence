# T4 RC-A versus v41 reset/clock-domain audit

## Executive summary

RC-A passes current hardware 3/3, while v41 samples show real digital NACKs. The exact protected NVP RTL, table and XDC are identical. Both integrations clock the NVP cone at nominal 62.5 MHz from the PCIe GT/pipe `userclk1` family, and neither PCIe `user_reset` nor XDMA `axi_aresetn` resets the NVP functional state. Thus no v41-specific source-level reset coupling or nominal-clock difference was found.

The primary classification is T4-F because the exact routed DCP that generated formal Phase 2 is not retained and DONE-to-reboot timestamps are missing. Exact generated-IP clock behavior across PERST/warm reboot and exact Phase-2 route/I/O margin therefore cannot be proven. The compared RC-A and v41 precursor checkpoints have identical NVP pin/IOB electrical properties, but image-dependent route margin remains plausible.

## T1 basis and identities

Basis: `RCA_CURRENT_HARDWARE_PASS_3_OF_3`. Exact commits and manifests are recorded in `00_INPUT_IDENTITY`; protected blobs match their four expected identities across RC-A, Phase 2 and Phase 3.

## Clock, reset and implementation

RC-A: `user_clk <- legacy PCIe user_clk_out`; v41: `autonomous_clk <- XDMA axi_aclk`. Read-only DCP reports show `userclk1`, 16.000 ns, via pipe MMCM CLKOUT2/BUFG from GT TXOUTCLK. Clock behavior before link and during PERST is unknown. Configuration initialization creates the one-shot 320-cycle POR. PCIe/XDMA resets affect surrounding application/control logic, not the NVP POR/autoinit state. A stopped clock retains state and open-drain enables and resumes mid-byte; actual stopping is unproven.

## Timeline and exact duration

Preserved evidence does not record DONE-to-reboot for either class, so timing difference and overlap are unknown. Exact success-path calculation gives a conservative completion bound of 1,810,937 us from configuration and a 1,000,000 us margin, recommending 2,810,937 us before reboot.

## Simulation

The unmodified full NVP regression passed all-ACK completion and all existing fault/reset checks. A separate integration model passed six pause-retention cases and integration-reset pulses. The latter cases are `HYPOTHETICAL_NOT_PROVEN` with respect to actual IP lifecycle.

## Classification, residual hypotheses and next test

Primary: `T4_INCONCLUSIVE_MISSING_EXACT_ARTIFACTS`. Residual hypotheses are unmeasured generated-IP clock lifecycle and exact Phase-2 placement/routing/electrical margin. One separately authorized delayed-reboot test is justified as a bounded discriminator, not as proof of a diagnosed cause. Its full plan is in `09_DELAYED_REBOOT_TEST_PLAN`; it was not executed.

## Final block

    TASK=
        T4_EXACT_RCA_VERSUS_V41_RESET_CLOCK_DOMAIN_AUDIT
    T1_BASIS=
        RCA_CURRENT_HARDWARE_PASS_3_OF_3
    RCA_SOURCE_COMMIT=
        55ce0df41552bb74e0923f89eff43977b040f2e5
    V41_PHASE2_FUNCTIONAL_SOURCE_COMMIT=
        fd32fcb65be3f1a59c569874195d1faeaf7d27e9
    V41_PHASE3_PROVENANCE_COMMIT=
        8464af66611f7c22b8a36a4aab915d598eedda3f
    NVP_CORE_RTL_BYTE_IDENTICAL=YES
    NVP_TABLE_BYTE_IDENTICAL=YES
    NVP_XDC_BYTE_IDENTICAL=YES
    RCA_AUTOINIT_CLOCK_SOURCE=LEGACY_PCIE_USER_CLK_USERCLK1
    V41_AUTOINIT_CLOCK_SOURCE=XDMA_AXI_ACLK_USERCLK1
    RCA_CLOCK_NOMINAL_HZ=62500000
    V41_CLOCK_NOMINAL_HZ=62500000
    RCA_CLOCK_ACTIVE_BEFORE_LINK=UNKNOWN
    V41_CLOCK_ACTIVE_BEFORE_LINK=UNKNOWN
    RCA_CLOCK_ACTIVE_DURING_PERST=UNKNOWN
    V41_CLOCK_ACTIVE_DURING_PERST=UNKNOWN
    RCA_NVP_STATE_AFFECTED_BY_PCIE_RESET=NO_DIRECT_RTL_PATH
    V41_NVP_STATE_AFFECTED_BY_XDMA_RESET=NO_DIRECT_RTL_PATH
    RCA_PHYSICAL_RESET_SEQUENCE=CONFIG_INIT_PLUS_320_CLOCK_ONE_SHOT_THEN_500MS_LOW
    V41_PHYSICAL_RESET_SEQUENCE=CONFIG_INIT_PLUS_320_CLOCK_ONE_SHOT_THEN_500MS_LOW
    RCA_REBOOT_OVERLAPS_AUTOINIT=UNKNOWN_NOT_RECORDED
    V41_REBOOT_OVERLAPS_AUTOINIT=UNKNOWN_NOT_RECORDED
    PROGRAM_TO_REBOOT_TIMING_DIFFERENCE=NOT_PROVEN_TIMESTAMPS_INCOMPLETE
    CLOCK_RESET_LIFECYCLE_DIFFERENCE=NOT_PROVEN
    IMPLEMENTATION_IO_MARGIN_DIFFERENCE_PLAUSIBLE=YES_UNPROVEN
    FIRST_I2C_START_US=1500000.016
    WORST_CASE_SUCCESS_TOTAL_US=1810937
    SAFE_DELAY_MARGIN_US=1000000
    RECOMMENDED_DELAYED_REBOOT_WAIT_US=2810937
    RECOMMENDED_DELAYED_REBOOT_WAIT_SECONDS=2.810937
    PRIMARY_T4_CLASSIFICATION=T4_INCONCLUSIVE_MISSING_EXACT_ARTIFACTS
    DELAYED_REBOOT_TEST_JUSTIFIED=YES_BOUNDED_DISCRIMINATOR
    DELAYED_REBOOT_TEST_EXECUTED=NO
    FUNCTIONAL_PATCH_CREATED=NO
    FUNCTIONAL_PATCH_APPLIED=NO
    NEW_BITSTREAMS=0
    JTAG_SESSIONS=0
    FPGA_PROGRAMS=0
    UBUNTU_REBOOTS=0
    SSH_DUT_COMMANDS=0
    MMIO_OPERATIONS=0
    C2H_TRANSFERS=0
    H2C_TRANSFERS=0
    FORMAL_REPOSITORY_MUTATION=0
    PHASE3_RESUMED=NO
    PHASE4_STARTED=NO
    NEXT_ACTION=OWNER_REVIEW_AND_SEPARATE_AUTHORIZATION_FOR_ONE_DELAYED_WARM_REBOOT_TEST