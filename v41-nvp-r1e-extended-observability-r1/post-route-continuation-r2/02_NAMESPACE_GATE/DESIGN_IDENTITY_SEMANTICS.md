# Namespace-correct design identity semantics

`CHECKPOINT_CURRENT_DESIGN_NAME` is the Vivado in-memory checkpoint/design
object name. `RTL_TOP_FROM_BUILD_MANIFEST` is the HDL elaboration top recorded
by the frozen build manifest. They are recorded independently and are not
compared for equality.

The primary identity is the exact routed-DCP SHA-256 chained to the frozen
source commit, source tree, build manifest, Vivado version, part, routed state,
top-level port signature, and R1e structural signature.

DESIGN_NAME_EQUALITY_REQUIRED=NO
CURRENT_DESIGN_TO_RTL_TOP_EQUALITY_COMPARISON_COUNT=0

