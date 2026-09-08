# Driver load

- Exact `insmod` attempts: 1
- `insmod` return code: 0
- Driver load: PASS
- `/dev/xdma0_user`: created
- `/dev/xdma0_c2h_0`: created
- `modprobe`, `new_id`, `driver_override`, manual bind, and module parameters: not used
- Normal `rmmod` at cleanup: not executed because physical quiescence was not proven and module refcount was 1
- Post-terminal-reboot unload state: not verified because SSH did not return in the bounded reconnect window
