
# R3R4R5 DUT Lock Receipt

- Controller lock: `ACQUIRED`, then `RELEASED LAST`
- Linux lock: `ACQUIRED`, then `RELEASED FIRST`
- Lock boot ID: `614295f4-c62b-4430-ae67-06013bea7084`
- DUT exclusivity: `PASS`
- Parallel HDMI hardware activity: `NONE`
- Helper invocations: `31`
- Every DUT connection used helper SHA-256 `8988139C2F2CFFC4F5F04A6BB1A61314AAF4A5779B2021709BF35A9A625F5F84`: `YES`
- Credential remnants after invocations: `0`

One preliminary task-local process-name detector matched the unrelated CUPS
service because of an unbounded `ups` substring. Read-only resolution proved
no competing hardware process; the detector was narrowed to a word-bounded UPS
pattern before any hardware mutation. Both receipts are retained locally.
