# AHD Project-State Changelog

This file is append-only. Published revision entries must never be edited,
deleted, reordered, squashed into another entry, or rewritten. A correction
requires a new authorized project-state revision.

## PROJECT_STATE_REV 1 — 2026-08-28

Status: `ACCEPTED`
Update type: `META_GOVERNANCE_CHANGE` and initial state capture
Authorization: `META-0_TASK_DIRECTIVE` containing `SSOT WRITE AUTHORIZED`
Expected previous revision: `ABSENT`
Accepted by role: `OWNER_ARCHITECT`
Applied by role: `META_UPDATE_AGENT`

Created the first AHD v41 current-state and architecture SSOT and froze its
governance, update policy, machine schema, evidence mapping, integrity
manifest, optimistic concurrency control, and stale-agent detection.

Initial project truth recorded:

- Product: G-1 `ACCEPTED`, G0 `ACCEPTED`, G1 `ACCEPTED`, G2A `ACTIVE`.
- Research: R0 `ACCEPTED`, R1 `ACTIVE`; R1i-a/R1i-b remain research-only.
- Linux Video: L0 `PLANNED`; V4L2 with transport abstraction is a planned
  architecture direction, not implemented state.
- META: META-0 governance infrastructure is accepted only by this creation
  task; no wider Owner acceptance is inferred.
- Qualified FPGA baseline: R1i at commit
  `20c3323d79d3896edc586d6db1df7deee60f9e41`, tree
  `70d801fd7a879080da399bfa9ee95fd6eb008e16`, frozen tag
  `v41-r1i-qualified-poc-20260827`.
- Product PCIe requirement: Gen2 x1 or better and sustained application
  payload `>= 288 MB/s` per card; Gen2 and throughput remain unqualified.
- Video topology: 4 physical inputs/card, max 2 active/card, planned 2
  cards/host.
- Accepted G1 C2H architecture: one C2H/card, two private four-record rings,
  shared formatter/engine, record-boundary round-robin, channel-tagged records.
- Transport ABI and v41D implementation contract remain `PROVISIONAL`.

Evidence repository snapshot before creation:
`f1258ba3ad2d6ab29c01260ce70fd23b59d8d4dd`. The snapshot contained no prior
`project-current-state/` directory and no newer G2A, R1, L0, Linux, or V4L2
evidence package. Evidence `PASS` was not treated as acceptance; accepted
labels derive from the explicit Owner/Architect-approved META-0 input.
