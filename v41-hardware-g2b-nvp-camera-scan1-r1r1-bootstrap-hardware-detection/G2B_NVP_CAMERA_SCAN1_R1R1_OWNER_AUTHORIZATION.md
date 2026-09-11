
# Owner authorization

- Task: `G2B-NVP-CAMERA-SCAN1-R1R1`
- Project state: `8 — OWNER_ATTESTED_NOT_REVERIFIED`
- Authorized source reuse: commit `c7e16fa3da26545cef960a6c75427a3614c4b655`, tree `56526e17154f8e06f3eb4b95233934c18b6ee06e`
- Human Gate A: exact `SCAN1_BASELINE_READY`, receipt SHA-256 `66C41CBABD981C6E4EBF5F561CA4B9D61961BAD69B475FD2601B0A07C2C3E865`
- Human Gate B: exact `SCAN1_CAMERA_CONNECTED`, no suffix; connector label recorded as `UNKNOWN`, receipt SHA-256 `F685D8609BE8F24C91186E6F1FD1325D9F8ECE408495541DA3277B0736CAEB29`
- Human Gate C: exact `SCAN1_RETURN_CONTROL_READY`, receipt SHA-256 `6431F6B75B99127FD127D7E5B77B82279C399F6C8BB2EC522EFFBF11179DC85F`

The replies authorized only the bounded physical transitions and scan series. They did not authorize functional NVP writes, source changes, rebuilds, route/BGDCOL changes, ACQ1, Flash programming, retry programming, or an additional reboot.
