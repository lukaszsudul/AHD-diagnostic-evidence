
# Cleanup receipt

No hardware resource was acquired. No DUT helper, AIO context, driver, XDMA
node, controller lock, or Linux lock was created. There was therefore no live
hardware state to clean up. Prior state remained Owner-attested: stream
disabled, no active DMA, driver unloaded, nodes absent, locks released.
