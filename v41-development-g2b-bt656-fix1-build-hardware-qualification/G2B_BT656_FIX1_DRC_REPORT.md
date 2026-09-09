# DRC report disposition

Result: **NOT_REACHED** for the governed gate. The raw fully-routed DRC report
contains 14 warnings (PDCN-1569 x1, REQP-1839 x12, RTSTAT-10 x1) and no listed
Error or Critical Warning. However, the scripted DRC gate evaluation did not
run after the earlier bus-skew export failure, so this evidence does not elevate
the DRC gate to PASS.
