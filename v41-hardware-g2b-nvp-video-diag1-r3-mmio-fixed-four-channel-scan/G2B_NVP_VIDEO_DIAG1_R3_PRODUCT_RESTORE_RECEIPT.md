# PRODUCT NVP baseline restore

PASS. Firmware safe restore returned BGDCOL to `0x88/0x88`, full route to `0x00`, and internally physically verified the saved bank/page. Restore status was 3, I²C ownership was released, and the bus was idle. The retained diagnostic error `0x8` records the capture failure; it does not negate successful restore.
