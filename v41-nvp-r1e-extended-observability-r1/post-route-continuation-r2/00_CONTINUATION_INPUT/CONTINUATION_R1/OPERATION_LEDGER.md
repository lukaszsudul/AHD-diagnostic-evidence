# R1e post-route continuation operation ledger

TASK=V41_NVP_R1E_POST_ROUTE_CONTINUATION_AND_PAIRED_AB_R1

OWNER_STANDING_AUTHORIZATION=GRANTED

FULL_BUILDS_THIS_TASK=0
SYNTHESIS_RUNS_THIS_TASK=0
PLACE_RUNS_THIS_TASK=0
ROUTE_RUNS_THIS_TASK=0
POST_ROUTE_CONTINUATION_SESSIONS=1
OPEN_CHECKPOINT_EXECUTIONS=1
WRITE_BITSTREAM_ATTEMPTS=0
FPGA_PROGRAMS=0
WARM_REBOOTS=0
DRIVER_LOADS=0
PROGRAM_RETRIES=0
SOURCE_CHANGES=0
FORMAL_REPOSITORY_MUTATIONS=0

The verbatim continuation prompt was preserved and hashed before any Vivado continuation command.

SHARED_BUILD_LOCK_ACQUISITIONS=1
SHARED_BUILD_LOCK_RELEASES=1
SHARED_BUILD_LOCK_RELEASED=YES

CONTINUATION_PROCESS_EXIT_CODE=1
CONTINUATION_BLOCKER=BLOCKED_SINGLE_POST_ROUTE_CONTINUATION_TOP_IDENTITY_HARNESS_MISMATCH

The exact routed DCP opened successfully in Vivado 2025.2 and loaded part
`xc7a35tcsg325-2`. The task-local check then compared the checkpoint design
object name (`checkpoint_PHASE3_routed`) with the RTL top identifier and
stopped. This occurred before the object-cardinality query, reports, or
`write_bitstream`. The one-session/no-rerun rule was applied. No hardware
operation followed.
