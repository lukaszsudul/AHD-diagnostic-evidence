# Protected PCIe function lifecycle

Pre-cold boot `32d7b853-06fe-4004-9c4b-9b4abafbe896`: protected
`10ee:7021`, subsystem `10ee:f0a1`, at `0000:0b:00.0`, parent
`0000:00:02.2`, bound to live `xdma` with 21 class entries/nodes. The AHD
`10ee:7011` function at `0000:01:00.0` was unbound. The bounded journal and
startup check supported an interactive `insmod`, but did not prove future
autoload impossible.

Immediately after the Owner-attested whole-DUT cold start, neither Xilinx
function enumerated and the XDMA class was absent. Historical BDFs now
identified AMD functions, so no identity was inferred from BDF alone. After
the one exact AHD SRAM programming and planned warm reboot, AHD
`10ee:7011/10ee:0007` enumerated at `0000:01:00.0` Gen2 x1. The protected
`10ee:7021` function remained absent before target driver load, during the
same-boot AHD interventions and after target cleanup.

No protected node was opened, and no foreign driver was unloaded, reloaded,
unbound, bound or configured. The protected device's pre-cold live module and
node identities were **not** preserved across the authorized loss of power;
that is an observed lifecycle change, not a same-boot intervention by this
task. Its functionality was not tested. The Owner should not infer that the
second device was restored or qualified.
