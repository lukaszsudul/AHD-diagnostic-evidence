# NVP ACK shadow-monitor R2 summary

- Base functional commit: `fd32fcb65be3f1a59c569874195d1faeaf7d27e9`
- Observer R2 patch SHA-256: `78c2d4099a20f1a8c81d15cbe7e7ab15e7f041fba9c03a07ae83593ccd2f0e51`
- Half-phase: `626` clocks / `10016` ns
- Mid-high sample: cycle `313`
- FSM-tick context records: `512`
- Shadow ACK event records: `145`
- AXI-Lite reads: `11456`
- AXI-Lite writes: `0`

First functional NACK event:

```json
{
  "ack_event_index": 144,
  "operation_index": 31,
  "slot_index": 30,
  "byte_phase": 1,
  "tx_byte": 96,
  "register": 88,
  "write_value": 0,
  "meta_bank": 5,
  "physical_bank": 5,
  "physical_bank_valid": 1,
  "functional_ack_decision": "NACK_HIGH",
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
  "init_action": 3,
  "pending_bank": 5,
  "pending_register": 88,
  "pending_data": 0,
  "first_error_code": 1,
  "first_error_step": 31,
  "first_error_meta_bank": 5,
  "first_error_register": 88,
  "first_error_value": 0,
  "init_active": 1,
  "init_done": 0,
  "init_error": 0,
  "no_scl_high": 0,
  "shadow_correct_phase_ack": "NACK_HIGH",
  "classification": "REAL_DIGITAL_NACK",
  "raw_hex": "0x210058051F010058050302019CA724E4093F3F3F3FE50505005860011E1F0090"
}
```

```text
R2_FALSE_NACK_COUNT=0
R2_REAL_DIGITAL_NACK_COUNT=1
R2_INVALID_ACK_WINDOWS=0
TRACE_TELEMETRY_CORRELATION=PASS
R2_PRIMARY_CLASSIFICATION=REAL_DIGITAL_NACK_AT_CORRECT_ACK_PHASE_CONFIRMED
RAW_ANALOG_MEASUREMENT_AVAILABLE=NO
AXIL_WRITES=0
C2H_TRANSFERS=0
H2C_TRANSFERS=0
```
