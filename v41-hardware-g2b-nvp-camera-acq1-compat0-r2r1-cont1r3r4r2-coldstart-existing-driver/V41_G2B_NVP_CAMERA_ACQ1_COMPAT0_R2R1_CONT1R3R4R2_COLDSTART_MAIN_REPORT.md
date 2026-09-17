# AHD v41 CONT1R3R4R2 — controlled cold start and existing-driver characterization

Engineering gate: **FAIL**. Evidence publication: pending at staging; report the
commit-pinned remote read-back separately after publication. Overall result:
**FAIL**. The first measurement hard stop was
`SCANNER_HARD_STOP:0x00000C18` during the next scan after 25 complete campaign
scans. No retry, resumed campaign, further power cycle or second programming
attempt was made.

## Cold-start and activation facts

The Owner replied `DUT_COLD_START_COMPLETE` after being asked to shut down and
physically cold-start the whole DUT. This is Owner attestation, **not** an
electrical measurement of rail removal. The host and machine ID stayed
`VCDE-DUT-1` / `0e90f50d9465492b80258da5658446f8`; boot ID changed from
`32d7b853-06fe-4004-9c4b-9b4abafbe896` to
`79fc7bcf-5230-4c24-ad7d-456f0eb2c32c`. Endpoint
`10.132.1.111:22` used pinned SSH host key
`SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8`.

Before shutdown, the protected `10ee:7021` function at `0000:0b:00.0` owned
the `xdma` class and 21 nodes; the AHD `10ee:7011` function was unbound.
Current-boot journal evidence supported an interactive `insmod` by another
user. No static autostart source was found in the bounded check, but delayed or
future autoload was not ruled out. After the cold start the class was free,
and **both Xilinx PCI functions were initially absent**. Old BDFs then belonged
to AMD devices and were not treated as card identity.

The exact known AHD JTAG target was checked read-only (`xc7a35t`, IDCODE
`0362D093`, `DONE=0`), then the approved 2,192,144-byte bitstream SHA-256
`CD80C84E17467BCB03DEE58DC7FF64D50FD2CB6E5C409E21F871C3E05052BA09`
was programmed once to volatile SRAM. The programming receipt reports `DONE=1`.
The single predeclared graceful warm reboot established final boot
`e9656f6c-dd41-4500-95cc-9dc90ef9b69d`. AHD enumerated as
`0000:01:00.0`, `10ee:7011`, subsystem `10ee:0007`, Gen2 x1, and the class
remained free. The protected `10ee:7021` function **did not return** after
either boot. It was not manually reloaded, accessed, rebound or configured;
its functional state is outside this qualification.

The already qualified 3,296,104-byte `xdma_ahd_pcie.ko` SHA-256
`E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77`
was loaded once with its unchanged existing path and no parameters. The only
eligible PCI function was AHD. Dynamic nodes resolved through `st_rdev` and
`/sys/dev/char` to the same AHD BDF: `/dev/xdma0_user` `511:0`,
`/dev/xdma0_c2h_0` `511:36`. The index `0` was discovered, not assumed. Node
permissions remained `root:root 0600`; a non-root MMIO attempt failed at
`open` before any MMIO and was not retried as a scan. The same accepted
runtime preflight then ran under the existing privileged mechanism, with
opened-descriptor BDF checks and no permission change.

The closed 34-file runtime bundle passed hash, import, module-origin and
projection gates on the final boot. SCAN1, ACQ, BRAM telemetry and
implementation identities matched the frozen manifest/schema. Inert MMIO
sanity passed `16/16` for SCAN1 and `16/16` for ACQ. Runtime status showed
autoinit done and idle, ACQ error count zero and I2C readiness. A separate
autoinit NACK counter was **not independently recorded**, so this report does
not claim that narrower counter was proven zero. Experimental functional NVP
writes remained zero.

## Measurement and hard stop

One control scan passed. The campaign then persisted **25/1000** complete
scans, each with 82 entries, 10 groups, 82 telemetry exposures, a valid
configuration projection, coherent publication, restored entry bank and
`A8_PRE=A8_POST`. Of those 25, 15 had 105 transactions and 10 had successful
retries. Eleven first-attempt `REGADDR_NACK` events all recovered under the
unchanged one-retry rule. Completed-scan accounting is 2,050 campaign entry
exposures and 250 group records; including control, 2,132 exposures and 260
group records. No timeout or bank-verify failure occurred in a **completed**
scan. These partial counts are not a 1,000-scan rate or qualification.

The next scan stopped with raw status `0x00000C18`, 37 valid entries, 51
transactions and no complete publication. The first-error index was 36 and
detail `0x0005FF0A`. The frozen detail encoding gives Bank 5, register `0xFF`
(bank selection), code `0xA` (`INTERNAL_PROTOCOL_ERROR`). The exact
underlying cause is **unproven**; this is not evidence of a camera format,
analog front-end defect or successful 1,000-scan campaign. The hardware
generation register still read 26, the same generation as the last complete
scan; it is not treated as a new completed generation. The entry/exit bank
both read `0x00000100`, and the restore flag was set. No further scan was
started. Causal interpretation under the preregistration is
`NOT_ASSESSED_CAMPAIGN_INCOMPLETE`.

The 26 complete raw records (control plus 25 campaign scans), 11 event rows,
2,132 exposure rows and associated manifests were sealed in a controller-
private archive, 108,145 bytes, SHA-256
`96080348A26E00ECF8B4DBA58F6E691EBAD48F2D8B0C3DDC2EC474A316E6A0CB`.
The archive is **not published**. Public evidence contains hashes, selected
progress and event summaries only; no camera pixels or raw video exist.

## Cleanup and disposition

With the error snapshot recorded, one qualified SCAN1 `ACK_CLEAR` returned
the scanner to `0x00000011` idle; ACQ remained `0x00800011` idle. No new scan
or functional NVP action occurred. A root-level holder and module-refcount
survey showed zero users of the task-owned AHD nodes; one normal
`rmmod xdma_ahd_pcie` succeeded. The AHD function remained enumerated but
unbound, target nodes and XDMA class disappeared, and no foreign Xilinx
function appeared. The DUT lock was released, then the controller lock was
removed from the active namespace by an exact recoverable move. The approved
diagnostic image remains in volatile SRAM; there was no final reboot, Flash
write or power cycle.

The engineering result is **FAIL** because the 1,000-scan campaign had a
hard scanner error after only 25 complete scans. The cold start did remove
the previous observed namespace conflict in this boot, but it did not prove a
permanent cure, did not restore the protected device and did not yield a
camera frame. The next single practical action toward a real frame is a
**separately governed offline diagnosis of the Bank 5/0xFF internal-protocol
error using the preserved failure receipt and raw scan evidence**. No new
hardware attempt is authorized by this report.
