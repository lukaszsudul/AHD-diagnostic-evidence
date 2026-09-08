# Publication sanitization

The governed account token also matches a value in the private credential source. To enforce the prohibition on publishing credentials, every occurrence of that token in public text, source copies, and path metadata is replaced with `<GOVERNED_USER_REDACTED>`.

The full files are otherwise present. `support/source-original-sha256.json` records SHA-256 identities of the exact task-local source files before public redaction. The public manifest hashes the sanitized bytes actually committed. No password value, compiled executable, raw capture, driver, bitstream, or camera image is present.
