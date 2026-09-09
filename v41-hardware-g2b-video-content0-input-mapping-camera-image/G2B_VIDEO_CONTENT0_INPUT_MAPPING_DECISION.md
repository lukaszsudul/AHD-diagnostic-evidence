
# Input mapping decision

PHYSICAL_INPUT_MAPPING = PARTIALLY_PROVEN. The active internal route is
VIN1/channel 1 -> VDO1 -> FPGA INPUT_0. The external connector/refdes is
UNKNOWN because matching as-built connector-to-VIN evidence is absent.
`INPUT_MAPPING_MISMATCH = UNRESOLVED`; there is neither per-channel live status
nor a safe runtime scan to prove or disprove that the camera is on another VIN.

Physical Owner action: Connect a powered, uncovered AHD 1080p25 camera aimed at a bright high-contrast target to the PCB connector electrically mapped to NVP VIN1/channel 1; first supply the missing as-built connector-to-VIN1 refdes mapping so that connector can be identified without guessing.
