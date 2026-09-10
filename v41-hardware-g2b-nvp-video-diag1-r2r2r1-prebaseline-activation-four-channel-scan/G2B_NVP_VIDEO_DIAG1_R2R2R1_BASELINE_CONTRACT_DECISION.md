# Double-PREPARE baseline contract decision

Method: TWO_CONSECUTIVE_PREPARE_PASSES

Decision: NOT_REACHED

The sole initial CLEAR was issued, but diagnostic STATUS and ERROR immediately
returned `0xFFFFFFFF`; therefore PREPARE_A and PREPARE_B were never issued and
no restoration authority was established. START remained hard-gated.
