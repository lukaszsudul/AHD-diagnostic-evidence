# R4 Evidence Secret Scan

SCAN_SCOPE=C:\FPGA\V41_NVP_R1E_FORMAL_BOOTSTRAP_AND_PAIRED_AB_R4
CREDENTIAL_FILE_INCLUDED=NO
FILES_SCANNED_BEFORE_SEAL=110
PRIVATE_KEY_MARKER_HITS=0
PLINK_PW_VALUE_PATTERN_LINES=0

The credential's password literal is identical to the already-public DUT user
name in the owner prompt. A byte scan therefore finds that shared literal in
10 files / 40 lines, all attributable to the verbatim owner prompt, public
remote username, absolute `/home/<user>/...` paths, or explicit expected-user
fields. This is not treated as a credential-role leak.

SHARED_LITERAL_EQUALS_PUBLIC_USERNAME=YES
SHARED_LITERAL_PASSWORD_ROLE_LEAKS=0
REMOTE_COMMAND_SHARED_LITERAL=NO
PLINK_PW_OPTION_USED=NO
PLINK_PWFILE_OPTION_USED=YES
PASSWORD_ROLE_ARGUMENT_OCCURRENCE=NO
SECRET_SCAN=PASS

The accepted transport helper created a temporary password file only in its
isolated secret directory and deleted it after each call. That directory and
the credential source file are outside the R4 evidence root and are not
packaged.
