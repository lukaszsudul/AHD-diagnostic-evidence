#!/usr/bin/env python3
"""Extract the set_chnmode dispatch/call graph from the pinned source."""
import argparse
from pathlib import Path
from aggregate_evidence import call_graph
from scan0_model import write_json

p=argparse.ArgumentParser(); p.add_argument("repo",type=Path); p.add_argument("output",type=Path)
a=p.parse_args(); write_json(a.output,call_graph(a.repo))
