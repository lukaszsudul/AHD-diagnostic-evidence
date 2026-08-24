# Independent R1g resource-audit identity

## Verified facts

```text
RESOURCE_AUDIT_REPORT_PATH=C:\FPGA\R1G_OFFLINE_RESOURCE_ATTRIBUTION_AND_R1H_PLAN\R1G_RESOURCE_ATTRIBUTION_REPORT.md
RESOURCE_ATTRIBUTION_REPORT_SHA256=45A5E7BE82D94BFB781BA6726F3FBD47236CD551703542EE4964C6C392C2ACB6
RESOURCE_AUDIT_MANIFEST_SHA256=776A900D108880230CFFA4CC0BC1AF989858E3A2C0298C5F0B38B0DC310A691F
RESOURCE_AUDIT_MANIFEST_RESULT=PASS_61_OF_61
SOURCE_GIT_COMMIT=e112a5addb7ac62700a9a71af81bf368fad0bada
SOURCE_GIT_TREE=3a59ebec130103055d24a3a32ecda00dedde5534
VIVADO_VERSION=2025.2
VIVADO_SW_BUILD=6299465
SOURCE_MUTATIONS=0
SYNTHESIS_RUNS=0
IMPLEMENTATION_RUNS=0
HARDWARE_ACTIONS=0
```

The report and every one of its 61 manifested evidence files were freshly
rehash-verified. The audit directory is task-local and is not a Git worktree.
The current public evidence tree at R1g evidence commit `31786f...` contains no
resource-audit report path, and the task-local audit root contains no evidence
ZIP or sidecar. Accordingly:

```text
RESOURCE_AUDIT_EVIDENCE_COMMIT=UNAVAILABLE_NOT_PUBLISHED_TASK_LOCAL_AUDIT
RESOURCE_AUDIT_PACKAGE_SHA256=UNAVAILABLE_NO_PACKAGE_CREATED
```

This unavailable-publication classification is fail-closed and does not affect
the verified byte identity of the local report and its complete manifest.
