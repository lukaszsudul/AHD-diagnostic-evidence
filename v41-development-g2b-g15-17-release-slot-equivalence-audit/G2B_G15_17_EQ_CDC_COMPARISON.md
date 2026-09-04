# Focused CDC comparison

## Release qualifier

For every slot the routed checkpoint contains exactly one `userclk1` FDRE release toggle, one `nvp_vclk1` FDRE sync1, one `nvp_vclk1` FDRE sync2, and one `nvp_vclk1` FDRE history register. Sync1 and sync2 both have `ASYNC_REG=1`, have no reset/control net, and form direct toggle-to-sync1 and sync1-to-sync2 edges. Each sync pair is co-located. Physical locations differ, which is expected and was not normalized away.

## Stable-data payload

Each 56-bit generation/epoch payload crosses without per-bit synchronizers. This is intentional stable-data CDC. Its qualifier is the synchronized release toggle, its launch and hold rules are proven in RTL, and each of its three actual semantic-use families has an absolute 6.000 ns datapath-only settling check. Every collection resolved to 56 sources and 3, 4, or 3 destinations.

## Reset and retirement

All slots share a single transport request path with one toggle and two direct `ASYNC_REG` stages into `nvp_vclk1`. The return acknowledgement likewise has two direct `ASYNC_REG` stages into `userclk1`. Reset-overlap accounting uses the captured four-bit release phase. Retirement waits for the complete synchronized release vector and ownership phase, preventing a lagging old phase from being accepted after reset.

## Mismatch and endpoint closure

The normal destination is exactly the selected slot's three state bits. Mismatch closure is exactly the four shared fatal/event/deferred/admission registers. Reset closure is exactly the three reset-abandoned accounting bits. The old 20-register destination expression mixed roles, included 13 irrelevant endpoints for each slot, and excluded reset closure.

## Disposition

- `SLOT1_CDC_STRUCTURE = PASS_WITH_DISPOSITION`
- `SLOT2_CDC_STRUCTURE = PASS_WITH_DISPOSITION`
- `SLOT3_CDC_STRUCTURE = PASS_WITH_DISPOSITION`

The disposition is the accepted stable-data-plus-synchronized-qualifier protocol, not an unresolved warning. This audit is intentionally focused and does not claim closure of the full global CDC report. Exact mapped logic depths differ, but synchronizer depth, attributes, clocks, reset behavior, protocol ordering, endpoint roles, and hold lifetime are equivalent.
