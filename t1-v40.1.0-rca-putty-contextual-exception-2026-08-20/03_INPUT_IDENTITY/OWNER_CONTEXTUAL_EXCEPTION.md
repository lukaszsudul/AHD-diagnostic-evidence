# Owner contextual username/password exception

The owner explicitly confirms and authorizes the following narrow condition:

    OWNER_CONTEXTUAL_EXCEPTION=YES
    USERNAME_EQUALS_PASSWORD=YES

The shared literal is permitted only in a non-secret username role, including
the exact token following Plink option -l and the read-only result of id -un.
Authentication continues to use one-use protected pwfiles, and sudo input
continues to use redirected standard input.

This exception does not authorize Plink option -pw, a password-role process
argument, a password-bearing environment variable, a password literal in a
remote command, a saved PuTTY session, or retained authentication material.
