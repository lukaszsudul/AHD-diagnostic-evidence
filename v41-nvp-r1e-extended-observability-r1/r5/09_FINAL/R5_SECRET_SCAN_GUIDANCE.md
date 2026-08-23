# R5 evidence secret-scan guidance

Run this scan locally after all R5 evidence and the authoritative final report
have been staged, but before creating the sealed ZIP or evidence-repository
commit. It must not make a network connection and must never read or copy
`C:\FPGA\VCDE-DUT-1.txt` into evidence.

## Inclusion and temporary-file gates

Require all of the following:

```text
CREDENTIAL_FILE_INCLUDED=NO
PRIVATE_KEY_FILE_INCLUDED=NO
PASSWORD_TEMP_FILE_COUNT=0
EXECUTED_COMMAND_STANDALONE_PUTTY_PW_OPTION_COUNT=0
HIGH_CONFIDENCE_SECRET_TOKEN_PATTERN_COUNT=0
REVIEWED_SENSITIVE_ASSIGNMENT_FINDINGS=0
SECRET_SCAN_RESULT=PASS
```

Use file-list checks to reject any included credential/key material or leaked
credential-helper temporary file:

```powershell
$root = 'C:\FPGA\V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5'
$files = @(rg --files --hidden $root)
$files | Select-String -CaseSensitive -Pattern `
  'VCDE-DUT-1\.txt$|(^|[\\/])pw-[0-9a-fA-F]+\.tmp$|\.pem$|\.pfx$|id_rsa$|id_ed25519$'
```

Any match is a hard failure unless it is merely a textual reference inside a
Markdown/log file rather than an included file path. Inspect file-list matches,
not just prose mentioning the protected credential path.

## Text-content scan

First scan for high-confidence secret formats while excluding binary
FPGA/build/package formats:

```powershell
rg -n -i --hidden `
  --glob '!*.bit' --glob '!*.dcp' --glob '!*.zip' --glob '!*.pyc' `
  --glob '!*.png' --glob '!*.jpg' --glob '!*.pdf' `
  -- `
  '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|github_pat_[A-Za-z0-9_]+|gh[pousr]_[A-Za-z0-9]+|xox[baprs]-[A-Za-z0-9-]+|AKIA[0-9A-Z]{16}' `
  $root
```

Then scan only potential live phase command evidence for a standalone PuTTY
`-pw` option. The verbatim owner prompt and the frozen helper source mention
`-pw` as a forbidden token, so a repository-wide raw count would be a false
gate. The required `-pwfile` option is not a finding.

```powershell
$liveRoots = @(
  "$root\04_HOST_SAFETY_DISCOVERY",
  "$root\05_FORMAL_BOOTSTRAP",
  "$root\06_ARM_A_R1E",
  "$root\07_ARM_B_FORMAL"
)
rg -n -- '(^|[[:space:]])-pw([[:space:]]|$)' $liveRoots
```

Finally review assignment-shaped occurrences of `password`, `passwd`,
`secret`, or `token`. Variable names, sanitized `NO/PASS` audit fields, parser
error prose, and assignments to `$null` are not secrets; any literal sensitive
value is a failure. Do not dump environment variables or the credential file
to perform this review.

The established credential happens to share a literal with an authorized user
identity, so a blind scan for the username alone is not meaningful. Review
that literal contextually: appearances as `USER`, `ExpectedUser`, a home path,
or the SSH login identity are expected; appearances as a password argument,
password field value, remote command literal, or inherited environment value
are failures.

## Credential-safe helper evidence

For every `Invoke-ContextualPlink.ps1` evidence record, when such records exist,
require:

```text
PLINK_PW_OPTION_USED=NO
PLINK_PWFILE_OPTION_USED=YES
PASSWORD_ROLE_ARGUMENT_OCCURRENCE=NO
REMOTE_COMMAND_SHARED_LITERAL=NO
INHERITED_ENVIRONMENT_AUDIT=PASS
PWFILE_DELETED=YES
```

R5 stopped before SSH, so no such live record is expected. Do not manufacture
one for the terminal package.

## Package-order rule

1. Complete the final report and operation ledger.
2. Run the file-list and text-content scans locally.
3. Record commands, match counts, reviewed false positives, UTC, and final gate
   in a dedicated secret-scan result file.
4. Generate `SHA256_MANIFEST.txt` only after the scan result is present.
5. Create the sealed ZIP from the scanned tree.
6. Hash the ZIP and write its sidecar.
7. Recheck that neither credential files nor `pw-*.tmp` files entered the ZIP
   listing before committing/pushing evidence.

Binary `.bit` artifacts should be identity-checked by their exact SHA-256 and
size, not interpreted by the text scanner.
