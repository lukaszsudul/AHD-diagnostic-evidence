# Read-only G2A evidence helper: dump all effective CONFIG.* values from the
# primary-donor-identical frozen XDMA XCI in a clean, isolated Vivado project.
if {$argc != 4} {
  puts stderr "usage: dump_frozen_donor_effective_config.tcl DONOR_ROOT WORK_ROOT OUTPUT_PATH EXPECTED_XCI_BLOB"
  exit 2
}

lassign $argv donor_root work_root output_path expected_xci_blob
set donor_root [file normalize $donor_root]
set work_root [file normalize $work_root]
set output_path [file normalize $output_path]
set xci_source [file join $donor_root ip v41 xdma_v41_m1.xci]
set expected_commit 8464af66611f7c22b8a36a4aab915d598eedda3f
set primary_donor_commit c89e88bcdf389614c884fb129e8b2d42a585bccb
set expected_blob 5065b919254fe164ac831192b93c29734737b859

if {$expected_xci_blob ne $expected_blob} {
  error "caller XDMA blob expectation does not match frozen value"
}
if {![file isfile $xci_source]} { error "frozen donor XCI missing: $xci_source" }
set actual_commit [string trim [exec git --no-optional-locks -C $donor_root rev-parse HEAD]]
set actual_blob [string trim [exec git --no-optional-locks -C $donor_root hash-object -- $xci_source]]
set primary_blob [string trim [exec git --no-optional-locks -C $donor_root rev-parse "${primary_donor_commit}:ip/v41/xdma_v41_m1.xci"]]
if {$actual_commit ne $expected_commit || $actual_blob ne $expected_blob || $primary_blob ne $expected_blob} {
  error "frozen donor identity mismatch: commit=$actual_commit working_blob=$actual_blob primary_blob=$primary_blob"
}
if {[file exists $work_root]} {
  set existing [glob -nocomplain -directory $work_root *]
  if {[llength $existing] != 0} { error "WORK_ROOT must be absent or empty" }
}
file mkdir $work_root
set xci_copy [file join $work_root xdma_v41_m1.xci]
file copy $xci_source $xci_copy

create_project g2a_frozen_donor_dump [file join $work_root project] -part xc7a35tcsg325-2
import_ip -files $xci_copy
set ip [get_ips -quiet xdma_v41_m1]
if {[llength $ip] != 1} { error "expected one frozen donor XDMA IP" }
generate_target all $ip

set fh [open $output_path w]
fconfigure $fh -encoding utf-8 -translation lf
puts $fh "# FROZEN_PRIMARY_DONOR_COMMIT=$primary_donor_commit"
puts $fh "# PROVENANCE_WORKTREE_COMMIT=$expected_commit"
puts $fh "# PRIMARY_AND_PROVENANCE_DONOR_XCI_BLOB=$expected_blob"
puts $fh "# VIVADO_VERSION=[version -short]"
foreach property [lsort [list_property $ip]] {
  if {[string match {CONFIG.*} $property]} {
    puts $fh "$property=[get_property $property $ip]"
  }
}
close $fh
puts "FROZEN_DONOR_EFFECTIVE_CONFIG_DUMP=PASS"
close_project
exit 0
