# Drain helper report

Device-free gate: 8/8 PASS. Initial and maximum outstanding requests: 1024. Buffer size/alignment: 4096/4096 bytes. Active video payload persistence and control IPC: NO.

Hardware cleanup result: BLOCKED — `BT656_DIAG1_R1_DRAIN_AIO_CLEANUP_UNRESOLVED`. After STOP_RESUBMIT and PARENT_QUIESCENT, the helper reported 1023 requests still outstanding. Its normal exit was not observed. The module reference count remained 1; user/C2H nodes remained present. No signal or forced cleanup was attempted.
