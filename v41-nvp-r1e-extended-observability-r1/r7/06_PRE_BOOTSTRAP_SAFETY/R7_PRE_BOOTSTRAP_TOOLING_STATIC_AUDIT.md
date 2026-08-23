# R7 pre-bootstrap host-safety tooling static audit

```text
PRE_BOOTSTRAP_TOOLING_STATIC_AUDIT=PASS
PRE_BOOTSTRAP_TOOL=PREPARED_NOT_EXECUTED
LIVE_SSH_EXECUTED_BY_THIS_AUDIT=0
```

The supervisor is bound to the exact R7 baseline receipt
`R7_HOST_BASELINE=PASS_2_OF_2`, its caller-supplied boot ID, the exact formal
bit size/hash, and the selected-JTAG receipt
`R7_JTAG_RECONFIRMATION_GATE=PASS_5_OF_5`. It also validates the exact canonical
target suffix and requires a stable recorded DONE value of 0 or 1.

The remote payload accepts zero or one exact expected endpoint and accepts
driver/node absence before bootstrap. It rejects foreign/multiple Xilinx
functions, a wrong same-name XDMA module, node owners, task DMA, and critical
kernel/AER conditions. It checks that all three R7 loader evidence directories
are absent/fresh and performs contextual runtime reads only when access exists.

```text
Invoke-R7PreBootstrapSafetyDiscovery.ps1_SHA256=814665CFE3534FF53243A7FC8A6FD63FC8B35DFBCD7AE93804477057B573D017
r7_prebootstrap_safety_readonly.sh_SHA256=FC7868B7CD536A4F3C3D8365AA6950F8B76378687CEE6B8047DECDF2FD6FDB45
parse_pci_bars.py_SHA256=5F7A6BDBF498720E1B40C54AB71A7E86BBD43AF1758AB207CF7EEBA65B15A922
FORMAL_BIT_SHA256=7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2
FORMAL_BIT_SIZE_BYTES=2192144
POWERSHELL_PARSE=PASS
HOST_OR_PCIE_MUTATION_COMMANDS=0
```
