#!/usr/bin/env python3
import sys
from pathlib import Path

BUNDLE_ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(BUNDLE_ROOT))

from cont1r2_integrity import main


if __name__ == "__main__":
    raise SystemExit(main())
