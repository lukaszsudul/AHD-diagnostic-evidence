
# Next root-cause scope

The FPGA/XDMA/host pixel path is proven on CH1 and CH3. CH2 and CH4 consistently
retain VCLK but expose no SAV, while every NOVID bit remains asserted. The next
scope is an NVP6134C channel-private Bank 5/6/7/8 equivalence and VDO1
route/re-arm investigation for CH2/CH4, plus camera format, power, cabling,
analog-front-end, and connector-to-VIN mapping. Do not modify the proven FPGA
transport for that investigation.
