
# Dependency closure method

The bundle builder starts from every runtime entry point, recursively parses
static imports and explicit dynamic/subprocess/resource references, classifies
local modules versus standard-library/recorded third-party dependencies, and
hash-pins every local module and runtime resource. Symlinks, credential remnants,
old-task absolute runtime dependencies, unresolved imports, and ambiguous local
imports are rejected.

Result: 17 local modules,
9 runtime resources, 25
files, zero unresolved or ambiguous imports, and manifest SHA-256 `0EC4B48D2C7665F71B8E99C0C0F766AFBE78E35AA89A4A52956D5CF400C9F787`.
