# R2 remote evidence transfer verification

The approved Windows host copied the complete R2 measurement and post-reboot
host-health trees from `VCDE-DUT-1` (`10.132.1.111`). The remote manifest was
generated before transfer and contains 26 files.

```text
REMOTE_MANIFEST_ENTRIES=26
LOCAL_FILES_CHECKED=26
REMOTE_TRANSFER_MISMATCHES=0
REMOTE_TRANSFER_VERIFICATION=PASS
```

The decisive raw objects independently match the hashes emitted by the
identity-gated read-only decoder:

```text
TRACE_RAW_SHA256=33A19868C9B69BD8139020ACD0ACD046B436AE1B625E98CCC24FF3E35A6D8823
FSM_TICK_CONTEXT_RAW_SHA256=A635CC4D961CF04887EC9AFE64D5A06844AE0D6EAAE4153CDED4EEA283EDFAA3
SHADOW_ACK_EVENTS_RAW_SHA256=71B6F89FC15A75AD45BF9DD4F82DE05A6E899B18DE1E245BE4D7A2F400743699
```

The authoritative remote manifest is retained as
`REMOTE/R2_REMOTE_FILES_SHA256.txt`.

