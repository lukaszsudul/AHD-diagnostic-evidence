
# R3R4R6R1 Authorization Receipt

Owner authorization was applied to one fresh DUT-local build and one finite
prequeued C2H session. No retry occurred. Writes were limited to one transport
reset, one combined `ERROR_STATUS` W1C, two coherent snapshot requests, one
stream enable, and one safety disable following the short primary completion.
There was no JTAG access, FPGA programming, reboot, Flash access, power cycle,
package installation, SSOT change, bitstream change, driver change, or ABI
change.
