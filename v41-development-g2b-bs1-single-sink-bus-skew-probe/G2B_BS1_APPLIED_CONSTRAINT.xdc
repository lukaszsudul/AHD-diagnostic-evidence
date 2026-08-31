# G2B-BS1 APPLIED-CONSTRAINT EVIDENCE SENTINEL
# STATUS: NOT_APPLIED_INITIALIZATION_TIMEOUT
#
# The only BS1 Vivado worker timed out while open_checkpoint was still loading.
# It did not reach reset_timing, read_xdc, object resolution, set_bus_skew, or
# write_xdc. This file exists to make the required evidence slot explicit and
# must not be represented as a constraint that Vivado applied.
#
# Intended authoritative skew-free base:
# G2B_BS1_CONSTRAINT_BASE.xdc
# SHA-256: A05AF5431E521BBC8812DAAE5574CC31D4E7E3BE89DCA0E41974462383BE3071
#
# Intended single BS1 constraint, preserved in the immutable worker:
# set_bus_skew -from $sources -to $sinks 3.000
#
# Resolved application status: NOT_REACHED
