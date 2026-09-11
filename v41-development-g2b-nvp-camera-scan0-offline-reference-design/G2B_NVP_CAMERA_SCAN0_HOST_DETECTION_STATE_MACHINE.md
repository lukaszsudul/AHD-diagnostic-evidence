# Stateful host detection campaign

Per channel the host owns `campaign_id`, `scan_index`, previous complete raw tuple, stable count, candidate format, confirmed format, three debounce buffers, last applied mode, last EQ state, slice phase and video-loss transition history. A new campaign resets every field and refuses old generations.

Only valid-complete snapshots with stable generation, exact manifest identity, verified entry-bank restore and equal A8 bookends advance stability. Three consecutive byte-identical required raw tuples are necessary. A primary blocker is selected by fixed priority (snapshot integrity, bank/restore, live change, register authority, format resolution, physical mapping); all other findings remain visible. No action follows from a single F0 value.
