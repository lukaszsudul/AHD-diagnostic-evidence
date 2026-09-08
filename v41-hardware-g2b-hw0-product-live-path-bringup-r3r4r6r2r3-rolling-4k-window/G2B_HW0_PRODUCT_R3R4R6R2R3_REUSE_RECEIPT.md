# Tool reuse receipt

The R3R4R6R2R2 controller, ABI parser, record validator, stream analysis, frame
tool, connection helper, and publication architecture were copied into the fresh
root. Changes were limited to task identity, fresh paths, rolling-AIO metadata,
the 1024-outstanding refill controller, and bounded guard-cleanup fields. Existing
bitstream, driver, and ABI hashes were accepted and were not recomputed.

Accepted baseline native source SHA-256: `7C13B835DCC037EF529BC915EF045B661BA4166AF6F5B002ED63E7787890A0FB`

New rolling native source SHA-256: `3373FCCEE2DB3FAB000A7BE3832A52D755BA2DBD055F295F498344949AB68FC9`
