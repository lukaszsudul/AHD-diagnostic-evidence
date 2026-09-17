# Campaign hard-stop receipt

The first 25 campaign scans and the separate control scan were durably
persisted. At the next scan, the accepted characterizer raised
`SCANNER_HARD_STOP:0x00000c18` without persisting or acknowledging an
incomplete scan. There was no retry or resumption.

Read-only, BDF-verified post-stop MMIO reported:

| Register/field | Value |
| --- | --- |
| SCAN1 status | `0x00000C18` (ERROR set, BUSY clear) |
| generation register | `0x0000001A` (26; also last complete generation) |
| valid entries | `0x00000025` (37 partial entries) |
| failed/retried entries | `0` / `0` in partial scan |
| first error index | `0x00000024` (36) |
| first error detail | `0x0005FF0A` |
| scan flags | `0x00330004` (51 transactions; restore flag set) |
| entry/exit bank | `0x00000100` / `0x00000100` |
| ACQ status/errors/functional writes | `0x00800011` / `0` / `0` |

The frozen detail packing is bank, register and error nibble. It decodes to
Bank 5, `0xFF` bank-select register, code `0xA` =
`INTERNAL_PROTOCOL_ERROR`. The snapshot did not reach 82/82 or complete
publication, so it is not a campaign scan. The code identifies the failure
class and point, **not** the underlying electrical, RTL or software cause.
No camera-format conclusion is supported.

The task-private, controller-held archive of the completed raw records is
108,145 bytes, SHA-256
`96080348A26E00ECF8B4DBA58F6E691EBAD48F2D8B0C3DDC2EC474A316E6A0CB`.
It is not published. Its public manifest records 26 complete raw-record
hashes. One qualified `ACK_CLEAR` after the diagnostic read returned SCAN1
to `0x00000011` idle without starting another scan.
