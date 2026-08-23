# Arm-B host-cycle sampling-window audit

The single Arm-B warm reboot was submitted successfully. The bounded TCP/22
observer began after the host had already returned and consequently recorded
296 consecutive UP samples before its no-down timeout. It performed no state
change. The immediately following accepted pre-loader SSH session proved a new
boot ID, exact kernel 29, the exact endpoint/BAR geometry, and clean loader
entry. No reboot was repeated.

```text
WARM_REBOOT_EVIDENCE_SHA256=1F404201DA238E439D6B7EFDBFB0869C7D3EB3B97CB8A8311F101534201C8C29
TCP_OBSERVER_RESULT=ALL_UP_SAMPLING_WINDOW_MISSED_DOWN_INTERVAL
TCP_OBSERVER_SAMPLES=296
TCP_OBSERVER_STATE_CHANGES=0
PREVIOUS_BOOT_ID=c6cf85f0-0a06-4d2f-8656-5bca7cbb19a3
CURRENT_BOOT_ID=e2a2517a-c275-4ea9-bf11-83c0db94111e
BOOT_ID_CHANGED=YES
CURRENT_KERNEL=7.0.0-29-generic
PRELOADER_EVIDENCE_SHA256=1E1C02358552EF1607E05D3216DECD9850BE93646705593CFA39148D3B83BE0A
HOST_RETURNED=YES
SECOND_WARM_REBOOT=NO
REBOOT_GATE=PASS_BY_SUBMISSION_PLUS_CHANGED_BOOT_ID
```
