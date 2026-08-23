# Expanded evidence note

The two immutable DCP binaries are preserved inside the sealed LFS evidence
ZIP and at their original task-local source paths. To avoid a redundant
non-LFS 90-MiB duplication in the expanded Git tree, the expanded R2 directory
contains their identity records and complete reports rather than second binary
copies.

SYNTH_DCP_SHA256=1B86629EF73506533022488C28F41B56027E9FA1D6CFCB855381B79D6F78C001

ROUTED_DCP_SHA256=1CA3F857F2E3655FD06E8BF283B6BEC8826568402160EE004D7B8CD4D110C0B1

SEALED_PACKAGE=V41_NVP_R1E_POST_ROUTE_CONTINUATION_R2_EVIDENCE.zip
