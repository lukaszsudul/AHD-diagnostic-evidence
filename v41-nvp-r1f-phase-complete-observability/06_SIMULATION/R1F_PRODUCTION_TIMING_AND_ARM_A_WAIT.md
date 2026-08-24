# R1f production timing model and frozen Arm-A wait

## Gate result

```text
R1F_PRODUCTION_TIMING_MODEL=PASS
AUTOINIT_CLOCK_HZ=62500000
AUTOINIT_I2C_HZ=25000
EXPECTED_CNT_AT_INIT_DONE=132584734
PROBE_TARGET_OPPORTUNITIES_PER_PHASE=10000
PROBE_PHASES=3
PROBE_I2C_HZ=25000
R1F_PROBE_CYCLES_FROM_INIT_DONE_AT_MODEL_CLOCK=29415318
R1F_PROBE_SECONDS_FROM_INIT_DONE=29.415318000
MODELED_R1F_PROBE_COMPLETE_SECONDS_FROM_CONFIGURATION=31.536673744
ARM_A_MARGIN_SECONDS=2.000000000
ARM_A_REQUIRED_WAIT_SECONDS=33.536673744
```

The focused XSim model ran the exact production scheduler counts: 10,000
physically reached target opportunities for each of WADDR, REGADDR, and DATA;
10 blocks per phase; 512 index slots per phase; 12,000 maximum attempts per
phase; and an all-ACK bus.  It completed 10,000 interleaved scheduler rounds,
all six prerequisite/target opportunity and ACK totals were exactly 10,000,
all NACK and timeout totals were zero, setup/readback/restoration passed, and
the probe reached its success terminal state.

To keep the cycle-accurate simulation bounded, the test used a 1 MHz model
clock with a 1 us period while retaining 25 kHz I2C.  Every time-derived
parameter was scaled to the same physical duration as production: a 1 ms
post-init guard, a 20 us SCL timeout, and a 1 ms bus-idle timeout.  The
DIVIDER-derived tick duration and low-level state sequencing therefore
preserve physical probe time even though the raw clock/I2C cycle ratio is
scaled.  The measured 29,415,318 model-clock cycles equal
29.415318000 seconds from original `init_done` to final probe completion.

The frozen pre-increment autoinit count contributes:

```text
132584734 / 62500000 = 2.121355744 seconds
2.121355744 + 29.415318000 = 31.536673744 seconds
max(10.0, 31.536673744 + 2.0) = 33.536673744 seconds
```

The hardware supervisor must wait at least `33.536673744` seconds from the
later accepted post-program timing marker.  It may not shorten or recompute
this value after observing hardware results.

## Exact evidence identities

```text
TRI_PHASE_RTL_SHA256=4AA823B5896D9C11DB9837D1F30E4E077557FE367942B032B404ACBA92E03552
TIMING_TB_SHA256=71523794924E8AB03F2A6F02C2C7998791E14A474088F44850AC0286BD40A38D
TIMING_WRAPPER_SHA256=F501265BD3B87C17958E52955D76D6FAC924D19C9D0F649B9FFAF24045E0F505
XVLOG_SHA256=9822ECB3B5E8C31019442B5814B5E7E65786711ACC17B34B59B90EDAAC9FDE66
XELAB_SHA256=67A58CDE98F954F63F7785F62AA316DAF350CD8A360F186EEAF7352A567F2A1B
XSIM_SHA256=06D6D00BDF6F23D6AA6479B9D688437D9DD4F2B76D01AB9984229DBF8D32923B
```

Raw logs are preserved in
`06_SIMULATION/tri_phase_probe_production_timing_v2/`.
