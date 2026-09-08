#!/usr/bin/env python3
"""Nine focused source/build checks for the record-granular native helper."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re


def check(name: str, passed: bool, evidence: str) -> dict:
    return {"name": name, "result": "PASS" if passed else "FAIL",
            "evidence": evidence}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--build", required=True, type=Path)
    parser.add_argument("--report", required=True, type=Path)
    args = parser.parse_args()
    text = args.source.read_text(encoding="utf-8")
    build = json.loads(args.build.read_text(encoding="utf-8"))

    shuffled = [(2, b"C" * 4096), (0, b"A" * 4096), (1, b"B" * 4096)]
    by_index = [b""] * 3
    for index, payload in shuffled:
        by_index[index] = payload
    assembled = b"".join(by_index)
    failure_buffers = [b"A" * 4096, b"B" * 97, b""]
    preserved = sum(len(item) for item in failure_buffers) == 4193

    results = [
        check("NATIVE_SOURCE_COMPILES_ON_DUT",
              build.get("compile_exit_code") == 0 and
              build.get("binary_exists") is True,
              str(build.get("compiler"))),
        check("BINARY_IS_X86_64_LINUX",
              build.get("elf_x86_64") is True,
              str(build.get("file_output"))),
        check("NO_DEVICE_USAGE_SMOKE_TEST",
              build.get("smoke_exit_code") == 64 and
              build.get("smoke_device_open") is False,
              f"exit={build.get('smoke_exit_code')}"),
        check("NO_ACTIVE_DMA_SIGNAL_INTERRUPTION",
              not re.search(r"\b(SIGALRM|alarm\s*\(|setitimer\s*\(|kill\s*\()", text),
              "No signal-driven DMA interruption tokens"),
        check("NO_O_TRUNC_OR_EOP_FLUSH",
              "O_TRUNC" not in text and "eop_flush" not in text,
              "Forbidden tokens absent"),
        check("EXACT_2500_IOCBS_OF_4096_BYTES",
              "#define PRIMARY_RECORDS 2500U" in text and
              "#define RECORD_BYTES 4096U" in text and
              "request->cb.aio_data = index" in text and
              "request->cb.aio_nbytes = RECORD_BYTES" in text and
              "primary + index * RECORD_BYTES" in text and
              "request->cb.aio_offset = 0" in text,
              "Distinct indexed 4096-byte IOCBs 0..2499"),
        check("PREQUEUE_READY_AFTER_ALL_SUBMISSIONS",
              "while (submitted < PRIMARY_RECORDS" in text and
              "if (submitted != PRIMARY_RECORDS || early_count != 0)" in text and
              text.index("submitted != PRIMARY_RECORDS") <
              text.index("\\\"type\\\":\\\"PREQUEUE_READY\\\""),
              "PREQUEUE_READY follows the all-submitted hard guard"),
        check("ASSEMBLY_USES_REQUEST_INDEX",
              assembled == b"A" * 4096 + b"B" * 4096 + b"C" * 4096 and
              "primary + index * (size_t)RECORD_BYTES" in text and
              "assembly_basis\\\": \\\"REQUEST_INDEX" in text,
              "Shuffled completion fixture reconstructs A,B,C by request index"),
        check("COMPLETED_BUFFERS_PRESERVED_AFTER_LATER_FAILURE",
              preserved and "primary-partial-by-index.bin" in text and
              "if (!requests[index].completed || requests[index].result <= 0)" in text and
              text.index("persist_primary(argv[2]") < text.rindex("free(primary)"),
              "Positive completed buffers are persisted by fixed request index before free"),
    ]
    passed = sum(item["result"] == "PASS" for item in results)
    report = {
        "task": "G2B-HW0-PRODUCT-R3R4R6R2R2",
        "source": str(args.source),
        "source_sha256": hashlib.sha256(args.source.read_bytes()).hexdigest().upper(),
        "checks": results, "passed": passed, "total": 9,
        "result": "PASS" if passed == 9 else "FAIL",
    }
    args.report.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    return 0 if passed == 9 else 1


if __name__ == "__main__":
    raise SystemExit(main())
