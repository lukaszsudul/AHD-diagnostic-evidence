# G2B-HW0-PRODUCT-R3 preload inventory

Technical T0 result: **PASS**

The overall task failed at the independent artifact-boundary gate and stopped
before module load.

## Host and JTAG

| Field | Value |
|---|---|
| hostname / IP | `VCDE-DUT-1` / `10.132.1.111` |
| machine ID | `0e90f50d9465492b80258da5658446f8` |
| kernel / arch | `7.0.0-29-generic` / `x86_64` |
| boot ID | `52b0bf13-e9d1-4558-ae13-d08f4ecc8dac` |
| taint | `0` |
| JTAG target/device count | `1 / 1` |
| FPGA / index / IDCODE | `xc7a35t / 0 / 0362D093` |
| DONE | `1`, five consecutive R3-local samples |
| programming operations | `0` |

The controlling JTAG evidence is the R3-local rerun. The earlier R2-source
reference is preserved but superseded.

## PCIe

| Field | Value |
|---|---|
| exact endpoint count / BDF | `1 / 0000:01:00.0` |
| vendor/device / subsystem | `10ee:7011 / 10ee:0007` |
| class / modalias | `058000` / `pci:v000010EEd00007011sv000010EEsd00000007bc05sc80i00` |
| upstream | `0000:00:01.1` |
| endpoint LnkCap / LnkSta | `5.0 GT/s x1 / 5.0 GT/s x1` |
| upstream LnkSta | `5.0 GT/s x1` |
| driver / override | none / `(null)` = unset |
| power / IOMMU group | `D0 / 13` |
| BAR0 / BAR1 | `0xf6f00000..0xf6f1ffff` / `0xf6f20000..0xf6f2ffff` |

The raw override bytes were `286e756c6c290a`; no override write occurred.

## Fresh runtime and health

- `xdma_ahd_pcie`: absent
- platform `xdma`: absent
- `/dev/xdma*`: 0
- `/sys/class/xdma`: absent
- Secure Boot: disabled
- lockdown: none
- AER sysfs endpoint/upstream counters: NOT_EXPOSED
- endpoint/root `DevSta`, stable link, kernel log: clean
- MMIO, DMA, driver, config-write, rescan, reset, programming counts: all 0

Unavailable AER counters are not represented as zero.

