# T20 core MMIO test

PASS. Reads of MAGIC/VERSION, CLEAR, and following STATUS/STATE/ERROR reads completed. CLEAR executed once, produced no diagnostic downstream response, and did not block the next read. PREPARE, START, HOST_CAPTURE_RESPONSE, RESTORE, and ABORT writes also produced no downstream response.
