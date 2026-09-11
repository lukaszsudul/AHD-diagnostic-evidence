#!/usr/bin/env python3
"""Calculate transaction and 25-kHz SCL-period timing from the frozen table."""
import argparse
from pathlib import Path
from scan0_model import candidate_registers, scan_manifest, scan_time_rows, write_csv

p=argparse.ArgumentParser(); p.add_argument("output",type=Path); a=p.parse_args()
rows=scan_time_rows(scan_manifest(candidate_registers())); write_csv(a.output,rows,list(rows[0]))
