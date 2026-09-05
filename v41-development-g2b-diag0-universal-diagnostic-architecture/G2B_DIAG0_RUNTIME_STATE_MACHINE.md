# Runtime state machine

Scope: DIAG0 offline architecture proposal; no implementation or hardware qualification. Normative decisions apply to the future HW0_DIAGNOSTIC profile. Engineering gate is BLOCKED by the explicitly identified NVP evidence gaps; publication does not promote SSOT.

State codes are the zero-based table order and are encoded in STATUS[7:0]. All states allow shadow writes. Commands omitted in a row set ILLEGAL_COMMAND and leave state unchanged. Snapshot is abbreviated SNAPSHOT; CLEAR is CLEAR_RUN_STATUS. Actual external reset overrides all software states and terminates the host session. Internal errors while an AXI packet is in flight enter ABORTING/DRAINING first; ERROR is output-idle.

|Code / state|Entry|Allowed commands|Output|Exit|Sticky effects|
|---|---|---|---|---|---|
|0 RESET|FPGA/AXI reset|none|none; external reset ends session|reset released -> IDLE|clear all state; ACTIVE invalid|
|1 IDLE|reset or CLEAR|START,CLEAR,SNAPSHOT; STOP/ABORT no-op|none|START -> CONFIG_VALIDATE|safe shadow defaults|
|2 CONFIG_VALIDATE|START candidate captured|SNAPSHOT,STOP,ABORT|none|valid -> WAIT_FRAME_BOUNDARY(synthetic video), RUNNING(record), SCANNING(live); invalid -> ERROR|CONFIG_ERROR rejects without RUN_ID change; initialize epoch before output|
|3 SCANNING|live start/rescan or next candidate|SNAPSHOT,STOP,ABORT|none|eligible -> ROUTING; exhausted -> ERROR|cache validity/per-input reason; INIT_DONE wait bounded|
|4 ROUTING|eligible candidate and no live output|SNAPSHOT,STOP,ABORT|none|verified I2C route -> WAIT_LOCK; failure -> next candidate/ERROR|I2C errors retained; legal STOP before owner transfer|
|5 WAIT_LOCK|route acknowledged|SNAPSHOT,STOP,ABORT|none|stable -> WAIT_FRAME_BOUNDARY; timeout -> next candidate/ERROR|stable timer resets on bad/stale sample|
|6 WAIT_FRAME_BOUNDARY|video acquisition or new cycle|SNAPSHOT,STOP,ABORT|none until full-frame admission|qualified complete-frame start -> RUNNING; timeout -> ERROR|discard initial partial/proving frame; not counted|
|7 RUNNING|unit admission allowed|SNAPSHOT,STOP,ABORT|selected complete records only|count/time/STOP -> STOP_PENDING; loss -> DRAINING; ABORT -> ABORTING|errors sticky; completed units only|
|8 STOP_PENDING|limit/time/STOP|SNAPSHOT,STOP,ABORT|current complete unit; no new unit|unit closed -> DRAINING; loss -> DRAINING|freeze stop cause; simultaneous limit counts once|
|9 DRAINING|producer closed|SNAPSHOT,STOP,ABORT|remaining complete records through TLAST|empty/retired -> PAUSED or COMPLETE or ERROR or SCANNING|never declare terminal while output active; preserve next_action|
|10 PAUSED|clean scheduled cycle end|SNAPSHOT,STOP,ABORT|none|pause expires -> next cycle or COMPLETE|cycle end includes configured pause even final cycle|
|11 COMPLETE|finite cycles/host STOP/ABORT drained|START,CLEAR,SNAPSHOT; STOP/ABORT no-op|none|START -> CONFIG_VALIDATE; CLEAR -> IDLE|retain complete/aborted result and counters|
|12 ABORTING|ABORT while busy|SNAPSHOT; STOP/ABORT idempotent|finish/drain complete records; discard FILLING|drain and epoch retirement -> COMPLETE|ABORTED_RUN once; no partial packet|
|13 ERROR|config/acquisition/runtime error after clean drain|SNAPSHOT,CLEAR; START if not fatal|none|CLEAR -> IDLE; valid START -> CONFIG_VALIDATE|sticky detail preserved; fatal needs new session|

Priority at one AXI edge: external reset; fatal containment; ABORT; source loss; host STOP; count/time limit; normal progress. A record beat that handshakes at that edge still counts. Limit/frame/record admission arbitration uses next counter value so the Nth unit cannot accidentally admit N+1. CONFIG_VALIDATE uses a cancellation latch for STOP/ABORT; canceled candidate never activates or consumes a run ID. DRAINING next_action (ERROR, RESCAN, PAUSE, COMPLETE) is latched; host STOP overrides rescan/repeat and ABORT overrides graceful completion. Epoch handshakes are internal substates; RUNNING output remains gated until epoch initialization completes.
