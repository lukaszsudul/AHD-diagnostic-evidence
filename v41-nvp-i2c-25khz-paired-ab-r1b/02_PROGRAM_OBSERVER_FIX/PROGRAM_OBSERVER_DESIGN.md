# Corrected programming observer

The R1 defect occurred after the sole programming operation returned. R1b
removes only that task-local observer defect:

- the Tcl lists the device properties but never queries BIT4 EOS;
- pre- and post-program state use the proven BIT5 DONE property;
- the Tcl contains exactly one programming command and no retry loop;
- the supervisor independently hashes the bit and scripts;
- the supervisor recognizes EOS only from the exact vendor startup-HIGH line;
- the supervisor requires the consumed, startup-HIGH, return, DONE, fresh-DONE,
  Tcl-pass, and exit-zero records in strict order;
- every captured line receives an absolute QPC/Stopwatch timestamp;
- the wait begins from the later return/fresh-DONE marker in that same epoch.

The installed supported wrapper is
`C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat`; the prompt's nested wrapper
path is absent on this workstation. The raw unwrapped executable is forbidden
and is not referenced by the R1b supervisor.

