# R1g offline host-tool gate

## Result

```text
EXECUTION_CLASS=OFFLINE_ONLY
INHERITED_R1F_HOST_TOOL_FIXTURES=PASS_24_OF_24
R1G_ADDITIONAL_HOST_FIXTURES=PASS_3_OF_3
HOST_TOOL_HASH_GATE=PASS
R1F_REGISTER_MAP=UNCHANGED
R1F_RECORD_VERSION=1
ACTIVE_HARDWARE_BINDING=PENDING_R1G_COMMIT_AND_BUILD
LIVE_SSH_JTAG_VIVADO_MMIO_PROGRAM_REBOOT_DRIVER_ACTIONS=0
```

The 24 accepted R1f reader, decoder, probe-model, and frozen-statistics tests
were replayed from the exact R1f worktree with Vivado's bundled Python 3.13.
All passed. The exact reader and statistics implementations remain byte
identical:

```text
read_nvp_r1f.py=
  5BDE0B94E8817DA9EC92FBE8BF7149E93C631E348FCD0B395D4EA539EC2A734C

r1f_statistics.py=
  C0188FF2AB7AC03034DAA7F412F447E3DBC21C15FB5458B126C0A96FEB771CCD
```

Fixture evidence:

```text
R1G_INHERITED_R1F_HOST_FIXTURES_LOG_SHA256=
    625EBF46932BAA5A44DBC3862C9D6674643E3591A3EF54577E15330FA3517AAE

R1G_ADDITIONAL_HOST_FIXTURES_LOG_SHA256=
    299395D589D892F7B9564167398C9F82DAFBFB3B5812182E4C1118AA3D17B00B

R1G_CAMPAIGN_STATIC_FIXTURE_LOG_SHA256=
    21DB444A97A448BC6C65DAEB029E4AE35817908CEFE0E187950D0AC022C76621
```

Three R1g additions passed offline:

1. runtime source-commit and `BUILD_FLAGS=0x00000002` contract;
2. unchanged R1f magic/version/capability/record/probe contract;
3. exact-formal deterministic zero across every aligned word from `0x20A0`
   through `0x35FC`, including a nonzero terminal-word rejection.

Two initial additional-fixture invocations failed before executing a test due
to command/import-path setup. Their logs are preserved. The corrected third
invocation ran and passed all three fixtures; no production tool changed in
response.

The task-local runtime-provenance supplement is read-only. It opens only
`/dev/xdma0_user` with `O_RDONLY|O_CLOEXEC`, uses `pread`, and implements no
write, DMA, PCIe, driver, programming, or reboot action.

## Inherited R1f manifest observation

The published R1f campaign-tooling manifest lists the non-live pending binding
template as 1,250 bytes/SHA
`897501415FB282DC9927564609540F3E608F8571642627052C7C305EE6D39F71`,
while the file present at evidence commit
`1130c4686a7aaedcf2609dd4a5739d7a7eb73fff` is 1,259 bytes/SHA
`4F61587B93B34ACE7DE605D5EEBEA98A9F0559E789AF5107EA027A3B35722C29`.
R1g does not treat either pending R1f template as an active binding. It derives
a new fail-closed R1g template and hash-gates all executable/read-only leaf
tools directly. This inherited non-live-template discrepancy does not weaken
an R1g live gate.
