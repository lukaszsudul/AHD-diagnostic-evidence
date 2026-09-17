# Owner cold-start authorization

The Owner explicitly allowed one normal shutdown and physical cold start of
the whole DUT, including the second PCIe device, and replied
`DUT_COLD_START_COMPLETE`. The reply is an attestation of the physical action,
not a rail-voltage measurement. The attached task also allowed one exact AHD
SRAM programming attempt and one conditional, predeclared graceful warm reboot
for PCIe enumeration, then use of the existing qualified driver and a single
control-plus-1,000-scan characterization if all gates passed.

The Owner specifically prohibited driver binary/name/namespace changes,
autostart or boot-configuration edits, foreign-driver manipulation, a second
cold cycle or programming attempt, camera capture and ungoverned recovery.
This run did not alter driver files, startup configuration, the FPGA source,
SSOT or the protected function. No new hardware action is authorized by the
incomplete-campaign result.
