# SCAN1 FSM

States: `IDLE`, `WAIT_AUTOINIT_DONE`, `CAPTURE_ENTRY_BANK`, `SELECT_GROUP_BANK`, `VERIFY_GROUP_BANK`, `READ_GROUP_ENTRY`, `RESTORE_ENTRY_BANK`, `VERIFY_RESTORED_BANK`, `FINALIZE_SNAPSHOT`, `PUBLISH_DONE`, `WAIT_HOST_ACK`, `ABORT_SAFE`, `ERROR_SAFE`.

START is accepted only in IDLE. DONE holds a single frozen snapshot until ACK. START while BUSY or DONE-before-ACK is rejected and counted. ABORT/preemption/error routes through safe release and entry-bank restore; incomplete scans are never marked valid. State transitions are frozen in the companion JSON.
