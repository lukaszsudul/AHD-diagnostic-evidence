# Diagnostic MMIO protocol contract

Accepted writes execute exactly one validated side effect and create no downstream response. Accepted reads latch one word, assert registered response-valid, and hold valid/data until ready. A pending response blocks new requests unless it is consumed in the same cycle. DIAG_VERSION is `0x00010002`; capability bit 11 is set; the aggregate capability word is `0x00000BFF`.
