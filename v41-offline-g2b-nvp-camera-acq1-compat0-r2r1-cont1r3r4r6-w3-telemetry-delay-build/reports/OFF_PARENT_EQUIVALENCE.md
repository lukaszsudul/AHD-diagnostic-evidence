# W3 default-OFF equivalence to pinned parent

The guarded `simulation/delay-final3/receipt.json` records `PASS W3_OFF_PARENT_EDGE_EQUIVALENCE`: all **105** accepted scanner commands and the full resolved SCL/SDA edge trace match the pinned W1 parent. The companion comparison covers all **104** adjacent command gaps; the 21 selected W1 transaction boundaries agree as a subset. OFF produced 82 valid entries, 10 group selects and no SCL stretch in this clean offline simulation.

The `W3_DELAY_TIMING` receipt and raw `simulation/delay-final3/W3_DELAY_GAPS.csv` show eleven successful bank writes with 18,750 cycles added in ON and 93 unchanged gaps; the derived `DELAY_TIMING_PROOF.csv` records the named boundaries. Five paired negative pin cases separately show no new pause on a failed select, and a pause after a successful cleanup restore. These are digital observations, not measured physical I2C recovery or timing margin.

Guarded OFF log SHA-256: `EAA80317F082A3F58D8AC60F9B51FE15CE6F2C4CC497B81A74C74BCCBB33F30E`.
Guarded ON log SHA-256: `F5C2BA4395B413C21C63DE27DC4BEF226BAF82F9A81F04F3296012A3DA5C415A`.
Raw gap CSV SHA-256: `F30732073C9706D93E69FB0536B3BB9C8ED8F83B9190F237D9D8E9C0BD6CD745`.
