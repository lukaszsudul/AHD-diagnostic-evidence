# G2B-HW0-PRODUCT-R3R2 — DRIVER_LOAD_PROBE

PASS at T1. Exactly one sudo insmod of the sealed module, no parameters, return0. Automatic binding only to 0000:01:00.0; unintended bound endpoints0; platform xdma remained absent.
No manual new_id/bind/unbind/override, modprobe or depmod. Taint0 before,12288 after (out-of-tree and unsigned bits12/13).
After unexpected reboot the module was absent. Normal unload attempts0: no unload command was issued against an already absent module. This is not a successful normal cleanup cycle.
