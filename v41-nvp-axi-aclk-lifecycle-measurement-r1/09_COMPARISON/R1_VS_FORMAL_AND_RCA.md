# R1 versus established controls

| Sample | Image | Infrastructure | INIT_DONE | INIT_ERROR | NACK | TIMEOUT | VCLK | SAV | FRAME | Clock lifecycle result |
|---|---|---:|---:|---:|---:|---:|---|---:|---:|---|
| Current-hardware RC-A control (3/3) | v40.1.0 RC-A | valid | 1 | 0 | 0 | 0 | active | active | active | not instrumented |
| Latest preserved formal Phase-2 delayed-reboot sample | exact formal Phase 2 | valid after channel recovery | 1 | 1 | 9 | 0 | active | 0 | 0 | not instrumented |
| R1 observer image | `4C169486...E72EF5DB` | valid | 1 | 1 | 19 | 0 | active | 0 | 0 | ambiguous: reference stopwatch epoch not retained |
| Same-session restored formal context | exact formal Phase 2 | valid | 1 | 1 | 5 | 0 | active | 0 | 0 | not instrumented |

The R1 counter rate after reboot is compatible with 62.5 MHz. This does not answer whether cycles were lost earlier in the configuration-to-measurement lifecycle because the marker and read brackets do not share a reconstructable stopwatch epoch.
