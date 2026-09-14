# MODE1 minimum initial-EQ audit

## Result

`MODE1_INITIAL_EQ_AUTHORITY_INCOMPLETE`

The frozen SCAN0 path isolates nine EQ semantic entries: three bank selections,
five functional writes and one vendor software-state assignment.  The first eight
are retained in the semantic minimum; the software-state assignment is excluded
and replaced conceptually by executor session state.  No adaptive tracking loop,
CH2-CH4 coefficient, ACP/coax action or multi-format branch is included.

| MODE1 op | Target/action | Value | First-image rationale | Authority and recovery |
|---:|---|---:|---|---|
| 162 | select Bank 5 | `0x05` | enter CH1 format bank | public bank-select semantics; restore captured entry bank |
| 163 | Bank 5 / `0x59` | `0x11` | reference initialization invokes it before image acquisition; indispensability is not independently proven | reference semantics only; `PROHIBITED_UNRESOLVED` |
| 164 | select Bank 5 | `0x05` | retain CH1 format bank | public bank-select semantics; restore captured entry bank |
| 165 | Bank 5 / `0xC0` | `0x17` | reference initial-EQ coefficient/setup | private-register compatibility incomplete; `PROHIBITED_UNRESOLVED` |
| 166 | Bank 5 / `0xC1` | `0x13` | reference initial-EQ coefficient/setup | private-register compatibility incomplete; `PROHIBITED_UNRESOLVED` |
| 167 | Bank 5 / `0xC8` | `0x04` | reference initial-EQ coefficient/setup | private-register compatibility incomplete; `PROHIBITED_UNRESOLVED` |
| 168 | select Bank 10 | `0x0A` | enter CH1 EQ control bank | public bank-select semantics; restore captured entry bank |
| 169 | Bank 10 / `0x74` | `0x02` | reference initial-EQ CH1 control | private-register compatibility incomplete; `PROHIBITED_UNRESOLVED` |
| 170 | software `ch_stage[CH1]` | `0` | vendor internal state only | excluded; executor state must be session-scoped and unpublished |

All five functional writes require controlled NVP6134C compatibility evidence.
The public PDF marks Banks 5-10 as private/not user-programmable and supplies no
safe restore rule for these bytes.  Consequently the subset is semantically exact
but not safe to execute, and no candidate, build, bitstream or hardware prompt is
permitted.

