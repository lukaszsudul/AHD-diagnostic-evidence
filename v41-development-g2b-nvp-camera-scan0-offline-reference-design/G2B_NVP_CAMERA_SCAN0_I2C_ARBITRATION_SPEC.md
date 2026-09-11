# I2C arbitration specification

Priority is fixed: (1) autoinit/PRODUCT-critical sequence, (2) governed ACQ1 executor, (3) read-only SCAN1 scanner. The grant unit is one complete atomic bank group: save/select, verify, all group entries, then release. There is no transaction-level interleaving inside a group and every client must select its bank explicitly.

SCAN1 cannot start before `autoinit_done`. If autoinit becomes pending during a scan, the scanner finishes only the active group, begins no next group, restores/verifies ENTRY_BANK if safe, invalidates the scan with `AUTOINIT_PREEMPTED`, releases both lines and yields. Partial entries remain private diagnostic state and never receive `VALID_COMPLETE`.

The existing 25-kHz fixed master, clock stretching and fixed SCL/bus-idle timeout behavior are reused. A logical entry may be retried at most once. No new nine-pulse recovery, runtime timeout, or speed selection exists.
