# Kernel and next-reboot selection gate

```text
KERNEL_AND_BOOT_RAW_SHA256=78F0C46E7F891C3F8B9874ECC4F7480AABE4BC2AA769FCB8B9E199F108106666
CURRENT_BOOT_ID=f86e72b5-a516-43da-b320-841b715bb926
CURRENT_KERNEL=7.0.0-29-generic
PROC_CMDLINE_BOOT_IMAGE=/boot/vmlinuz-7.0.0-29-generic
PINNED_MODULE_VERMAGIC=7.0.0-29-generic SMP preempt mod_unload modversions
CURRENT_KERNEL_EQUALS_PINNED_VERMAGIC=YES
ACTIVE_BOOTLOADER=GRUB
GRUB_DEFAULT=gnulinux-advanced-f7897627-c98a-4bf4-b24a-ae18f881e2da>gnulinux-7.0.0-29-generic-advanced-f7897627-c98a-4bf4-b24a-ae18f881e2da
GRUB_NEXT_ENTRY=NONE
PERSISTENT_DEFAULT_KERNEL29=YES
NEXT_ENTRY_SELECTS_OTHER_KERNEL=NO
NEXT_REBOOT_KERNEL_PROVEN=7.0.0-29-generic
KERNEL_CHANGES_DURING_TASK=0
GRUB_WRITES=0
KERNEL_AND_BOOT_SELECTION_GATE=PASS
```

The passing read-only preflight inspected the active kernel, command line,
module tree, exact pinned-module vermagic, `/etc/default/grub`, GRUB environment,
and the selected `grub.cfg` menuentry. The persistent selected entry names and
boots `/boot/vmlinuz-7.0.0-29-generic`; no one-shot `next_entry` selects another
kernel. No kernel or bootloader state was changed.
