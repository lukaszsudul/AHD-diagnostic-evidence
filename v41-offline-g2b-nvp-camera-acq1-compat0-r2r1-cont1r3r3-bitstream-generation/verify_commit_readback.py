"""Compare every public CONT1R3R3 file to commit-pinned remote raw bytes."""

import argparse
import datetime as dt
import hashlib
import json
import urllib.parse
import urllib.request
from pathlib import Path


MANIFEST = "CONT1R3R3_SHA256_MANIFEST.txt"


def sha(data):
    return hashlib.sha256(data).hexdigest().upper()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--repository", required=True)
    parser.add_argument("--commit", required=True)
    parser.add_argument("--remote-directory", required=True)
    parser.add_argument("--stage", type=Path, required=True)
    parser.add_argument("--readback-directory", type=Path, required=True)
    parser.add_argument("--receipt", type=Path, required=True)
    args = parser.parse_args()
    if args.receipt.exists() or args.readback_directory.exists():
        raise ValueError("fresh readback output paths required")
    if len(args.commit) != 40 or any(c not in "0123456789abcdef" for c in args.commit.lower()):
        raise ValueError("full commit SHA required")
    lines = (args.stage / MANIFEST).read_text(encoding="utf-8").splitlines()
    specs = []
    for line in lines:
        digest, size_text, name = line.split("  ", 2)
        specs.append((name, int(size_text), digest))
    specs.append((MANIFEST, (args.stage / MANIFEST).stat().st_size, sha((args.stage / MANIFEST).read_bytes())))
    args.readback_directory.mkdir(parents=True)
    checked = []
    for name, expected_size, expected_digest in specs:
        local = (args.stage / name).read_bytes()
        if len(local) != expected_size or sha(local) != expected_digest:
            raise ValueError(f"local manifest mismatch: {name}")
        remote_path = "/".join(
            urllib.parse.quote(part, safe="")
            for part in (args.remote_directory, name)
        )
        url = f"https://raw.githubusercontent.com/{args.repository}/{args.commit}/{remote_path}"
        with urllib.request.urlopen(url, timeout=30) as response:
            if response.status != 200:
                raise ValueError(f"HTTP {response.status}: {name}")
            remote = response.read()
        (args.readback_directory / name).write_bytes(remote)
        if len(remote) != expected_size or sha(remote) != expected_digest or remote != local:
            raise ValueError(f"commit-pinned remote bytes differ: {name}")
        checked.append({"name": name, "size_bytes": expected_size, "sha256": expected_digest})
        print(f"REMOTE_READBACK_PASS={name}|{expected_size}|{expected_digest}")
    receipt = {
        "repository": args.repository,
        "commit": args.commit,
        "directory": args.remote_directory,
        "checked_files": checked,
        "count": len(checked),
        "result": "PASS",
        "checked_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
    }
    args.receipt.write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
