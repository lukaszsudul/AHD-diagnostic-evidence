
# Sanitization receipt

All published artifacts are text. Task-path occurrences equal to the DUT credential were replaced with `DUT_USER_REDACTED`; workstation identity, DUT IPv4, host key, and credential-file names are rejected. No credential value was read by the evidence generator. No vendor PDF, reference-driver source, bitstream, DCP, XDMA driver/binary, native helper, camera frame, or camera pixel payload is included. The required JSONL files contain only read-only NVP register evidence and host metadata. Original and sanitized hashes are recorded in the generator provenance table inside the machine state preparation log.
