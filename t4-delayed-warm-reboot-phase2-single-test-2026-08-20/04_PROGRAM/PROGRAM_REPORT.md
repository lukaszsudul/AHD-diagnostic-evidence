# Single Phase-2 programming report

Exactly one `program_hw_devices` invocation occurred using the exact sealed Phase-2 image. Vivado reported `End of startup status: HIGH`, establishing EOS high and successful completion of the programming command. The script then attempted to read unsupported tool property `REGISTER.IR.BIT4_EOS`; this reporting-only property mismatch caused its final Tcl result to say FAIL after programming had already completed. There was no retry.

A new read-only Hardware Manager session subsequently established the exact target and fresh DONE=1. This satisfies the hardware state gate without another programming invocation.

    PROGRAM_START_UTC=2026-08-20T17:21:23Z
    PROGRAM_END_UTC=2026-08-20T17:21:29Z_APPROX_LOG_EXIT
    PROGRAM_INVOCATIONS=1
    PROGRAM_EOS=HIGH_VENDOR_STARTUP_STATUS
    PROGRAM_DONE=1_FRESH_READ_ONLY_SESSION
    PROGRAM_RETRIES=0
