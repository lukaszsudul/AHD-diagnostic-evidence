# Active XDC scope audit — PASS

Only the three global release-slot 1–3 set_bus_skew commands are removed; the authoritative combined candidate is appended byte-for-byte. All other original bytes remain unchanged. Groups 1–8, 9, 10–12, 13 and 14, clocks, unrelated false paths and max delays, ABI/MMIO and R1i constraints are unchanged.

The fresh routed scope audit resolves nine checks: 56 source cells each and 3/4/3 destination cells per slot. The exported complete timing context retains exactly eleven current BUS_SKEW commands and no release-slot global relation. See scope_resolved.csv and proposed_resolved.xdc.

Complete context reconstruction preserves base lines 1–54 and 85 onward and replaces exactly its G2B block (lines 55–84) with the proposed complete active g2b_cdc.xdc; all non-G2B timing commands remain byte-equivalent after newline normalization.

```diff
--- original
+++ proposed
@@ -180,15 +180,12 @@
 set g2b_release1_generation_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/release_generation_axi_reg\[1\].*}] {IS_SEQUENTIAL == 1}]
 set g2b_release1_epoch_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/release_epoch_axi_reg\[1\].*}] {IS_SEQUENTIAL == 1}]
 set g2b_release1_payload_src "$g2b_release1_generation_src $g2b_release1_epoch_src"
-set_bus_skew 3.000 -from $g2b_release1_payload_src -to $g2b_release_payload_dst
 set g2b_release2_generation_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/release_generation_axi_reg\[2\].*}] {IS_SEQUENTIAL == 1}]
 set g2b_release2_epoch_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/release_epoch_axi_reg\[2\].*}] {IS_SEQUENTIAL == 1}]
 set g2b_release2_payload_src "$g2b_release2_generation_src $g2b_release2_epoch_src"
-set_bus_skew 3.000 -from $g2b_release2_payload_src -to $g2b_release_payload_dst
 set g2b_release3_generation_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/release_generation_axi_reg\[3\].*}] {IS_SEQUENTIAL == 1}]
 set g2b_release3_epoch_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/release_epoch_axi_reg\[3\].*}] {IS_SEQUENTIAL == 1}]
 set g2b_release3_payload_src "$g2b_release3_generation_src $g2b_release3_epoch_src"
-set_bus_skew 3.000 -from $g2b_release3_payload_src -to $g2b_release_payload_dst
 
 set g2b_source_mailbox_src_candidates [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(desc_attempt_source|desc_generation_source|desc_epoch_source|reset_abandoned_hold_source|reset_commit_phase_hold_source|own_ok_hold_source)_reg.*}]
 # Keep only real sequential launch elements.  Synthesized descriptor arrays
@@ -244,3 +241,92 @@
 set g2b_hard_baseline_d [get_pins -quiet -of_objects $g2b_hard_baseline_dst -filter {REF_PIN_NAME == D}]
 set_max_delay -datapath_only 6.000 -from $g2b_hard_baseline_src -to $g2b_hard_baseline_d
 set_bus_skew 3.000 -from $g2b_hard_baseline_src -to $g2b_hard_baseline_d
+
+# AHD v41 G2B-G15-17-EQ temporary combined analysis candidate.
+# Replaces only Groups 15, 16, and 17 after structural/semantic equivalence
+# checks in the bounded audit harness have passed. Group 14 remains unchanged.
+# Each 56-bit stable release token is constrained to its three real semantic-use
+# families with the governed 6.000 ns absolute settling cap.
+
+current_instance -quiet
+
+set g2b_g15eq_release_generation_src [filter \
+    [get_cells -quiet -hier -regexp \
+      {.*G2B_ONECH_C2H/release_generation_axi_reg\[1\].*}] \
+    {IS_SEQUENTIAL == 1}]
+set g2b_g15eq_release_epoch_src [filter \
+    [get_cells -quiet -hier -regexp \
+      {.*G2B_ONECH_C2H/release_epoch_axi_reg\[1\].*}] \
+    {IS_SEQUENTIAL == 1}]
+set g2b_g15eq_release_payload_src \
+    "$g2b_g15eq_release_generation_src $g2b_g15eq_release_epoch_src"
+set g2b_g15eq_release_state_dst_cells [filter \
+    [get_cells -quiet -hier -regexp \
+      {.*G2B_ONECH_C2H/slot_state_source_reg\[1\].*}] \
+    {IS_SEQUENTIAL == 1}]
+set g2b_g15eq_release_fault_dst_cells [filter \
+    [get_cells -quiet -hier -regexp \
+      {.*G2B_ONECH_C2H/(source_ownership_fatal|source_ownership_fatal_event|source_ownership_fatal_deferred|enable_applied_source)_reg.*}] \
+    {IS_SEQUENTIAL == 1}]
+set g2b_g15eq_release_reset_dst_cells [filter \
+    [get_cells -quiet -hier -regexp \
+      {.*G2B_ONECH_C2H/reset_abandoned_hold_source_reg.*}] \
+    {IS_SEQUENTIAL == 1}]
+
+set_max_delay -datapath_only 6.000 -from $g2b_g15eq_release_payload_src -to $g2b_g15eq_release_state_dst_cells
+set_max_delay -datapath_only 6.000 -from $g2b_g15eq_release_payload_src -to $g2b_g15eq_release_fault_dst_cells
+set_max_delay -datapath_only 6.000 -from $g2b_g15eq_release_payload_src -to $g2b_g15eq_release_reset_dst_cells
+
+set g2b_g16eq_release_generation_src [filter \
+    [get_cells -quiet -hier -regexp \
+      {.*G2B_ONECH_C2H/release_generation_axi_reg\[2\].*}] \
+    {IS_SEQUENTIAL == 1}]
+set g2b_g16eq_release_epoch_src [filter \
+    [get_cells -quiet -hier -regexp \
+      {.*G2B_ONECH_C2H/release_epoch_axi_reg\[2\].*}] \
+    {IS_SEQUENTIAL == 1}]
+set g2b_g16eq_release_payload_src \
+    "$g2b_g16eq_release_generation_src $g2b_g16eq_release_epoch_src"
+set g2b_g16eq_release_state_dst_cells [filter \
+    [get_cells -quiet -hier -regexp \
+      {.*G2B_ONECH_C2H/slot_state_source_reg\[2\].*}] \
+    {IS_SEQUENTIAL == 1}]
+set g2b_g16eq_release_fault_dst_cells [filter \
+    [get_cells -quiet -hier -regexp \
+      {.*G2B_ONECH_C2H/(source_ownership_fatal|source_ownership_fatal_event|source_ownership_fatal_deferred|enable_applied_source)_reg.*}] \
+    {IS_SEQUENTIAL == 1}]
+set g2b_g16eq_release_reset_dst_cells [filter \
+    [get_cells -quiet -hier -regexp \
+      {.*G2B_ONECH_C2H/reset_abandoned_hold_source_reg.*}] \
+    {IS_SEQUENTIAL == 1}]
+
+set_max_delay -datapath_only 6.000 -from $g2b_g16eq_release_payload_src -to $g2b_g16eq_release_state_dst_cells
+set_max_delay -datapath_only 6.000 -from $g2b_g16eq_release_payload_src -to $g2b_g16eq_release_fault_dst_cells
+set_max_delay -datapath_only 6.000 -from $g2b_g16eq_release_payload_src -to $g2b_g16eq_release_reset_dst_cells
+
+set g2b_g17eq_release_generation_src [filter \
+    [get_cells -quiet -hier -regexp \
+      {.*G2B_ONECH_C2H/release_generation_axi_reg\[3\].*}] \
+    {IS_SEQUENTIAL == 1}]
+set g2b_g17eq_release_epoch_src [filter \
+    [get_cells -quiet -hier -regexp \
+      {.*G2B_ONECH_C2H/release_epoch_axi_reg\[3\].*}] \
+    {IS_SEQUENTIAL == 1}]
+set g2b_g17eq_release_payload_src \
+    "$g2b_g17eq_release_generation_src $g2b_g17eq_release_epoch_src"
+set g2b_g17eq_release_state_dst_cells [filter \
+    [get_cells -quiet -hier -regexp \
+      {.*G2B_ONECH_C2H/slot_state_source_reg\[3\].*}] \
+    {IS_SEQUENTIAL == 1}]
+set g2b_g17eq_release_fault_dst_cells [filter \
+    [get_cells -quiet -hier -regexp \
+      {.*G2B_ONECH_C2H/(source_ownership_fatal|source_ownership_fatal_event|source_ownership_fatal_deferred|enable_applied_source)_reg.*}] \
+    {IS_SEQUENTIAL == 1}]
+set g2b_g17eq_release_reset_dst_cells [filter \
+    [get_cells -quiet -hier -regexp \
+      {.*G2B_ONECH_C2H/reset_abandoned_hold_source_reg.*}] \
+    {IS_SEQUENTIAL == 1}]
+
+set_max_delay -datapath_only 6.000 -from $g2b_g17eq_release_payload_src -to $g2b_g17eq_release_state_dst_cells
+set_max_delay -datapath_only 6.000 -from $g2b_g17eq_release_payload_src -to $g2b_g17eq_release_fault_dst_cells
+set_max_delay -datapath_only 6.000 -from $g2b_g17eq_release_payload_src -to $g2b_g17eq_release_reset_dst_cells

```
