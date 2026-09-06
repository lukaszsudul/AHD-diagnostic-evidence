# G2B-HW0-PRODUCT-R3R2 — CLEANUP_RECEIPT

BLOCKED normal-cleanup qualification. Task-owned reader processes absent after boot change; no reader stop signal, MMIO safety disable, drain or rmmod was necessary/attempted on the new boot. Driver and XDMA nodes absent, endpoint unbound, platform xdma absent; endpoint still Gen2x1.
Original-session DMA quiescence and orderly unload could not be established across the reboot. No unsafe unload or additional reset was issued.
Linux lock absent across boot transition (not normal release). Controller lock released last after five final DONE1 samples. Credential remnants0; temporary credential files deleted after every helper invocation. No task-owned hardware work remains running.
