
# Double-PREPARE baseline comparison

PREPARE_A and PREPARE_B each executed 26
I2C transactions. Both captured BGDCOL 0x78=`0x88`, BGDCOL 0x79=`0x88`, and
full VDO1 route=`0x00`; all visible values agreed. NACK, timeout, and recovery
counts were zero. PREPARE_B became the restore authority. Result:
PASS.
