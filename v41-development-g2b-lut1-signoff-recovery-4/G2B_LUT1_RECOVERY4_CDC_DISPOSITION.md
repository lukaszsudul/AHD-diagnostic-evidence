# CDC disposition — PASS

All 1,401 findings are individually classified in the companion CSV; 427 are critical. No unresolved finding or required RTL change remains in the report review. The continuation verified the four exact CDC-10 ASYNC_REG chain attributes; this gate is final PASS.

The inherited recovery-1 comparator stopped at an old canonical hash. This was not a new CDC rule or destination: comparison against the original Gen12 report proves the entire multiset of rule, destination, clock pair, exception, severity, depth and description is identical. Seventeen critical and nine warning rows select different launch representatives. Every changed representative belongs to an existing reviewed ownership, release, descriptor or reset-return stable-data collection. Changes are enumerated in cdc_comparison.json and marked in the CSV; source differences are not ignored or replaced by count-only matching. The original failure and report are preserved.

No report is rerun. The current rows are reviewed against the promoted structural protocols and fresh/preserved routed timing bounds. Launch representatives across alternative mailbox/slot fan-in are not immutable identities of a report_cdc finding. The DCP/netlist is byte-identical; constraint state is the exact governed update. The obsolete fixed family counts and canonical hashes are not presented as a current PASS.

CDC-10 findings retain the exact original rows and two-stage held-level protocol. CDC-13 findings retain exact generated-clock mux rows and unchanged generated-XDC exceptions. Other finding buckets and individual evidence are in the CSV.

{
  "result": "PASS",
  "total": 1401,
  "critical": 427,
  "critical_dispositioned": 427,
  "unresolved_critical": 0,
  "requires_rtl_change": 0,
  "changed_representatives": 26,
  "unchanged_endpoint_multiset": true,
  "counts": {
    "CDC-1": 423,
    "CDC-3": 30,
    "CDC-6": 13,
    "CDC-9": 6,
    "CDC-10": 2,
    "CDC-13": 2,
    "CDC-15": 925
  },
  "buckets": {
    "ASYNC_ASSERT_SYNC_RELEASE_RESET": 6,
    "FALSE_POSITIVE_WITH_PROOF": 2,
    "TOGGLE_HANDSHAKE": 4,
    "INTENTIONAL_TWO_STAGE_SYNCHRONIZER": 32,
    "STABLE_DATA_WITH_SYNCHRONIZED_QUALIFIER": 1350,
    "GRAY_CODED_CDC": 7
  }
}

Continuation verified all four exact ASYNC_REG chain attributes. FINAL_CDC_DISPOSITION = PASS.
