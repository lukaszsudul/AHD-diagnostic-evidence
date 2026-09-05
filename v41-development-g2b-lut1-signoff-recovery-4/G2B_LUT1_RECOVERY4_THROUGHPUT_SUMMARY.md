# Offline throughput — PASS

Record 4096 = 64 header + 3840 payload + 192 zero padding bytes. Payload efficiency 93.75%; overhead 6.25% of transport. A 64-bit stream uses 512 beats/record with the frozen TKEEP/TLAST contract. Required 288 MB/s payload needs 75,000 records/s and 307.2 MB/s transport. Gen2 x1 after 8b/10b has a theoretical 500 MB/s transport ceiling before packet overhead, giving 468.75 MB/s ideal payload. Required beat duty is 61.44%; gross transport reserve 192.8 MB/s. This governed offline capacity analysis is not a PCIe packet-level or hardware throughput measurement.

OFFLINE_THROUGHPUT = PASS
HARDWARE_THROUGHPUT_PROVEN = NO
