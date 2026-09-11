
# Private-bank mapping authority

Mapping is PASS:

- PDF page 88 places the per-channel format classifier at Banks 5, 6, 7, and 8, register 0xF0.
- `c_v38ek_format_bank(idx)` at `nvp6134c_diagnostics_pkg.vhd:552-563` maps zero-based indices 0,1,2,3 to Banks 5,6,7,8.
- `nvp6134c_i2c_bringup.vhd:1096-1106` applies that mapping in a four-entry loop and reads 0xF0.

Therefore CH1->Bank5, CH2->Bank6, CH3->Bank7, CH4->Bank8 is proven for the project. This mapping proof does not establish undocumented equivalence of every private register.
