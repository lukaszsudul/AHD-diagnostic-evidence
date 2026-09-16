"""Bounded SCAN1/ACQ read-only identity and inert-MMIO preflight.

The only writes are SCAN1 ACK_CLEAR and the ACQ SANITY token, both inherited
non-functional sanity operations. There is no ACQ command-register write.
"""
from __future__ import annotations

import argparse
import json

from scan1 import mmio
from scan1.controller import ScannerController

from .characterizer import LiveScanner


ACQ_BASE = 0x12400
ACQ_MAGIC = ACQ_BASE + 0x00
ACQ_VERSION = ACQ_BASE + 0x04
ACQ_CAPABILITIES = ACQ_BASE + 0x08
ACQ_STATUS = ACQ_BASE + 0x10
ACQ_COMMAND_SEQUENCE = ACQ_BASE + 0x14
ACQ_COMPLETED_SEQUENCE = ACQ_BASE + 0x18
ACQ_FUNCTIONAL_WRITE_COUNT = ACQ_BASE + 0x2C
ACQ_UNAUTHORIZED_WRITE_COUNT = ACQ_BASE + 0x30
ACQ_ERROR_COUNTS = ACQ_BASE + 0x34
ACQ_SANITY = ACQ_BASE + 0x7C
ACQ_SANITY_COUNT = ACQ_BASE + 0x80
ACQ_SANITY_TOKEN = 0x434F4D50


def require(ok: bool, reason: str) -> None:
    if not ok:
        raise RuntimeError(reason)


def read_checked(device: mmio.MmioDevice, address: int) -> int:
    value = device.read32(address)
    require(value != 0xFFFFFFFF, f"MMIO_ALL_ONES_READ:{address:#x}")
    return value


def run(device_path: str) -> dict:
    with mmio.MmioDevice(device_path) as device:
        scanner = ScannerController(device)
        scanner_identity = scanner.identity()
        new_identity = LiveScanner(device).identity()
        require(new_identity["telemetry"]["implementation_magic"] == 0x52335231,
                "CONT1R3R1_IMPLEMENTATION_MAGIC_MISMATCH")
        require(new_identity["telemetry"]["implementation_version"] == 0x00010000,
                "CONT1R3R1_IMPLEMENTATION_VERSION_MISMATCH")
        acq_identity = {
            "magic": read_checked(device, ACQ_MAGIC),
            "version": read_checked(device, ACQ_VERSION),
            "capabilities": read_checked(device, ACQ_CAPABILITIES),
        }
        require(acq_identity == {"magic": 0x4E564143, "version": 0x00010000,
                                 "capabilities": 0x000000FF},
                f"ACQ_IDENTITY_MISMATCH:{acq_identity}")
        initial = {
            "status": read_checked(device, ACQ_STATUS),
            "command_sequence": read_checked(device, ACQ_COMMAND_SEQUENCE),
            "completed_sequence": read_checked(device, ACQ_COMPLETED_SEQUENCE),
            "functional_write_count": read_checked(device, ACQ_FUNCTIONAL_WRITE_COUNT),
            "unauthorized_write_count": read_checked(device, ACQ_UNAUTHORIZED_WRITE_COUNT),
            "error_counts": read_checked(device, ACQ_ERROR_COUNTS),
        }
        require(initial["status"] & 1 and not initial["status"] & (2 | 4 | 8 | 64 | 128),
                "ACQ_NOT_IDLE")
        require(initial["status"] & (1 << 4) and initial["status"] & (1 << 23),
                "ACQ_AUTOINIT_OR_I2C_BUS_NOT_READY")
        require(all(initial[key] == 0 for key in (
            "command_sequence", "completed_sequence", "functional_write_count",
            "unauthorized_write_count", "error_counts")),
            "ACQ_ACTION_OR_ERROR_COUNTER_NONZERO")

        scan_rows = scanner.mmio_sanity(16)
        require(len(scan_rows) == 16 and all(row["result"] == "PASS" for row in scan_rows),
                "SCAN1_MMIO_SANITY_NOT_16_OF_16")
        initial_sanity_count = read_checked(device, ACQ_SANITY_COUNT)
        acq_rows = []
        for index in range(16):
            before = (read_checked(device, ACQ_MAGIC),
                      read_checked(device, ACQ_VERSION),
                      read_checked(device, ACQ_STATUS))
            require(before[:2] == (0x4E564143, 0x00010000),
                    f"ACQ_SANITY_IDENTITY_MISMATCH:{index + 1}")
            device.write32(ACQ_SANITY, ACQ_SANITY_TOKEN)
            token = read_checked(device, ACQ_SANITY)
            count = read_checked(device, ACQ_SANITY_COUNT)
            require(token == ACQ_SANITY_TOKEN and count == initial_sanity_count + index + 1,
                    f"ACQ_SANITY_READBACK_MISMATCH:{index + 1}")
            acq_rows.append({"cycle": index + 1, "token": token, "count": count,
                             "result": "PASS"})
        final = {
            "functional_write_count": read_checked(device, ACQ_FUNCTIONAL_WRITE_COUNT),
            "unauthorized_write_count": read_checked(device, ACQ_UNAUTHORIZED_WRITE_COUNT),
            "command_sequence": read_checked(device, ACQ_COMMAND_SEQUENCE),
            "completed_sequence": read_checked(device, ACQ_COMPLETED_SEQUENCE),
            "error_counts": read_checked(device, ACQ_ERROR_COUNTS),
            "scanner_status": read_checked(device, mmio.STATUS),
            "acq_status": read_checked(device, ACQ_STATUS),
        }
        require(all(final[key] == 0 for key in (
            "functional_write_count", "unauthorized_write_count", "command_sequence",
            "completed_sequence", "error_counts")), "POST_SANITY_FUNCTIONAL_ACTION_OR_ERROR")
        require(final["scanner_status"] & mmio.STATUS_IDLE and
                not final["scanner_status"] & (mmio.STATUS_BUSY | mmio.STATUS_DONE |
                                             mmio.STATUS_ERROR | mmio.STATUS_BANK_LOCKOUT),
                "POST_SANITY_SCANNER_NOT_IDLE")
        require(final["acq_status"] & 1 and final["acq_status"] & (1 << 23) and
                not final["acq_status"] & (2 | 4 | 8 | 64 | 128),
                "POST_SANITY_ACQ_OR_I2C_NOT_IDLE")
        return {"result": "PASS", "scanner_identity": scanner_identity,
                "telemetry_identity": new_identity["telemetry"],
                "acq_identity": acq_identity, "initial_counters": initial,
                "scan1_mmio_sanity": scan_rows, "acq_mmio_sanity": acq_rows,
                "final_counters": final, "experimental_functional_writes": 0}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--self-test", action="store_true")
    mode.add_argument("--run", action="store_true")
    parser.add_argument("--device", default="/dev/xdma0_user")
    args = parser.parse_args(argv)
    if args.self_test:
        require(ACQ_SANITY == 0x1247C and ACQ_SANITY_COUNT == 0x12480 and
                ACQ_SANITY_TOKEN == 0x434F4D50 and mmio.CONTROL_ACK_CLEAR == 2,
                "FROZEN_INERT_MMIO_CONTRACT_DRIFT")
        print("PASS CONT1R3R1_RUNTIME_PREFLIGHT_SELF_TEST")
        return 0
    print(json.dumps(run(args.device), sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
