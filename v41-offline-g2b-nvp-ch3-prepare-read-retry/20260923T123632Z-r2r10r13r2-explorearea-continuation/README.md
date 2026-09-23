# AHD v41 CH3 R2R10R13R2 — ExploreArea post-synth continuation

## Result

- Exact input: R13R1 post-synthesis DCP, 53,794,550 bytes, SHA-256 `C4906596B0DEB7957C150D8FA3D0377908DD930339C5FC619BE961667596DDAE`.
- Source identity: commit `88ac649a8484ff359270ec19ab539478edf534c0`, tree `8120a9560d85c1a147b30941e47901e52af0b306`.
- Product source changes and new top-level synthesis: zero.
- Process: `opt_design -directive ExploreArea=PASS`, `place_design=PASS`, `route_design=PASS`, `write_bitstream=PASS`.
- Post-ExploreArea: 20,575 Slice LUT, 22,191 registers, 28.5 BRAM tiles.
- Routed: 19,905 Slice LUT, 22,191 registers, 28.5 BRAM tiles.
- Reduction versus the R13R1 default post-opt result of 20,845 LUT: 270 LUT.
- Routing: 39,821/39,821 routable nets fully routed, zero nets with routing errors.
- Output status: `BITSTREAM_GENERATED_UNTESTED`.

## Output identity

- Bitstream: 2,192,144 bytes, SHA-256 `22DACBCF9245BB04901B106A27BB37248B14CC877B92DB1774FFAF63FA4B716A`.
- Routed DCP: 17,718,175 bytes, SHA-256 `C907318FB88B93C224B03468AACF9880D14399383F0F6A77E8FC29F59C9B376D`.
- Post-opt ExploreArea DCP: 7,103,721 bytes, SHA-256 `F8E7042BDA0DBD151BD505250A7309E657C0DF3EB6504FD9C072DFF46C4A3ACE`.
- Input DCP remained byte-identical before and after the run.

Binary artifacts remain private and are not included here.

## Native observations and scope

The router emitted estimated WNS `+0.083 ns`, TNS `0.000 ns`, WHS `+0.029 ns`, and THS `0.000 ns`. These are native process observations, not additional timing sign-off. The mandatory bit-generation DRC completed with zero errors.

The retry contract, 16-entry PREPARE allowlist, 1/4 retry budgets, four-slot telemetry v1, MMIO ABI, host decoder, and microcode were unchanged. No simulation, host test, regression, formal equivalence, lint, extra timing/DRC/CDC/bus-skew/methodology report, or hardware operation was performed. Retry effectiveness, EQ execution, camera scene, physical NACK cause, functional equivalence, and product qualification remain unproven. Historical R13 and R13R1 results remain unchanged.
