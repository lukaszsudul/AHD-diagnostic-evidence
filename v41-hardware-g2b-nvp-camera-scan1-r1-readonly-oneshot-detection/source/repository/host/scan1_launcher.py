#!/usr/bin/env python3
"""Closed-bundle launcher; only the adjacent bundle root is importable locally."""

from __future__ import annotations

import sys
from pathlib import Path


BUNDLE_ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(BUNDLE_ROOT))

from scan1.controller import main  # noqa: E402


if __name__ == "__main__":
    raise SystemExit(main())

