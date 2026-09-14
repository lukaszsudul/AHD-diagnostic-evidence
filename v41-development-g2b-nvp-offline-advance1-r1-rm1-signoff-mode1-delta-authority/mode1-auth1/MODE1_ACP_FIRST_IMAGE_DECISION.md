# MODE1 ACP/coax first-image decision

Decision: `ACP_NOT_REQUIRED_FOR_FIRST_IMAGE`.

The NVP6134C register authority describes ACP/coax as a generator/receiver for control signaling between the DVR/controller and the camera over the video cable. Video input, decoder locking and BT.656 output are separate functions. Therefore all 35 ACP semantic operations are excluded from first-image MODE1. This does not claim camera OSD or coax control functionality.
