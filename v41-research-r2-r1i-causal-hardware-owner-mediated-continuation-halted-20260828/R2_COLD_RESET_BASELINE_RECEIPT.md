# R2 Cold-Reset and Safe-Baseline Receipt

## Owner cold reset

- Owner cold reset recognized: `YES`
- Counted as a formal cold-start trial: `NO`
- Role: `PRECONDITION ONLY`
- Formal Owner-mediated manual-reset receipts created: `0`

The reset occurred before the earlier R2 attempt and before formal start-of-trial instrumentation. It is therefore not part of the frozen ten-trial denominator.

## Fresh read-only entry state

- hostname: `VCDE-DUT-1`
- remote user: `vcdeagent1`
- kernel: `7.0.0-29-generic`
- boot ID: `c53a4c28-4120-4527-89e2-1108cfaaa2f3`
- Xilinx PCIe functions: `NONE`
- XDMA module: `NOT_LOADED`
- XDMA device nodes: `NONE`
- JTAG part: `xc7a35t`
- JTAG IDCODE: `0362D093`
- DONE samples: `0` in `5/5`
- FPGA programming invocations during entry probe: `0`
- starting classification: `UNPROGRAMMED_OR_FPGA_UNKNOWN`, resolved as unprogrammed
- PCIe classification: `PCIe_NOT_ENUMERATED`
- source entry-state receipt SHA-256: `308E013E316902A554DD324949F8C986A82DD01A453CE9EA3749792C2F9D6DE5`

## Safe baseline establishment

- result: `PASS`
- role: Formal Phase-2
- bitstream SHA-256: `7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2`
- program receipt SHA-256: `D7F27EE1B266B9940D4CF111676FE52BF717962C21D125BAA8FE73B8DC807B21`
- independent DONE receipt SHA-256: `CF5558D68447DC81DAF7DF7A8262D16976A307D6FE7B606A45EE2810D1DEEF6E`
- host transition receipt SHA-256: `DAD9A20CA1D00F7E98A964B5B4C4899B87154A66A53D6262A7C3C784B3EDC747`
- runtime identity receipt SHA-256: `2B7C850F50A2E9459E7B25DD33B18FE550A7FD9E093CE27FE736586F547EB1C2`
- safe-baseline receipt SHA-256: `F4A9252E2901A7B2CE943F85544B474F51D51BBBCE44EBBB639D9F3E4B8B7B67`
- baseline sealed UTC: `2026-08-28T11:44:34.4852745Z`
- DONE: `1`
- PCIe endpoint: `10ee:7011`, Gen1 ×1
- driver binding: `xdma`
- `BLOCK_ID=0xA40A0C07`
- `PROTOCOL=0x0000400B`
- `CAPABILITIES=0x00031002`
- diagnostic magic: `0x00000000`
- secondary diagnostic magic: `0x00000000`
- flash operations: `0`

## Final restored baseline after halt

- preceding primary run: `R2OM-R03-P2-C3`
- final Formal receipt SHA-256: `26E2FFCEEA193E834CB80777A1E34EA618EDF6E6FECE4E067CD3000EC8E849AF`
- final Formal runtime receipt SHA-256: `5795E9584AF6A28F7EB4AEB81897960F8847A1C89B912ACA63D4763B1F5B6A70`
- baseline sealed UTC: `2026-08-28T18:26:06.1283545Z`
- DONE: `1`
- PCIe endpoint: `10ee:7011`, Gen1 ×1
- driver binding: `xdma`
- `BLOCK_ID=0xA40A0C07`
- `PROTOCOL=0x0000400B`
- `CAPABILITIES=0x00031002`
- diagnostic magic: `0x00000000`
- secondary diagnostic magic: `0x00000000`
- boot ID: `d12b3a07-ea25-4769-8293-88ee8fc92ef2`
- flash operations: `0`

The final state is an identity-verified safe baseline. Formal telemetry is not a primary causal run and is not used to claim candidate functional success.
