# Formal identity

Accepted reader:

- Binary: `/home/vcdeagent1/FPGA_AHD_HOST/phase2_precheck_accepted/xdma_axil_read`
- Binary SHA-256: `808AA85670CCEBD288DE6EA7EE05BEF303272A6E555273E763D75DC45B68351E`
- Source SHA-256: `868842808943594C2F41F086D40EF27CF781C7E6DAC5504D6D0EBC52DDA041D7`
- Access behavior: `O_RDONLY` and `pread`; no write path.

The initial unprivileged call stopped before MMIO because the accepted nodes are root-only. The subsequent authorized sudo call read all four registers successfully.

    BLOCK_ID=0xA40A0C07
    PROTOCOL=0x0000400B
    CAPABILITIES=0x00031002
    DIAGNOSTIC_MAGIC=0x00000000
    FORMAL_IDENTITY=PASS_A40A0C07_0000400B_00031002

