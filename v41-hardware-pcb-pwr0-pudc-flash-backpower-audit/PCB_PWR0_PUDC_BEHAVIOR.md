# PCB-PWR-0 PUDC_B Behavior

## Exact device and evidence

Device: `xc7a35tcsg325-2` (`xc7a35t`, `csg325`, `-2`).

The behavior below is based on the locally published PCB-PIN-1 transcription of AMD UG470 v1.17, Table 2-4 and its configuration-memory-clear discussion. The actual UG470 PDF was not present in the offline documentation cache. A non-durable secondary extraction suggests Figure 2-14 is a Master SPI x4 topology, but that detail is not treated as authoritative local proof.

## Meaning of LOW

PUDC_B is active low.

Once the applicable FPGA supplies are valid and before user configuration takes ownership, LOW enables the weak internal pull-up policy on ordinary/inactive SelectIO. During configuration, global three-state keeps those user drivers high-Z while the pull-up biases the pad toward that bank's VCCO.

Therefore the preconfiguration state is:

`ordinary/inactive SelectIO = high-Z driver + weak internal pull-up`

It is not an internal pull-down. It is also not a guaranteed logic high when the bank supply is absent, when a receiver clamps the node, or when an external resistor opposes it.

## Meaning of HIGH

Once the applicable supplies are valid, HIGH disables the global weak SelectIO pull-ups during the power-up/configuration interval. Global three-state still disables the ordinary user drivers.

Therefore the preconfiguration state is:

`ordinary/inactive SelectIO = high-Z driver, no global configuration pull`

HIGH does not enable pull-downs. Deterministic board behavior must come from net-specific external biasing, powered-domain pulls, or isolation.

## What PUDC_B does not control

PUDC_B does not turn dedicated configuration pins into ordinary user I/O and does not disable pins actively required by the selected configuration mode. This is an engineering inference from the transcription's SelectIO-specific pull wording plus exact Vivado/BSDL pin classifications; the original UG470 sentence/table body was not locally readable.

- Dedicated Bank-0 configuration pins—CCLK, DONE, INIT_B, PROGRAM_B, and M[2:0]—retain their defined configuration behavior. CFGBVS defines the Bank-0 configuration-voltage selection relationship.
- Dual-purpose Bank-14 pins used by Master SPI—FCS_B and the active DQ pins—perform their configuration functions. Width and topology determine which DQ pins are active.
- Dual-purpose configuration pins not active in the selected mode must not be assumed ordinary until the exact UG470 mode table is checked. In particular, T18/DOUT_CSO_B and any proposed user assignment need explicit mode/daisy-chain review.
- Ordinary SelectIO become application I/O only after startup/EOS. Their configured PULLUP/PULLDOWN/KEEPER and output INIT behavior are separate from PUDC_B's preconfiguration policy.

## Weak pull strength

The locally published PCB-PIN-1 DS181 transcription records a selected 3.3 V pad pull-up current range of 90 to 330 microamps at VIN=0. This is a per-pad characteristic under its stated test condition, not a guaranteed aggregate current into an unpowered peripheral. Receiver clamps, bank voltage, temperature, and node voltage change the result.

With many NVP inputs connected, no exact total is reported because the final signal count, active configuration roles, powered-off receiver paths, and applicable current conditions are not all known.

`PUDC_LOW_AGGREGATE_INJECTION_RISK = HIGH`

## Related-board evidence

The reported HDMI prototype measurements are retained verbatim as a classification, not generalized as an AHD measurement:

- PUDC_B LOW -> nominally off ADV 3.3 V domain measured about 1.2 V;
- PUDC_B HIGH -> nominally off ADV 3.3 V domain measured about 0 V.

`EVIDENCE_CLASS = EXPERIMENTAL_EVIDENCE_FROM_RELATED_BOARD`

This supports the physical plausibility of aggregate clamp/back-power current. It does not establish the AHD voltage, current, safety, or damaged/undamaged condition.

## Strap implementation

The prior UG470 transcription states that PUDC_B is tied directly or through no more than 1 kOhm to VCCO_14 or GND. A HIGH option must therefore reference the actual VCCO_14 rail, not an unrelated permanent 3.3 V rail that can exist while Bank 14 is off.

Recommended routing option:

- one footprint from PUDC_B to VCCO_14;
- one footprint from PUDC_B to GND;
- mutually exclusive population and a BOM note that prohibits simultaneous stuffing;
- default proposed population HIGH; and
- accessible measurement/test documentation, not a live jumper that can be moved under power.

## AMD Figure 2-14 boundary

The electronics designer reports that Figure 2-14 connects PUDC_B to GND, and a secondary session extraction suggests the figure is a Master SPI x4 example. No stable local UG470 body/PDF exists to verify its title, complete topology, or caption. Those details remain a confirmation item. Independently, the locally published Table 2-4 transcription permits PUDC_B to VCCO_14 (HIGH) or GND (LOW) through the specified direct/<=1 kOhm connection. Therefore even if the reported drawing is confirmed, it demonstrates one valid example/default and cannot make LOW mandatory.

- `UG470_FIGURE_2_14_TOPOLOGY = REQUIRES_UG470_PDF_CONFIRMATION`
- `SECONDARY_TRANSCRIPT_SUGGESTS = MASTER_SPI_X4_REFERENCE_EXAMPLE`
- `FIGURE_2_14_PUDC_GND_STATUS = DESIGNER_REPORTED_EXAMPLE_NOT_MANDATORY`
- `GENERAL_PUDC_LOW_RECOMMENDATION_FROM_FIGURE = NOT_ESTABLISHED`
- `PUDC_HIGH_EXPLICITLY_SUPPORTED = YES`
