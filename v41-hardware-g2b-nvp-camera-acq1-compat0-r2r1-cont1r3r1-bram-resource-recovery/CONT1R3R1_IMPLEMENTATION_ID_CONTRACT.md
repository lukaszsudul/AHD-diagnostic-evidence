# Read-only implementation identity extension

The CONT1R3 payload magic/version/capabilities remain `0x4E565433` / `0x00010000` / `0x0000007F`. Payload schema SHA-256 remains `438D630943B0D3A2BFCB2C23B9FB060FD0C347C16F331D008997DBB3B8B22F95`; SCAN1 manifest digest remains `2773DFA86ABEC87EF1E5BFB6F093D83BD8FCB4382B51B1792F3B7E8E302A1B2B`. Their meanings were not redefined by physical storage recovery.

The separate extension requires read-only `0x137F0 = 0x52335231` and `0x137F4 = 0x00010000`. Contract JSON SHA-256: `81A3FC68BABE70273A531DDB2F93B89D5EF5C494E7D21FA68AF0D534836F7363`. The host rejects absent, old or wrong implementation words before collection; `runtime-bundle/test_implementation_identity.py` exercised acceptance and three negative cases. These addresses do not collide with the 870 payload words.

Source commit/tree are linked externally through the final DCP/bitstream and deployment manifests, not embedded recursively in the source. No signed-off image link or hardware runtime identity is claimed until those gates complete.
