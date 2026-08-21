# Per-bank VCCO availability audit

The text, XML, RPX string inventory, `report_io`, I/O-bank objects, ports,
I/O primitives, and associated nets were searched after `report_power`.
`report_io` identifies VCCO_14 supply pins and the ports assigned to bank 14,
but it does not report bank power/current. No documented, unit-bearing,
mutually exclusive power/current property is present on the bank, port, I/O
cell, or net objects. Bank 16 has no used design ports in either image.

The only modeled 3.3-V rail row is aggregate `Vcco33`; it cannot be assigned
to bank 14 or bank 16.

```text
VCCO_14_DIRECT_BREAKDOWN_AVAILABLE=NO
VCCO_14_BREAKDOWN_METHOD=NOT_AVAILABLE_FROM_UNMODIFIED_DCP
VCCO_16_DIRECT_BREAKDOWN_AVAILABLE=NO
VCCO_16_BREAKDOWN_METHOD=NOT_AVAILABLE_FROM_UNMODIFIED_DCP
AGGREGATE_VCCO33_IS_PER_BANK=NO
```