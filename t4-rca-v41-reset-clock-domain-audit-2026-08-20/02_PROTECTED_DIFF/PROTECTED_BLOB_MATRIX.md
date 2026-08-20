# Protected blob matrix

All four protected paths resolve to their expected Git blob in all three exact commits. No contradiction was found.

path | expected_blob | rca_blob | v41_phase2_blob | v41_phase3_blob | result
"rtl/nvp/nvp6134c_autoinit.vhd" | 5dc0230cd569f03d68452055db6b10c5fcade751 | 5dc0230cd569f03d68452055db6b10c5fcade751 | 5dc0230cd569f03d68452055db6b10c5fcade751 | 5dc0230cd569f03d68452055db6b10c5fcade751 | MATCH
"rtl/nvp/nvp6134c_i2c_bringup.vhd" | cfe33464d8e75c514462786593b278d90b4059a4 | cfe33464d8e75c514462786593b278d90b4059a4 | cfe33464d8e75c514462786593b278d90b4059a4 | cfe33464d8e75c514462786593b278d90b4059a4 | MATCH
"rtl/nvp/nvp6134c_diagnostics_pkg.vhd" | 7ddd60fc86da49cda1adcd7af7b772b337c95df6 | 7ddd60fc86da49cda1adcd7af7b772b337c95df6 | 7ddd60fc86da49cda1adcd7af7b772b337c95df6 | 7ddd60fc86da49cda1adcd7af7b772b337c95df6 | MATCH
"xdc/boards/current/nvp_control.xdc" | 2e4a6f56d5dfa227a968492fe4476d25721f09f9 | 2e4a6f56d5dfa227a968492fe4476d25721f09f9 | 2e4a6f56d5dfa227a968492fe4476d25721f09f9 | 2e4a6f56d5dfa227a968492fe4476d25721f09f9 | MATCH
