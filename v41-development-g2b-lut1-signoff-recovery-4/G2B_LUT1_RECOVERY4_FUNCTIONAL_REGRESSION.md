# Functional regression — PASS

Fresh 11/11 G2B host ABI/parser tests and 16/16 R1i tests pass. The first G2B invocation could not locate the frozen ABI in the sparse checkout; its log is preserved. The successful invocation used the exact tracked frozen ABI JSON retrieved into this recovery directory.

No RTL or test-source drift since the recovery-1 accepted source. Its functional evidence is preserved for one-channel C2H, four-slot ring, formatter, TKEEP/TLAST, backpressure, sequence/reset epoch, coherent snapshot, ABI golden vectors and frame reconstruction. The complete prior receipt is copied as preserved_functional_authority.md. Current MMIO, profile and R1i trace hashes were reverified in functional_hashes.json.

ABI/MMIO unchanged: YES. Hardware accessed: NO.
