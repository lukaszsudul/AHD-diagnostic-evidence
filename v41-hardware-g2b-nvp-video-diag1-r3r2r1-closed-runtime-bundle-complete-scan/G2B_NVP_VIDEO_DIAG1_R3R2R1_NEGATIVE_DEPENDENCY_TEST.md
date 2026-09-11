
# Negative dependency test

Only `abi_v1.py` was removed from an isolated copy of the final bundle. The gate
failed before hardware with `MISSING_LOCAL_DEPENDENCY` and exit code
1. The missing file was not restored in the negative
copy. Result: PASS_EXPECTED_FAILURE.
