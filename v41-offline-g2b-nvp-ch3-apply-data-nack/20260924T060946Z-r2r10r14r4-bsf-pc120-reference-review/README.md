# AHD v41 R2R10R14R4 — BSF / PC120 reference review

## Scope

Offline retained-evidence and pinned-reference review only. No DUT contact, driver operation, build, simulation, product change, or historical-result mutation occurred.

## Identity

- Product source: `88ac649a8484ff359270ec19ab539478edf534c0`
- Product tree: `8120a9560d85c1a147b30941e47901e52af0b306`
- R13R2 bitstream SHA-256: `22DACBCF9245BB04901B106A27BB37248B14CC877B92DB1774FFAF63FA4B716A`
- Pinned reference: `4e4o/nvp6134_ex@081ebbff9a2722d47acf16c680594be43cb179e2`
- Historical R14R3 evidence: `15fc8e497000d8cdbc25dd646c00050fdd429f30`

## Findings

1. Bank B is `0x0B` (decimal 11). `0x11` is decimal 17 and is not an alias.
2. The original manufacturer datasheet associates Manual BSF with Bank A–B and the `0x60–0x72` range. This establishes a range association, not the individual access or side-effect semantics of Bank `0x0B` register `0x71`.
3. For physical CH3 / channel index 2, the pinned reference resolves to Bank `0x0B` and the lower `0x60–0x72` range. All 19 ordered register/value pairs match PC103–121.
4. PC120 `0x71=0x6D` matches the pinned reference. Historical R14R3 ended there with DATA_NACK after the complete data byte had been clocked. Whether the device committed the write is not retained or established.
5. The active source plans CH3 BSF mode bits as `00` (LPF Auto) before PC120; no physical readback of that field was retained. Loading the Bank B range therefore does not prove that Manual BSF was active.
6. Product settle is 300 us after each successful write. The pinned reference exposes 200 us and 300 us helper variants; an external GPIO helper and the selected reference platform remain unresolved.

## Decision

`WRITE_REPEATABILITY=NOT_ESTABLISHED_MISSING_REGISTER_OR_SEQUENCE_SEMANTICS`

Matching values prove configuration provenance. They do not establish idempotence after an ambiguous DATA_NACK, a harmless individual readback, or the safety of retrying one byte in place.

## One next action

Separately authorize acquisition and review of authoritative access, commit, side-effect, and readback semantics for Bank `0x0B` register `0x71` within `0x60–0x72`. The needed information must resolve whether commit can precede the observed ACK, whether rewriting `0x6D` is safe after either possible first-write outcome, and whether a single readback is defined and sufficient.

Historical R14R3 remains FAIL before EQ. Physical NACK root cause remains unproven.
