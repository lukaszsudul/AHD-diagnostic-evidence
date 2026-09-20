# NEXT PREPARE-only handoff

This package admits the private bitstream only to a separately authorized hardware PREPARE test.

Before hardware work, a new task must establish current DUT containment and exact activation authority. It must independently verify the private bitstream identity: size 2192144 bytes and SHA-256 `34DFC48E9CCEDD9E4F608624EE51D1D79767E8E74035393576B69C21C07E8CB8`, together with source commit `b2f80cf4fda1775ab34804a246cb7be61e0ecd62` and DCP SHA-256 `F589B7C6151EC2EAB576B358837D0A331B02D69A11DF30F5BCF5910416EEBA64`.

The next authorized action is controlled DUT recovery/activation followed by hardware testing of PREPARE only. This handoff does not admit APPLY, camera configuration, ONESHOT, DMA capture, frame reconstruction, or PNG. Hardware qualification, camera admission, capture admission, and product qualification remain unclaimed.
