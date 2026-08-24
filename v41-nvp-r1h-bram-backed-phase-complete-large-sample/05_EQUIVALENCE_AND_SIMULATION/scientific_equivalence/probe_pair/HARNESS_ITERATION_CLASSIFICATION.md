# Probe-pair harness iteration classification

These are verification-harness iterations only. No production or shared test
source was changed by this lane.

| Run | Result | Classification | Gate use | Log SHA-256 |
|---|---|---|---|---|
| `run_01` | compile not started | PowerShell helper used the reserved automatic `$Args` name and passed an empty argument vector | rejected | `6CF4938E2D63B7860C1390A3C47AC7CD2A50768AA3F0161C21D693A94715E3E6` |
| `run_02` | compile not started | same harness-runner defect, preserved before correction | rejected | `6CF4938E2D63B7860C1390A3C47AC7CD2A50768AA3F0161C21D693A94715E3E6` |
| `run_03` | harness compile failed | nested macro-as-argument form unsupported by the exact xvlog frontend | rejected | `59AF328D8904F09D0E438D736F6AF61DBA223400947EE186E47C8436E6D07A0F` |
| `run_04` | PASS | fixed X-macro harness; 83 common outputs and internal event stream compared | authoritative | `D8440A7A5A5F50764F04D7F21246069B1005F4BDCAC5C9DB783C3FCE7E178BAF` |

The first three logs are retained but excluded from every acceptance claim.
They reached neither a design simulation nor any synthesis/implementation
command. The successful harness source SHA-256 is
`8A6906361D5306B705549A43D24334E9E10B4D287212E298CE3E09274093106A`.
