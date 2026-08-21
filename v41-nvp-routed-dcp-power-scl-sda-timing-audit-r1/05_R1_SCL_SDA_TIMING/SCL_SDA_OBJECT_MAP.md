# SCL/SDA Object Map

Connectivity-first discovery proved exactly one decomposed input buffer (`IBUF`) and one decomposed open-drain output buffer (`OBUFT`) at each top-level port. The logical IOBUF's data input is constant zero and the output-enable path terminates at `OBUFT/T`.

| Line | Port | IBUF leaf | OBUFT leaf | OEN register | Sync0 | Sync1 | Filtered register |
|---|---|---|---|---|---|---|---|
| SCL | `nvp_scl` | `NVP_SCL_IOBUF/IBUF` | `NVP_SCL_IOBUF/OBUFT` | `NVP_AUTOINIT/u_sequence/scl_oen_r_reg` | `scl_sync_r_reg[0]` | `scl_sync_r_reg[1]` | `scl_filtered_r_reg` |
| SDA | `nvp_sda` | `NVP_SDA_IOBUF/IBUF` | `NVP_SDA_IOBUF/OBUFT` | `NVP_AUTOINIT/u_sequence/sda_oen_r_reg` | `sda_sync_r_reg[0]` | `sda_sync_r_reg[1]` | `sda_filtered_r_reg` |

The raw IBUF output feeds the intended first synchronizer stage. In R1 it also reaches observer/read-only diagnostic plumbing outside `NVP_AUTOINIT/u_sequence`; these endpoints are explicitly accounted and are not protocol-decision fanout. Protocol decisions consume synchronized/filtered signals. Both synchronizer stages retain `ASYNC_REG=TRUE` and `SHREG_EXTRACT=NO`.