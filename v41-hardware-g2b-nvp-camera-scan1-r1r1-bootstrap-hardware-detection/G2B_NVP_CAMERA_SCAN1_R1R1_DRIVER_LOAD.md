
# Driver load and unload

- Load gate: `PASS`; exact module `xdma_ahd_pcie`
- Module SHA-256: `E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77`
- PCI alias: `pci:v000010EEd00007011sv000010EEsd00000007bc*sc*i*`
- Bound endpoints: `0000:01:00.0` only
- PCI identity: `10ee:7011`, subsystem `10ee:0007`, `Gen2 x1`
- Load attempts: `1`
- Normal unload command: exactly `sudo rmmod xdma_ahd_pcie`, one attempt, no force
- Final module state: absent; XDMA nodes absent; endpoint unbound

The driver binary is not included.
