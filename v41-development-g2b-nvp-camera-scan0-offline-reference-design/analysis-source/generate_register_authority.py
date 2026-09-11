#!/usr/bin/env python3
"""Generate the 82-entry authority matrix and known side-effect blacklist."""
import argparse
from pathlib import Path
from scan0_model import candidate_registers, side_effect_blacklist, write_csv

p=argparse.ArgumentParser(); p.add_argument("output",type=Path); a=p.parse_args(); a.output.mkdir(parents=True,exist_ok=True)
rows=candidate_registers(); write_csv(a.output/"register_authority.csv",rows,list(rows[0]))
blocked=side_effect_blacklist(); write_csv(a.output/"read_side_effect_blacklist.csv",blocked,list(blocked[0]))
