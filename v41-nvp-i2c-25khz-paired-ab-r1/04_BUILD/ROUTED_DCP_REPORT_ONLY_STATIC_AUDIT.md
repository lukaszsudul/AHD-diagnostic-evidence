# Routed-DCP Report-Only Supplement — Static Audit

Status: independent post-build gate passed. Attempt 1 opened the exact routed
checkpoint read-only, then stopped before reports because `current_design`
is a checkpoint session label rather than the HDL top. The failed output was
preserved without overwrite. The task-local script was adapted to validate
the read-only design `TOP` property while retaining `current_design` as
evidence; no design, source, checkpoint, build, or power assumption changed.
Attempt 2 likewise stopped before reports because the non-project session did
not expose `IS_ROUTED`. Attempt 3 used the exact report-only route-status
database, proved zero routing errors, and completed successfully.

## Identity

```text
TCL=C:\FPGA\V41_NVP_I2C_25KHZ_PAIRED_AB_R1\scripts\run_routed_dcp_report_only_after_pass.tcl
TCL_SHA256_PRE_ATTEMPT_1=31DF46A1625439A83C04DA6AEBAF5F00B67797E243832841DDD285383A048F87
TCL_SHA256_ATTEMPT_2=31F99A15D4C9568EAA23CAFCDF138E9A8CA24EDCBC03F119483575B2A7B26E5E
TCL_SHA256_ROUTE_STATUS_ADAPTED=323C59CE0A99551628384919D4AD7E8EED96F9811AF2E6687084D95B44D3F764

WRAPPER=C:\FPGA\V41_NVP_I2C_25KHZ_PAIRED_AB_R1\scripts\run_routed_dcp_report_only_after_pass.cmd
WRAPPER_SHA256=5A96DFE93FDE2189B0F804EEA4A98F3D0F4D71F9185EB27CEF4817DE04C6C41E

EXPECTED_SOURCE_COMMIT=f007dc172d43d30b02729755e60382f8ce3dbff4
EXPECTED_DESIGN=ahd_capture_top_xdma
EXPECTED_PART=xc7a35tcsg325-2
POST_BUILD_GATE=PASS
ATTEMPT_1=FAIL_CLOSED_CURRENT_DESIGN_SESSION_LABEL
ATTEMPT_1_REPORT_POWER_INVOCATIONS=0
ATTEMPT_1_DESIGN_CHANGES=0
ATTEMPT_1_PRESERVED_DIRECTORY=ROUTED_DCP_REPORT_ONLY_ATTEMPT_01_FAILED_CURRENT_DESIGN_LABEL
ADAPTATION=CHECK_TOP_PROPERTY_PRESERVE_CURRENT_DESIGN_LABEL
ATTEMPT_2=FAIL_CLOSED_EMPTY_NONPROJECT_IS_ROUTED_PROPERTY
ATTEMPT_2_REPORT_POWER_INVOCATIONS=0
ATTEMPT_2_DESIGN_CHANGES=0
ATTEMPT_2_PRESERVED_DIRECTORY=ROUTED_DCP_REPORT_ONLY_ATTEMPT_02_FAILED_EMPTY_IS_ROUTED_PROPERTY
ROUTED_PROOF_ADAPTATION=REPORT_ROUTE_STATUS_ROUTING_ERRORS_ZERO
ATTEMPT_3=PASS
ATTEMPT_3_REPORT_ONLY_RESULT_SHA256=273AEC03FCD6140D1577260DA247C920CB19B756EA78D9828D298B8F5F57B272
ROUTE_STATUS_ROUTING_ERRORS=0
FINAL_REPORT_ONLY_SUPPLEMENT=PASS
```

The wrapper refuses to start unless the exact routed DCP exists and the
independent gate file contains both `POST_BUILD_GATE=PASS` and the exact
source commit. It also requires a fresh report output directory, so a failed
report-only attempt cannot be silently overwritten or retried.

## Installed Vivado 2025.2 help basis

The commands and options were checked against already-preserved help from
Vivado 2025.2 build 6299465:

```text
report_power.help.txt=14503DBBA058C03C9C710DC763208935AACAF1F4F76FF5AB117E765DEC393C61
report_io.help.txt=05D288B1F3379D90279C03014E0B332803E3B8C50F3E9897952BCAF4F5745E8D
report_property.help.txt=AFD3CA0517F7363F9F3AAD900F590FD464BC8005DF6DDA8C9B596E19E07A4968
report_utilization.help.txt=9E8E9CAB11F727248ECDAFC3F3C770F427E3451B6A0B12CB969D4518F5C9ED8E
all_fanin.help.txt=73BD4E0B3208916AC802D0857A6513C778D4638B3704A456CB576330909184A7
all_fanout.help.txt=9A392F05E155688C260807CED16353A86DFD24126A6A5EBEED2D4AA762B4B486
get_cells.help.txt=57EA7D965FD978AEF4813B01400BFA5AD6FA55F26D5C605A2FD2A4E1DD0B40A2
get_clocks.help.txt=EC67D7E5BF571FD7FC2261095CA47BF37F92655560471EA296CFCB340EE511A9
list_property.help.txt=A2C846AA06B179DE43C319DD0D331C2476B611AFD88F0801494CA99B5CB768BB
open_checkpoint.help.txt=CCD5AD6FA15A8175D68E67D230687D975805BFACFE53E74573A1C2EA8BE081C2
close_design.help.txt=6943BEDE259FB9B587C8FB708EBBFA9F8AADE5B3CA42FC0AA4F2BA9DF2CA1C6D
```

Confirmed report options are limited to documented 2025.2 forms:

- `report_power -file`
- `report_power -hier all -hierarchical_depth 0 -l 0 -verbose -file`
- `report_power -advisory -file`
- `report_power -format xml -file`
- `report_io -file` and `report_io -format xml -file`
- `report_property -all`, `-file`, and `-append`
- `report_utilization -hierarchical -hierarchical_depth 20 -file`
- `all_fanin` with `-flat`, `-startpoints_only`, `-only_cells`, and
  `-trace_arcs all`
- `all_fanout` with `-flat`, `-endpoints_only`, and `-trace_arcs all`
- `get_clocks -of_objects`

No undocumented `-to` or `-from` spelling is used with `all_fanin` or
`all_fanout`; their object arguments use the documented positional form.

## Read-only boundary

Static command scan result:

```text
OPEN_CHECKPOINT_COMMANDS=1
CLOSE_DESIGN_COMMANDS=1
REPORT_POWER_COMMANDS=4
REPORT_IO_COMMANDS=2
ALL_FANIN_COMMANDS=3
ALL_FANOUT_COMMANDS=1
FORBIDDEN_DESIGN_OR_HARDWARE_COMMAND_HITS=0
```

The forbidden scan covers synthesis, optimization, placement, routing,
checkpoint/bitstream save, project creation, property/activity/operating-
condition changes, SAIF loading, and all Hardware Manager commands. The only
filesystem writes are report/evidence text, XML, log, and journal files in the
fresh task-local output directory.

## Evidence behavior

The report session must prove the exact routed design and part, then emits:

- standard, full-hierarchy verbose, advisory, and XML power reports without
  changing activity or operating assumptions;
- text and XML I/O reports, with explicit presence checks for `nvp_scl` and
  `nvp_sda`;
- exact `NVP_AUTOINIT` and `u_sequence` hierarchy/reference identities;
- all hierarchy boundary pins and their direct nets, aggregate external fan-in
  startpoints, and aggregate functional fan-out endpoints;
- every sequential NVP-autoinit clock pin and the unique 16.000-ns clock;
- the synthesized `tick_cnt_reg[10:0]` set, `tick_reg`, every terminal-decode
  fan-in cell/startpoint, cell properties including LUT `INIT`, and all cone
  pin/net connectivity.

VHDL generics are not assumed to survive as direct routed-cell properties.
If Vivado exposes an `I2C_HZ` or `DIVIDER` property, its value must agree with
25,000 or 1,250 respectively or the report session fails. If no such property
is retained, the report states that limitation explicitly and preserves the
exact source-commit-to-DCP provenance plus the synthesized 11-bit tick counter
and complete terminal-decode cone. It does not invent a direct generic
property.

```text
FULL_BUILDS_ADDED_BY_SUPPLEMENT=0
IMPLEMENTATION_COMMANDS=0
DESIGN_PROPERTY_CHANGES=0
OPERATING_CONDITION_CHANGES=0
SWITCHING_ACTIVITY_CHANGES=0
CHECKPOINT_SAVES=0
BITSTREAM_COMMANDS=0
HARDWARE_ACTIONS=0
```
