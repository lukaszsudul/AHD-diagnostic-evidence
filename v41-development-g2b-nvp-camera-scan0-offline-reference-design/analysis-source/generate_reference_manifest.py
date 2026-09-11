#!/usr/bin/env python3
"""Generate the pinned reference file identity manifest."""
import argparse
from pathlib import Path
from scan0_model import REFERENCE_COMMIT, git, reference_manifest, write_csv, write_json

p=argparse.ArgumentParser(); p.add_argument("repo",type=Path); p.add_argument("output",type=Path)
a=p.parse_args()
assert git(a.repo,"rev-parse","HEAD")==REFERENCE_COMMIT and not git(a.repo,"status","--short")
rows=reference_manifest(a.repo); a.output.mkdir(parents=True,exist_ok=True)
write_csv(a.output/"reference_manifest.csv",rows,list(rows[0]))
write_json(a.output/"reference_manifest.json",{"commit":REFERENCE_COMMIT,"files":rows})
