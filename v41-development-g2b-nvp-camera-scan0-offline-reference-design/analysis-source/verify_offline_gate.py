#!/usr/bin/env python3
"""Independently verify published offline gate and SHA closure."""
import csv, hashlib, sys
from pathlib import Path

root=Path(sys.argv[1]).resolve()
results=list(csv.DictReader((root/"G2B_NVP_CAMERA_SCAN0_OFFLINE_TEST_RESULTS.csv").open(encoding="utf-8")))
assert len(results)==24 and [r["Test"] for r in results]==[f"T{i}" for i in range(1,25)]
assert all(r["Result"]=="PASS" for r in results)
manifest=root/"G2B_NVP_CAMERA_SCAN0_OFFLINE_SHA256_MANIFEST.txt"
covered=set()
for line in manifest.read_text(encoding="utf-8").splitlines():
    digest,rel=line.split(" *",1); path=root/rel
    assert path.is_file() and hashlib.sha256(path.read_bytes()).hexdigest().upper()==digest
    covered.add(Path(rel).as_posix())
expected={p.relative_to(root).as_posix() for p in root.rglob("*") if p.is_file() and p!=manifest}
assert covered==expected
print(f"PASS 24/24; {len(covered)} files SHA-256 verified")
