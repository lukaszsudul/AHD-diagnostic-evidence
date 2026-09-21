# Next action

The exact new volatile image remains active, but the last measured loader state is `CAMP_RECOVERED` with terminal 5 and a valid sticky first-failure record. The qualified driver is unloaded and both task locks are released.

Do not issue another PREPARE or APPLY from this state. Any recovery/reactivation, new command, scan, PN B operation, DMA, or capture requires a separate Owner-authorized task with fresh identity and ownership checks.

The retained record localizes the first loader mismatch to APPLY_A PC 310, a confirmed Bank7 read of register `0xF0` that returned `0xFF` instead of the pinned expected value `0x34`. It does not prove a physical cause and is not a reproduced REGADDR_NACK.

```text
FIRST_FAILURE_RECORD=VALID_COHERENT
HISTORICAL_NACK_REPRODUCTION=NOT_REPRODUCED_AS_REGADDR_NACK
CH3_SYNC=NOT_TESTED
ROUTE_CONFIG_VERIFIED=NOT_RUN
PHYSICAL_NACK_ROOT_CAUSE=NOT_PROVEN
CAPTURE_ADMISSION=NOT_GRANTED
```
