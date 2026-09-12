#!/usr/bin/env python3
"""Closed-bundle fixed-executor launcher."""

import sys
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parent))

from acq1_compat0_r2.controller import main  # noqa: E402


if __name__ == "__main__":
    raise SystemExit(main())
