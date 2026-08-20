# Secret-handling ledger

The labelled UTF-8 credential source was read only inside a short-lived helper
process. The expected identity fields matched and the secret was present.

Before creation of a one-use pwfile, the helper compared the in-memory secret
with the complete intended Plink argument list. It found an exact collision and
rejected the invocation.

The helper contained no hard-coded password. Because one required identity
literal also collided with the secret, the task-local helper was removed during
sanitized cleanup and is not retained as evidence.

    CREDENTIAL_FILE_PARSE=PASS_LABELLED_UTF8
    EXPECTED_IP_MATCH=YES
    EXPECTED_USER_MATCH=YES
    PASSWORD_PRESENT=YES
    PLINK_ARGUMENT_SECRET_COLLISION=YES
    PLINK_PROCESS_STARTED=NO
    PASSWORD_FILE_CREATED=NO
    TEMP_PASSWORD_FILES_REMAINING=0
    PASSWORD_IN_EXECUTED_PROCESS_ARGUMENTS=NO
    ORIGINAL_CREDENTIAL_FILE_MODIFIED=NO
    SECRET_LEAK_SCAN=PASS

No credential value, secret property, or matching output line is recorded.
