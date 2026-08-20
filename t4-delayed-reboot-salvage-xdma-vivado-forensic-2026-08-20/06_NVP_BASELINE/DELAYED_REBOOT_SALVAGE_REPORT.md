# Delayed-reboot sample salvage

Telemetry was not read because the exact measurement channel was not recovered. The single recovery transaction stopped before `insmod`, and the task forbids a second attempt.

    FORMAL_IDENTITY_AFTER_RECOVERY=NOT_READ_MEASUREMENT_CHANNEL_ABSENT
    DIAGNOSTIC_MAGIC_AFTER_RECOVERY=NOT_READ_MEASUREMENT_CHANNEL_ABSENT
    SAMPLE_SALVAGE_CLASSIFICATION=DELAYED_REBOOT_SAMPLE_SALVAGE_INCONCLUSIVE_DRIVER
    DELAYED_REBOOT_FUNCTIONAL_CLASSIFICATION=INCONCLUSIVE_DELAYED_REBOOT_INFRASTRUCTURE

No functional inference is made.

