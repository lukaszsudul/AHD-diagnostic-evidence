# NVP Z8 midpoint ACK experiment summary

- Base functional commit: `fd32fcb65be3f1a59c569874195d1faeaf7d27e9`
- Combined R2+Z8 experiment patch SHA-256: `9d90016fad1a1b05c9ca53292f035445350a1143fd0214fc04d58ab9975b4440`
- Half-phase: `626` clocks / `10016` ns
- Mid-high sample: cycle `313`
- FSM-tick context records: `512`
- Shadow ACK event records: `16`
- AXI-Lite reads: `10424`
- AXI-Lite writes: `0`

First functional NACK event:

```json
{
  "ack_event_index": 15,
  "operation_index": 2,
  "slot_index": 1,
  "byte_phase": 1,
  "tx_byte": 96,
  "register": 255,
  "write_value": 0,
  "meta_bank": 1,
  "physical_bank": 0,
  "physical_bank_valid": 1,
  "original_r1_ack_decision": "NACK_HIGH",
  "z8_consumed_ack": "NACK_HIGH",
  "z8_sample_invalid": 0,
  "z8_sampled_scl": 1,
  "functional_decision_sda": 1,
  "functional_decision_scl": 0,
  "functional_decision_sda_drive_low": 0,
  "functional_decision_scl_drive_low": 1,
  "first_nack_event": 1,
  "scl_high_observed": 1,
  "early_high_valid": 1,
  "mid_high_valid": 1,
  "late_high_valid": 1,
  "sda_released_during_ack": 1,
  "scl_released_during_ack": 1,
  "half_phase_cycle_count_valid": 1,
  "early_high_sda_stage1": 1,
  "early_high_sda_stage2": 1,
  "early_high_sda_filtered": 1,
  "early_high_scl_stage1": 1,
  "early_high_scl_stage2": 1,
  "early_high_scl_filtered": 1,
  "early_high_sda_drive_low": 0,
  "early_high_scl_drive_low": 0,
  "mid_high_sda_stage1": 1,
  "mid_high_sda_stage2": 1,
  "mid_high_sda_filtered": 1,
  "mid_high_scl_stage1": 1,
  "mid_high_scl_stage2": 1,
  "mid_high_scl_filtered": 1,
  "mid_high_sda_drive_low": 0,
  "mid_high_scl_drive_low": 0,
  "late_high_sda_stage1": 1,
  "late_high_sda_stage2": 1,
  "late_high_sda_filtered": 1,
  "late_high_scl_stage1": 1,
  "late_high_scl_stage2": 1,
  "late_high_scl_filtered": 1,
  "late_high_sda_drive_low": 0,
  "late_high_scl_drive_low": 0,
  "early_high_offset_cycles": 9,
  "mid_high_offset_cycles": 313,
  "late_high_offset_cycles": 626,
  "measured_half_phase_cycles": 626,
  "init_phase": 1,
  "preinit_action": 2,
  "init_action": 2,
  "pending_bank": 1,
  "pending_register": 202,
  "pending_data": 102,
  "first_error_code": 0,
  "first_error_step": 0,
  "first_error_meta_bank": 0,
  "first_error_register": 0,
  "first_error_value": 0,
  "init_active": 1,
  "init_done": 0,
  "init_error": 0,
  "no_scl_high": 0,
  "shadow_correct_phase_ack": "NACK_HIGH",
  "classification": "REAL_DIGITAL_NACK",
  "raw_hex": "0xA1000000000066CA010202019CA724E4093F3F3F3FE5000100FF60010102000F"
}
```

```text
Z8_FALSE_NACK_COUNT=0
Z8_REAL_DIGITAL_NACK_COUNT=1
Z8_INVALID_ACK_WINDOWS=0
TRACE_TELEMETRY_CORRELATION=PASS
Z8_PRIMARY_CLASSIFICATION=Z8_INSUFFICIENT_REAL_DIGITAL_NACK_REMAINS
RAW_ANALOG_MEASUREMENT_AVAILABLE=NO
AXIL_WRITES=0
C2H_TRANSFERS=0
H2C_TRANSFERS=0
```
