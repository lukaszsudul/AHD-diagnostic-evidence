# Predeclared NVP/video rate classification policy

This policy was frozen before any live DUT telemetry was collected for
`V41_NVP_I2C_25KHZ_PAIRED_AB_R1`.

The accepted RC-A procedure historically required positive VCLK, SAV, and
frame deltas after an approximately one-second interval; it did not publish a
numeric normalized-rate window. Its retained eleven-sample unbracketed
envelope was:

```text
VCLK_DELTA_PER_APPROXIMATELY_ONE_SECOND=148520870..148564336
SAV_DELTA_PER_APPROXIMATELY_ONE_SECOND=28129..28137
FRAME_DELTA_PER_APPROXIMATELY_ONE_SECOND=25
```

For this campaign, each changing counter is normalized with its own preserved
read-start/read-end brackets. The following conservative policy is therefore
a campaign measurement adaptation, not a claim that these numeric limits were
part of the historical RC-A acceptance contract:

```text
RATE_POLICY_FROZEN_BEFORE_LIVE_DATA=YES
VCLK_RATE_MIN_REQUIRED_HZ=140000000
VCLK_RATE_MAX_REQUIRED_HZ=160000000
VCLK_ACCEPTANCE=MEASURED_RATE_INTERVAL_FULLY_WITHIN_REQUIRED_RANGE
SAV_ACCEPTANCE=DELTA_GREATER_THAN_ZERO_AND_RATE_MIN_GREATER_THAN_ZERO
FRAME_RATE_MIN_REQUIRED_HZ=20
FRAME_RATE_MAX_REQUIRED_HZ=30
FRAME_ACCEPTANCE=MEASURED_RATE_INTERVAL_FULLY_WITHIN_REQUIRED_RANGE
INIT_DONE_REQUIRED=1
INIT_ERROR_REQUIRED=0
NACK_COUNT_REQUIRED=0
TIMEOUT_COUNT_REQUIRED=0
FIRST_ERROR_REQUIRED=NONE
NVP_RESET_RELEASED_STATUS_REQUIRED=1
NVP_VDD1X_ACTIVE_REQUIRED=1
NVP_VDD3X_ACTIVE_REQUIRED=1
FINAL_DONE_REQUIRED=1
```

`NVP_SCL_SAMPLE` and `NVP_SDA_SAMPLE` are recorded as instantaneous context
only; either logic level may be observed on an idle/open-drain bus.

The implemented BAR diagnostics expose the first-error tuple plus
`DETAIL0..DETAIL5`. The internal eight-entry NACK log is not fully mapped into
the host-visible 192-bit diagnostic vector. Accordingly, this campaign
preserves every host-available diagnostic field and explicitly records:

```text
FULL_INTERNAL_8_ENTRY_NACK_LOG_HOST_VISIBLE=NO
FULL_AVAILABLE_HOST_DIAGNOSTICS=FIRST_ERROR_AND_DETAIL0_THROUGH_DETAIL5
```
