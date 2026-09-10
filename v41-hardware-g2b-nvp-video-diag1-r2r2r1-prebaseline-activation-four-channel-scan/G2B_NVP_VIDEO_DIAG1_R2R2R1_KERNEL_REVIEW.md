# Bounded PCIe/AER/kernel review

PCIE_AER_KERNEL_HEALTH = FAIL

The bounded log did not expose an explicit AER fatal row, IOMMU fault, DMA-API
error, Oops, BUG, panic, or use-after-free. It did expose a fresh kernel
initialization interval immediately after the bounded MMIO read hung, and the
previously loaded module was then absent without task-issued `rmmod`. This
unexpected restart is independently disqualifying. No boot-ID comparison was
performed.
