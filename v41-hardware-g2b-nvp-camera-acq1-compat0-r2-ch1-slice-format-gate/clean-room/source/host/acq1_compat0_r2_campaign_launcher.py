#!/usr/bin/env python3
"""Closed-bundle bounded campaign launcher."""

import sys
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parent))

from acq1_compat0_r2.campaign import main  # noqa: E402


if __name__ == "__main__":
    raise SystemExit(main())
