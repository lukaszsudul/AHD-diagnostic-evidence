# R15R7R1 — normal remove qualification, 0/10 trials

**CAMPAIGN_SAFETY_STOP before S0 unload. A_POST_DRAIN was not qualified.**

The exact retained driver sources and module identity were checked. Normal remove has no identified direct dependency on loader/FEQ application readiness. That finding alone is insufficient to authorize all transport states.

The specific missing evidence is ordering of all deferred engine work, including any residual or later queued work, before engine resources and BAR mappings are destroyed. User AIO completion precedes the end of the relevant driver worker. The retained remove chain masks/frees IRQs and then frees engine resources, without an identified work join at that boundary. Reader drain, io_destroy and close remain necessary; their complete ordering with possible later engine work was not established. This is a qualification gap, not a reproduced race or a claim that DMA/work is currently active.

General Linux IRQ/workqueue API documentation was used to interpret the helpers; it is not certification of the installed distribution kernel. Details, including the AIO/RCU caveat, remain in the private source trace.

- B is disabled, not used, and not a prerequisite or blocker.
- The narrow never-submitted/no-scheduled-work class is separated from post-drain. Fresh full execution admission and actual unload were not performed.
- The campaign requires a safe end for successful capture before starting. No gate candidate/manager was activated and no new offline qualification tests were claimed. Historical 87 wrapper tests remain historical.
- No unload, JTAG, reboot, new MMIO, ARM, PREPARE, APPLY, EQ, reader or DMA. Zero new trials and PNG; all 10 trials/100 samples remain explicitly not run.
- Firmware, driver and 52 local released host files retain their exact hashes. No product or configuration admission changes.
- Driver and both owned reservations remain retained for the same campaign. Historical results are unchanged.

Engineering qualification and append-only publication are separate results. No physical NACK cause or camera scene was tested.
