"""Byte-exact accepted CONT1R1 projection, re-exported without semantic change."""

from cont1r1_projection import (
    ProjectionGateError,
    configuration_projection,
    manifest_preflight,
    required_projection_keys,
)

__all__ = [
    "ProjectionGateError",
    "configuration_projection",
    "manifest_preflight",
    "required_projection_keys",
]
