# Host Source Delta

R3R2 capture controller SHA-256: '7AC6B0028DBC0B0BC89E464897994531CDB3E188D7C300170B0577C57DF33D88'.

R3R2 scan controller SHA-256: '1FBB936167F23CC161DB7CB9C2CE54E11FDCC5FF197F7D6015A15DAD0FB52163'.

The host now accepts 'ACTIVE_FRAME_AND_TRANSPORT_INTEGRITY=PASS' plus 'BOUNDED_ROUTE_SPECIFIC_VBI_TAIL=PASS'; it stores the legacy exact-tail result as a route fingerprint and stops only for actual integrity or out-of-range VBI failures. The hardware deployment manifest accidentally omitted unchanged transitive module 'abi_v1.py'; this operational packaging defect, not the validator logic, stopped the one authorized scan.
