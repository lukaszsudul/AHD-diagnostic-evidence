from pathlib import Path
import re,subprocess
R=Path(__file__).parent; E=Path('C:/FPGA/V41_G2B_EVIDENCE')
t=(E/'v41-development-g2b-lut1-signoff-recovery/tools/g2b_lut1_routed_signoff_recovery.tcl').read_text()
names='write_lines_atomic write_text_atomic read_text safe_value csv_value sha256_file property_or_unknown property_is_true seconds_since unique_objects_by_name collection_names route_signature routed_worst_slack check_timing_table_count utilization_row cdc1_family enforce_exact_cdc_disposition run_timing_gate'.split()
chunks=re.split(r'(?=^proc )',t,flags=re.M)
selected=[c for c in chunks if c.startswith('proc ') and c.split()[1] in names]
assert len(selected)==len(names)
(R/'helpers.tcl').write_text('\n'.join(selected)+'\nproc begin_phase {name seconds} {phase $name $seconds}\n')
contract='v41-development-g2b-pre-c2h-abi-mmio-freeze/V41_C2H_TRANSPORT_ABI_V1.json'
b=subprocess.check_output(['git','-C',str(E),'show','HEAD:'+contract]); (R/'V41_C2H_TRANSPORT_ABI_V1.json').write_bytes(b)
print('Extracted inert helper procedures; retrieved tracked frozen ABI JSON')
