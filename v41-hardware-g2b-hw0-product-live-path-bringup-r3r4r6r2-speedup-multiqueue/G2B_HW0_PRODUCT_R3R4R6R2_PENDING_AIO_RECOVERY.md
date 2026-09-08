# G2B-HW0-PRODUCT-R3R4R6R2 — PENDING_AIO_RECOVERY

Recovery BLOCKED. First operational blocker: R3R4R6R2_RECOVERY_DUT_RECONNECT_TIMEOUT_AFTER_AUTHORIZED_WARM_REBOOT.
PID25287 cmdline matched prequeued_c2h_capture and exact /home/vcdeagent1/vcde_artifacts/g2b_hw0_product_r3r4r6r1/20260907T202452Z path. Exactly one SIGTERM issued. Old pending state remained after12s; normal rmmod was not attempted with outstanding state.
Method selected ONE_GRACEFUL_WARM_REBOOT. Exactly one systemctl reboot command dispatched; connection closed at2026-09-08T06:21:50.9076393Z. This proves dispatch, not reboot completion. Subsequent task-helper reconnect attempts timed out; their exact times and results are in raw connection receipts.
No boot-ID read/comparison. No additional signal/reboot/power-cycle. Old helper exit, descriptor release, module removal and node disappearance could not be confirmed. Old Linux/controller locks were not removed because recovery completion was unproven. No R3R4R6R2 operational locks acquired.
No root cause is assigned to the lost connection; a stuck reboot versus unavailable host cannot be distinguished from these results. Further mutation requires Owner intervention.
