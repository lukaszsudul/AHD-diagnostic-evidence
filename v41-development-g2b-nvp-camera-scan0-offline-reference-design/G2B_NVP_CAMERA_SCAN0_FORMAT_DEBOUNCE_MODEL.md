# Reference format debounce model

The reference owns per-channel `s_fmt_dbnc_cnt` and three converted-format buffers. Each call reads F0/F2/F3/F4/F5 and conditional metrics, stores one converted result in the current slot, and advances the slot modulo three. A transition is accepted only when all three buffers agree. Otherwise the converted prior `s_keep_fmt` is returned. Stable no-detection clears both `s_fmt_set_done` and `g_eq_set_done` for that channel.

Initial detection is less strict: after its temporary discrimination writes it immediately sets format-done and seeds all three buffers to the same result. The governed host policy is intentionally stricter and requires three consecutive complete raw tuples in a fresh campaign before confirming any acquisition format. `g_eq_set_done` gates ordinary already-set changes in the reference and is retained as an explicit host state dependency, never inferred.
