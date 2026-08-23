# R5 evidence secret-scan guidance and result

The scan was local and read-only. It did not open the external credential file, start a network process, or invoke Vivado/JTAG/MMIO/reboot/driver tooling.

## Result

TEXT_FILES_SCANNED=91
HIGH_CONFIDENCE_SECRET_MATCHES=0
CREDENTIAL_FILE_COPIES_INSIDE_TASK_ROOT=0
CONTEXTUAL_PLINK_SESSION_RECEIPTS=3
CONTEXTUAL_PLINK_RECEIPT_FAILURES=0
EXTERNAL_CREDENTIAL_FILE_OPENED_BY_SCAN=NO
NETWORK_OR_HARDWARE_ACTIONS_BY_SCAN=0
SECRET_SCAN_GATE=PASS

## Packaging guidance

- Never package `C:\FPGA\VCDE-DUT-1.txt` or any temporary pwfile.
- Preserve the contextual transport receipts proving `-pwfile`, pinned host key, `-batch`, `-noagent`, `-noshare`, no inline `-pw`, and pwfile deletion.
- After all final text evidence is staged, re-run this scanner with `-ResultPath` set to a fresh file under `09_FINAL`; do not overwrite an earlier result.
- Hash the sealed package after the final scan. Do not include an evidence ZIP inside itself.
- Treat any later private-key header, bearer/JWT/API token, quoted password literal, inline PuTTY password, or credential-file copy as a publication blocker.
