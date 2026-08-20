# Driver recovery

All immediate gates passed. The accepted loader was invoked exactly once through `/usr/bin/bash`. It verified the exact module hash, observed no preexisting `xdma`, performed one `insmod`, bound `0000:01:00.0`, and created `/dev/xdma0_user` and `/dev/xdma0_control`.

The out-of-tree signature taint is expected with Secure Boot disabled and was not a rejection. No unknown symbol, probe failure, AER error, reset, or rescan was observed.

    LOADER_INVOCATIONS=1
    INSMOD_INVOCATIONS=1
    PINNED_DRIVER_RECOVERY=PASS_EXACT_LOADER_VIA_USR_BIN_BASH
    POSTLOAD_BOUND_DRIVER=/sys/bus/pci/drivers/xdma
    POSTLOAD_USER_NODE=/dev/xdma0_user
    POSTLOAD_CONTROL_NODE=/dev/xdma0_control
    POSTLOAD_KERNEL_HEALTH=PASS

The recovered driver remains loaded as required.

