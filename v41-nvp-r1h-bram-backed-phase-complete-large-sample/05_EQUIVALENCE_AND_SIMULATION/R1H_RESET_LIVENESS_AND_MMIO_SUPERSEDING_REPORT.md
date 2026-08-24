# R1h reset-liveness and MMIO integration — superseding result

This report supersedes the earlier MMIO component receipts whose DUT hashes
predate the reset-liveness correction. The first task-local reset regression
is intentionally retained as failed harness evidence: its test asserted the
global host-ready signal while address zero selected an unrelated local path.
The corrected test observes the R1h service handshake itself and the runner
fails closed on failure diagnostics as well as process status.

## Exact identity

```text
R1G_PARENT_COMMIT=e112a5addb7ac62700a9a71af81bf368fad0bada
VIVADO_SIMULATOR=2025.2
VIVADO_SW_BUILD=6299465
TOP=ahd_capture_top_xdma
SOURCE_COMMIT_STATE=UNCOMMITTED_AUTHORIZED_R1H_CANDIDATE
```

Final source hashes exercised by regression 02:

```text
D37A7ECC4C4335149428A75FFE71E0C2FA128F69AEA8E0781658DD22ED65623E  rtl/top/ahd_capture_top_xdma.sv
00ECE27375BE07D52E8FA4BF07F535AB29DC39A099AF4FC148BF654E0073BA2B  rtl/v41/r1h_mmio_read_service.sv
2EA788E5A9CA5D9F5663A0A1595009BDB20D7D1F81F8BE917721F79BFE802B40  tests/v41/tb_r1h_mmio_read_service.sv
6DE31F62629E0C64D35700DD1A57193C5F4240A224B4BF4763D69076FD61BD68  tests/v41/tb_r1h_mmio_integration_exhaustive.sv
```

## Corrected reset contract

The service advertises `req_ready=0` and `rsp_valid=0` while reset is
asserted. Its top-level reset is `(~axi_aresetn) || nvp_por_reset`; therefore
neither an AXI reset nor an NVP POR reset can leave a record/index request
waiting for a storage response that was suppressed by reset. An accepted
request pending when either reset asserts is cancelled, matching the existing
reset-cancellation contract.

## Passing regressions

```text
R1H_MMIO_READ_SERVICE_PASS accepted=10 consumed=6 reset_cancelled=4
R1H_MMIO_INTEGRATION_EXHAUSTIVE_PASS aligned_reads=1368 unaligned_reads=4104 forwarded_writes=1368 ordering_pairs=1 reset_cancellations=2
FINAL_TOP_ELABORATION=PASS
REQ_READY_DURING_RESET=0
PENDING_MEMORY_READ_CANCELLED_BY_NVP_OR_AXI_RESET=PASS
LOST_RESPONSES=0
DUPLICATED_RESPONSES=0
SYNTH_DESIGN_INVOKED=NO
IMPLEMENTATION_INVOKED=NO
```

The exhaustive test still covers every aligned DWORD and every unaligned byte
address in `0x20A0..0x35FF`, deterministic-zero invalid reads, all forwarded
writes, ordering, busy rejection, response backpressure, and reset recovery.

Evidence hashes:

```text
4479BD039180B0D7EED39A2963DBBF34B7B85BB549DB8D1DD5B6566CBC0D752D  reset_liveness_regression_02/service/xsim.log
A26C1F98E17F1DB42E1DBB5ABB677AF8626EBE0F71EA100940A2990E7EBD3977  reset_liveness_regression_02/integration/xsim.log
745A14A9AED2D6B102C6FBB2A5CA2533914AA781005F54276AC62E6AE94E85AE  reset_liveness_regression_02/top/xelab.log
```

Result: `PASS_CURRENT_RTL_RESET_COHERENT`.
