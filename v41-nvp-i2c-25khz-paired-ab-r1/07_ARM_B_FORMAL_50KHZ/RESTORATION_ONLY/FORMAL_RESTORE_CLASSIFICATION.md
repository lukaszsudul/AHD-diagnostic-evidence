# Exact formal Phase-2 restoration classification

The second and final permitted program invocation used the exact formal
Phase-2 bit and the previously accepted one-shot restoration procedure. Vivado
reported startup HIGH and `DONE=1`. After a 5.016797600-second conservative
wait, one Ubuntu warm reboot produced a new boot ID. The exact pinned XDMA
module was loaded once through the exact accepted loader.

Runtime reads proved the common formal identity, diagnostic magic zero, and
the accepted formal runtime signature of five zero Git words with build flags
zero. The contextual NVP sample was infrastructure-valid and reproduced the
known formal failure class: VCLK active, `INIT_ERROR=1`, 19 NACKs, no timeout,
and no SAV/frame activity. This is restoration context only, not a valid Arm-B
member of a paired scientific campaign because Arm A was infrastructure-invalid.

```text
FORMAL_RESTORE_PROGRAM=PASS_EOS_HIGH_DONE_1
FORMAL_BIT_SHA256=7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2
FORMAL_RESTORE_WAIT_SECONDS=5.016797600
FORMAL_RESTORE_BOOT_ID_CHANGED=YES
FORMAL_RESTORE_DRIVER=PASS_EXACT_PINNED
FORMAL_RESTORE_IDENTITY=A40A0C07_0000400B_00031002
FORMAL_RESTORE_DIAGNOSTIC_MAGIC=00000000
FORMAL_RESTORE_CONTEXT_NVP=FAIL_INIT_ERROR_1_NACK_19_SAV_0_FRAME_0
FINAL_DONE=1
FINAL_ACTIVE_IMAGE=FORMAL_PHASE2
FINAL_PINNED_DRIVER_LOADED=YES
```
