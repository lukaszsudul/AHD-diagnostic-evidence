# PCB-PIN-1 PROGRAM_B Architecture Decision

## Decision

PROGRAM_B_SELF_RESET = REMOVE

Recommendation = A. REMOVE LOOP FROM PRODUCT PCB

PROGRAM_B_LOOP_REQUIRED = NO

INTERNAL_RECONFIGURATION_ALTERNATIVE = SUPPORTED

Replacement FPGA GPIO required = NO

PCB routing may proceed without assigning another FPGA GPIO to replace T12.

## Product recommendation

Remove the product-board connection from an FPGA user I/O to the dedicated PROGRAM_B pin. Preserve the normal external PROGRAM_B pull-up and any required programming/debug access independently. If recovery must operate when no valid user image is running, use an external supervisor or other external reconfiguration controller; do not treat a user-I/O feedback loop as that recovery mechanism.

The reasons are:

- PROGRAM_B causes a full configuration-memory clear and reload, not an ordinary RTL reset.
- A transient logic error, initialization mistake, or electrical disturbance on the loop can remove the whole FPGA design.
- As reconfiguration starts, global three-state removes the user-I/O drive. The loop is self-terminating and its low time is not inherently guaranteed.
- A direct push-pull loop can contend with a programmer, pushbutton, or supervisor.
- A loop cannot recover a device that never configured far enough to make the user output operational.
- ICAPE2/IPROG supports intentional user-logic-initiated reconfiguration and is compatible with WBSTAR, MultiBoot, golden-image, and fallback strategies.

## Electrical semantics

AMD UG470 defines PROGRAM_B as a dedicated active-low configuration-reset input. Its falling edge starts configuration reset; a following rising edge permits the new configuration sequence. PROGRAM_B must have an external pull-up no larger than 4.7 kOhm to VCCO_0. Artix-7 DS181 specifies TPROGRAM, the minimum low program pulse width, as 250 ns.

When PROGRAM_B is asserted, configuration memory is cleared, block RAM is returned to initial state, flip-flops are reinitialized, and user I/O becomes high impedance under GTS. Therefore the T12 driver disappears during the very operation it starts. The external PROGRAM_B pull-up then releases the dedicated pin. The low interval must not be assumed to be self-sustaining or long enough merely because the FPGA started it.

If such a loop were ever retained for a non-product experiment, safe implementation would require:

- the mandatory PROGRAM_B pull-up;
- a low-only/open-drain or open-collector driver, not a push-pull-high driver;
- a tolerance-analyzed mechanism that guarantees at least TPROGRAM, such as a one-shot, supervisor, or properly analyzed RC/buffer circuit;
- protection against power-up assertion and repeated boot loops; and
- verified compatibility with every other PROGRAM_B driver.

That redesign cost is not justified for the present product architecture.

## Internal alternative

UG470 documents the 7-series ICAPE2/IPROG path. User logic can write WBSTAR and issue IPROG. IPROG resets the device except for dedicated reconfiguration logic, drives INIT_B and DONE low, clears configuration, and reloads from the selected start address. This is the architecturally cleaner implementation for a future intentional self-reconfiguration request.

IPROG is not a substitute for external recovery when no viable image is active. A robust remote-update design should combine an internally initiated warm boot with a protected golden image, fallback/watchdog policy, and external programming/recovery access appropriate to the product.

## PROGRAM_B versus PUDC_B

PROGRAM_B and PUDC_B are independent:

- PROGRAM_B is the dedicated configuration reset/reload control.
- PUDC_B is a Bank-14 multifunction input that selects whether SelectIO weak pull-ups are active before and during configuration.

Changing or removing the PROGRAM_B feedback loop does not decide the PUDC_B strap, and the PUDC_B strap must not be described as a logic-reset function.

## Official references

- AMD UG470, 7 Series FPGAs Configuration User Guide, pp. 20-21, 80-81, 135-138: https://docs.amd.com/v/u/en-US/ug470_7Series_Config
- AMD DS181, Artix-7 DC and AC Switching Characteristics, Table 66: https://docs.amd.com/v/u/en-US/ds181_Artix_7_Data_Sheet
