# NEXT PREPARE-only handoff

This package does not admit hardware PREPARE.

The same routed DCP and ordered XDC payload were confirmed, but the authorized reserve ended in local reporting code before final timing, DRC, and bitgen. No bitstream exists.

The next action requires a new Owner authorization for one additional offline opening of the exact DCP SHA-256 `F589B7C6151EC2EAB576B358837D0A331B02D69A11DF30F5BCF5910416EEBA64`. Remove the redundant startpoint-name intersection gate before that opening and retain the observed realized timing-path checks (`valid=6`, `data=5`). The continuation may run the missing timing summary, DRC, and one conditional bitgen. It must not rebuild or contact the DUT.

Hardware PREPARE can move to a separate task only after those gates pass and an exact bitstream is released. APPLY, ONESHOT, DMA capture, and PNG remain outside this handoff.
