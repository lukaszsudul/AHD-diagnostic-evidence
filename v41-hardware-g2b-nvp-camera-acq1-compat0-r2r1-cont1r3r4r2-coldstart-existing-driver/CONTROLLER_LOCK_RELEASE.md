# Controller lock release

At approximately 2026-09-17 08:21 UTC, after the DUT lock was released,
the exact controller maintenance lock path
`C:\FPGA\.AHD_G2B_NVP_CAMERA_ACQ1_COMPAT0_R2R1_CONT1R3R4R2_COLDSTART_20260917T063836Z.lock`
was removed from the active lock namespace by a recoverable move to this
task's `authority\controller_lock_released` directory. The original path is
absent. The archived, pre-release receipt remains byte-identical with SHA-256
`249A5D4A7AFC82CD1EB96A8CF4FF8CAADB70006C10F4C9D323E240904DC29EA3`.
Its historical `HELD` field describes its pre-release state; it is not an
active lock at the archived path. No unrelated lock or file was moved.
