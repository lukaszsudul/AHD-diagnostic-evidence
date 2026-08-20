# Contextual secret-handling ledger

## Credential gate

    CREDENTIAL_FILE_FOUND=YES
    CREDENTIAL_FILE_PARSE=PASS_LABELLED_UTF8
    EXPECTED_IP_MATCH=YES
    EXPECTED_USER_MATCH=YES
    PASSWORD_PRESENT=YES
    USERNAME_EQUALS_PASSWORD=YES
    OWNER_CONTEXTUAL_EXCEPTION=YES

No password-role value is retained.

## Structural token gate

Each actual Plink argument vector was constructed as individual
ProcessStartInfo argument tokens and audited before process start.

    SECRET_COLLISION_EXCEPTION_APPLIED=YES
    PLINK_PW_OPTION_USED=NO
    PLINK_PWFILE_OPTION_USED=YES
    PASSWORD_IN_PROCESS_ARGUMENT_PASSWORD_ROLE=NO
    PASSWORD_IN_PROCESS_ARGUMENT_USERNAME_ROLE=YES_AUTHORIZED
    REMOTE_COMMAND_SHARED_LITERAL=NO
    PASSWORD_BEARING_INHERITED_ENVIRONMENT=NO
    CONTEXT_LOGS_AUDITED=7
    CONTEXT_LOG_AUDIT=PASS

## Temporary-file gate

Every invocation created a new randomized pwfile only after ACL inheritance was
disabled and access was restricted to the current Windows user and SYSTEM.
Every file was deleted in the helper finally block.

    TEMP_PASSWORD_FILES_REMAINING=0
    PW_EXTENSION_FILES_REMAINING=0
    ORIGINAL_CREDENTIAL_FILE_MODIFIED=NO
    STRUCTURAL_SECRET_HANDLING_GATE=PASS

## Final campaign audit

All 60 contextual Plink process records were re-audited. Every retained record
reports the same structural result: `-pw` absent, exactly one task-local
`-pwfile`, the shared literal present in argument tokens only as the authorized
username following `-l`, no shared literal in the remote command, no inherited
password-bearing environment value, and deletion of its randomized pwfile.

Authorized retained occurrences are username fields and `id -un` results.
Home-directory paths emitted by a usage message and module metadata were
sanitized to `$HOME`. No password value, sudo stdin, credential-file content,
or unsanitized authentication command is retained.

    CONTEXTUAL_PLINK_PROCESS_RECORDS=60
    CONTEXT_LOG_AUDIT=PASS_60_OF_60
    SECRET_COLLISION_EXCEPTION_APPLIED=YES
    PLINK_PW_OPTION_USED=NO
    PLINK_PWFILE_OPTION_USED=YES
    PASSWORD_IN_PROCESS_ARGUMENT_PASSWORD_ROLE=NO
    PASSWORD_IN_PROCESS_ARGUMENT_USERNAME_ROLE=YES_AUTHORIZED
    TEMP_PASSWORD_FILES_REMAINING=0
    ORIGINAL_CREDENTIAL_FILE_MODIFIED=NO
    STRUCTURAL_SECRET_HANDLING_GATE=PASS
