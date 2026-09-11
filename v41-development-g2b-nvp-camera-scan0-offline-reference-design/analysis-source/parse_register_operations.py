#!/usr/bin/env python3
"""Parse the selected AHD1080p25 reference semantic operation path."""
import argparse
from pathlib import Path
from scan0_model import action_manifest, action_rows, manifest_digest, write_json

p=argparse.ArgumentParser(); p.add_argument("repo",type=Path); p.add_argument("output",type=Path)
a=p.parse_args(); rows=action_rows(action_manifest(a.repo))
write_json(a.output,{"semantic_operation_count":len(rows),"digest":manifest_digest(rows),"operations":rows})
