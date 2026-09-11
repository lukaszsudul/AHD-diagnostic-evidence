#!/usr/bin/env python3
"""Replay the derived action path while preserving unknown masked bits."""
import argparse
from pathlib import Path
from scan0_model import action_manifest, replay_actions, write_json

p=argparse.ArgumentParser(); p.add_argument("repo",type=Path); p.add_argument("channel",type=int,choices=[0,2]); p.add_argument("output",type=Path)
a=p.parse_args(); write_json(a.output,replay_actions(action_manifest(a.repo),a.channel))
