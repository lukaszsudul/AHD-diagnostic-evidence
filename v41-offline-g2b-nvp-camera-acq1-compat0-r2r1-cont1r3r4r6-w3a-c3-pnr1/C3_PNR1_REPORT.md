# AHD v41 — C3-PNR1, jedna implementacja niezmienionego C3

**Task:** `CONT1R3R4R6-W3A-C3-PNR1`  
**Engineering gate:** `PASS`  
**Evidence publication:** `PENDING_COMMIT_PINNED_READBACK` w tym migawkowym raporcie; ostateczny lokalny receipt po publikacji rozliczy ją niezależnie.  
**Overall result:** `PASS_C3_IMPLEMENTED_FINAL_LUT_LIMIT_MET_WITH_SCOPED_POSTOPT_EXCEPTION` (offline, bez symulacji i kwalifikacji sprzętowej).

| Pole | Wynik |
|---|---|
| Source candidate / commit / tree | C3 / `70266f0b90c6fc6a853495eba1d526b285fd7286` / `5f2bd8377985406b45433418b20be8993399bcb6` |
| New source revisions / historyczny budżet | `0` / `4/4_USED_UNCHANGED` |
| Budżet implementacji / punkt startowy / input checkpoint | `1/1` / `REPRODUCED_C3` / `NONE` |
| Wywołania synth / opt / place / phys_opt / route / bitgen | `1 / 1 / 1 / 1 / 1 / 1` |
| Post-opt LUT / dopuszczenie | `20 456` / `OWNER_EXCEPTION_C3_POST_OPT` (historyczne przekroczenie normalnego progu 20 384 nie zostało wymazane) |
| Final routed whole-design Slice LUT / limit / zapas | `19 995 / 20 384 / 389`; logic `18 742`, memory `1 253` |
| FF / RAMB36E1 / RAMB18E1 / DSP | `21 833 / 26 / 4 / 0` |
| Routing | `39 115/39 115` sieci w pełni trasowanych; `0` błędów |
| Timing WNS / TNS / WHS / THS / WPWS / TPWS | `+0,102 / 0,000 / +0,031 / 0,000 / 0,000 / 0,000 ns`; brak failing endpoints |
| Check timing / unconstrained | `no_clock=0`, `unconstrained_internal_endpoints=0`, `multiple_clock=0`, `generated_clocks=0`, `loops=0`; historyczne `no_input_delay=3`, `no_output_delay=3`, `pulse_width_clock=2` bez zmiany względem zaakceptowanego widoku |
| DRC / methodology | Każdy: `0 Error`, `0 Critical Warning`. Zwykłe ostrzeżenia odpowiednio `24` i `18`; nowe klasy opisano w `signoff/WARNING_SCOPE_NOTES.md`, bez ukrycia lub waivers. |
| CDC | `PASS_CURRENT_C3_SEMANTIC_MANIFEST_RECONCILED`: 1 337 wierszy (427 critical, 874 warning, 36 info), 53/53 zmienionych reprezentantów z dokładną równością pełnych i międzyzegarowych stożków, 64/64 przeniesionych `/D`→`/S` z dokładnie tym samym zbiorem źródeł między zegarami; bez broad waiver. |
| Bus-skew / promoted checks | `11/11 PASS` na bieżącej trasie, pełne XDC przywrócone; `17/17 PASS`, w tym obie kontrole Group-13. |
| Independent DCP reopen | `PASS_SIGNED_DCP_INDEPENDENT_AS_STORED_REOPEN`; zgodne clock/netlist/route/XDC, 157/157 uporządkowanych poleceń XDC i sześć rodzin raportów. |
| Signed DCP | `C:\FPGA\W3A_C3_PNR1_20260917T221245Z\signoff\C3_PNR1_SIGNED.dcp`; 63 219 896 B; SHA-256 `A99EDFE4DF21A3607EC1C31464AD4A03EC6717FCBABBC2979FDA4DFF48E188A5` |
| Firmware | `C:\FPGA\W3A_C3_PNR1_20260917T221245Z\firmware\AHD_v41_W3A_C3_PNR1_DIAGNOSTIC.bit`; 2 192 144 B; SHA-256 `8B6402C776AAF6B2D6E0F4453479B75462516AB79A9FE534257CD5339B95A51B`; nagłówek top `ahd_capture_top_xdma`, part `7a35tcsg325` |
| C3 host / kontrakt / errata | 7/7 plików byte-identical; kontrakt SHA-256 `7F2A9647EF60D360B9884E57F6FAE16BCAFC4DD8F60D592CE0A44D728FA67D39`; `C3_STATUS_BIT1_ERRATUM.md`; self-test offline PASS bez otwarcia urządzenia |
| Prywatny ZIP | `C:\FPGA\W3A_C3_PNR1_20260917T221245Z\firmware\AHD_v41_W3A_C3_PNR1_PRIVATE.zip`; 665 665 B; SHA-256 `4D7C1A13504ACD2C2D42F54CFF473F94B409F247E344193568C3732B487BC995`; 11/11 elementów odczytanych byte-exact |
| XSIM_NEW_RUNS / new RTL simulation / new formal campaigns | `0 / NOT_RUN_OWNER_REQUESTED_SPEEDUP / 0` |
| Behavioral assurance / hardware qualification | `LIMITED_STATIC_REVIEW_AND_IDENTIFIED_HISTORY / NOT_RUN` |
| DUT contact / programming / new scans / camera frames | `NONE / 0 / 0 / 0` |
| Project-current-state | revision `9` przy wejściu i przed publikacją; ostatni commit zmieniający SSOT `f8429a81e22a2f887afd06b334889c30aed7a293`; brak META/PRODUCT/SSOT edit |
| First blocker / next step | `NONE` / osobno zarządzane dopuszczenie W4 dokładnych hashy, bez domniemanej zgody na hardware |

Implementacja ukończyła `route_design` i zapisała trasowany DCP. Oryginalny wrapper zakończył się następnie błędem parsera `ROUTED_LUT_COUNT_NOT_PARSED`, ponieważ oczekiwał etykiety `Slice LUTs*`, a raport po route użył `Slice LUTs`. Liczbę 19 995 odczytano z rzeczywistego `ROUTED_UTILIZATION.rpt`; brakujące raporty i wydanie domknięto z zachowanego DCP **bez drugiego synth/opt/place/route**. To zdarzenie i pojedyncza próba są w ledgerze.

Bitstream jest lokalnym artefaktem diagnostycznym. Nie przeprowadzono XSim, innej symulacji RTL, programowania, kontaktu z DUT ani skanu kamery. Przejście implementacji nie dowodzi funkcjonalnego usunięcia NACK, uzyskania klatki ani kwalifikacji 10 000 skanów. W4 handoff zachowuje erratę status bit 1 i wymaga nowej, osobnej autoryzacji sprzętowej.

Publiczny pakiet dowodowy nie zawiera RTL, DCP, `.bit`, sterownika ani obrazu. Status publikacji zostanie ustalony dopiero po niezależnym odczycie bajtów z dokładnego nowego commita repo dowodów.
