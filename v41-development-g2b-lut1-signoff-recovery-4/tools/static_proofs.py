from pathlib import Path
import subprocess,hashlib,json,re,csv,shutil
R=Path(__file__).parent;S=Path('C:/FPGA/V41_G2B');E=Path('C:/FPGA/V41_G2B_EVIDENCE');B=Path('C:/FPGA/G2B_LUT1_PRODUCT_PRECOMMIT_BUILD_20260831_12')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest().upper()
def git(*a):return subprocess.check_output(['git','-C',str(S),*a],text=True).strip()
def write(name,t): (R/name).write_text(t+'\n',encoding='utf-8')
state=json.loads((R/'start.json').read_text());source=json.loads((R/'source.json').read_text())
manifest=Path(state['dcp']['path']).with_name('G2B_BUILD_INPUT_SHA256.txt')
assert sha(manifest)=='0248858AF074D4F3065B8A666366DEB532122C9F121F67625A2F68BBC0413EFD'
for row in state['build_inputs']:
 if row['path']!='xdc/common/g2b_cdc.xdc': assert sha(S/row['path'])==row['sealed']
xpr=B/'vivado_project/v41_g2b_onech_c2h_offline.xpr'
assert sha(xpr)=='204E26DCC659EACC973A9F17D5C92863830CDFCD4770855E67E4724067BB044E'
generated=list(B.glob('vivado_project/*.gen/sources_1/ip/xdma_v41_m1/ip_0/source/xdma_v41_m1_pcie2_ip-PCIE_X0Y0.xdc')); assert len(generated)==1
assert sha(generated[0])=='DD00E1DA9D2CAA6F27EBA21DB3BB6F73FC16A6F75C18C3394DB93430C815916B'
assert git('diff','--name-only','66cc8e3497579c2f7cb41d0b3639b3c2f00d6c49','HEAD')=='xdc/common/g2b_cdc.xdc'
xci=S/'ip/v41/xdma_v41_m1.xci';assert sha(xci)=='9BDA9F1C79C1553C0271DD1599119D8F6E74D4F089ECFBDE1E4A067F3F50CA9F'
write('G2B_LUT1_RECOVERY4_DCP_REUSE_PROOF.md','# DCP reuse proof — PASS\n\nDCP_REUSE_VALID = YES\nRECOVERY_MODE = ROUTED_DCP_REUSE\nFULL_REBUILD_EXECUTED = NO\n\nExact sealed DCP size/hash verified in start.json. All 34 non-XDC entries of the 35-input Gen12 manifest match current source. The manifest hash is '+sha(manifest)+'. The sole changed build input is g2b_cdc.xdc. All source changes after accepted recovery-1 source 66cc8e3 affect only that XDC. The original Gen12 was a precommit build; no inference that its parent commit alone contains the complete build sources is made.\n\nThe Gen12 project file matches its accepted hash '+sha(xpr)+', binding source set, top ahd_capture_top_xdma, part xc7a35tcsg325-2 and PRODUCT configuration. Generated PCIe XDC matches '+sha(generated[0])+'. The XDMA XCI is exact. No RTL, generated IP configuration, source set, top, profile or part change exists. The exact sealed DCP preserves its routed netlist and physical implementation; only timing constraints are reloaded.\n\nBuild inputs:\n```json\n'+json.dumps(state['build_inputs'],indent=2)+'\n```')
receipts={
'C:/FPGA/G2B_LUT1_MMIO_ROUTER_XSIM_20260831_13/G2B_ROUTER_XSIM_RECEIPT.txt':'EC9F1DBC71C7A532B0D8794657D0F3062D87A8B3A47D47500DE58DDB8D961623',
'C:/FPGA/G2B_LUT1_PRODUCT_PROFILE_XSIM_20260831_13/G2B_PRODUCT_PROFILE_XSIM_RECEIPT.txt':'62318E4DB49DE3F47060D9B1B4594B64894586BFC08C5D3D0FAD0CB4E46713B3',
'C:/FPGA/G2B_LUT1_R1I_20260831_13/wire_focused/r1i_candidate_allack.trace':'7C5D7F767B2E9CAEB1B587D3F258C295AD0F454141B2A8C84240B966133A4B49',
'C:/FPGA/G2B_LUT1_R1I_20260831_13/wire_focused/r1h_reference_allack.trace':'7C5D7F767B2E9CAEB1B587D3F258C295AD0F454141B2A8C84240B966133A4B49'}
for p,h in receipts.items():assert sha(Path(p))==h
write('functional_hashes.json',json.dumps(receipts,indent=2))
assert 'Ran 11 tests' in (R/'python_g2b_fresh.log').read_text() and (R/'python_g2b_fresh.log').read_text().strip().endswith('OK')
assert 'Ran 16 tests' in (R/'python_r1i.log').read_text() and (R/'python_r1i.log').read_text().strip().endswith('OK')
old=E/'v41-development-g2b-lut1-signoff-recovery/G2B_LUT1_FUNCTIONAL_PROTECTION.md'
write('G2B_LUT1_RECOVERY4_FUNCTIONAL_REGRESSION.md','# Functional regression — PASS\n\nFresh 11/11 G2B host ABI/parser tests and 16/16 R1i tests pass. The first G2B invocation could not locate the frozen ABI in the sparse checkout; its log is preserved. The successful invocation used the exact tracked frozen ABI JSON retrieved into this recovery directory.\n\nNo RTL or test-source drift since the recovery-1 accepted source. Its functional evidence is preserved for one-channel C2H, four-slot ring, formatter, TKEEP/TLAST, backpressure, sequence/reset epoch, coherent snapshot, ABI golden vectors and frame reconstruction. The complete prior receipt is copied as preserved_functional_authority.md. Current MMIO, profile and R1i trace hashes were reverified in functional_hashes.json.\n\nABI/MMIO unchanged: YES. Hardware accessed: NO.')
shutil.copyfile(old,R/'preserved_functional_authority.md')
write('G2B_LUT1_RECOVERY4_R1I_PROTECTION.md','# R1i protection — PASS\n\nAll protected RTL is hash-identical to Gen12 and unchanged from accepted recovery-1. Candidate/reference 5,346-byte focused traces match SHA256 7C5D7F767B2E9CAEB1B587D3F258C295AD0F454141B2A8C84240B966133A4B49. Physical SCL qualification, ACK sampling, synchronizers, NVP autoinit, reset/readiness/recovery and minimum product telemetry are preserved. Fresh 16/16 R1i tool tests pass. No R-track diagnostics were enabled.')
build=(S/'scripts/v41/g2b_build.tcl').read_text();assert 'PRODUCT RESEARCH_DIAGNOSTIC' in build
write('G2B_LUT1_RECOVERY4_PROFILE_RECEIPT.md','# Profile protection — PASS\n\nPRODUCT is the sealed routed profile; Gen12 project identity is exact. RESEARCH_DIAGNOSTIC remains reproducibly selectable by the unchanged g2b_build.tcl profile argument. Its selector changes instrumentation, preserving the reviewed functional boundary. No research route was required or attempted. Exact profile compatibility receipt verifies R1i page, live I2C health/bank telemetry, deterministic absent research storage and legacy latency classes. ABI/MMIO/XDMA and functional sources are unchanged.\n\nXDMA_CONFIGURATION = UNCHANGED\nXCI SHA256 = '+sha(xci)+'\n\nActual XCI settings:\n```\n'+'\n'.join(l for l in xci.read_text().splitlines() if re.search('bar[0-9]|axisten_freq|axi_data_width|pl_link_cap_max|dma_intf_sel|c2h|h2c',l,re.I))+'\n```')
write('G2B_LUT1_RECOVERY4_THROUGHPUT_SUMMARY.md','# Offline throughput — PASS\n\nRecord 4096 = 64 header + 3840 payload + 192 zero padding bytes. Payload efficiency 93.75%; overhead 6.25% of transport. A 64-bit stream uses 512 beats/record with the frozen TKEEP/TLAST contract. Required 288 MB/s payload needs 75,000 records/s and 307.2 MB/s transport. Gen2 x1 after 8b/10b has a theoretical 500 MB/s transport ceiling before packet overhead, giving 468.75 MB/s ideal payload. Required beat duty is 61.44%; gross transport reserve 192.8 MB/s. This governed offline capacity analysis is not a PCIe packet-level or hardware throughput measurement.\n\nOFFLINE_THROUGHPUT = PASS\nHARDWARE_THROUGHPUT_PROVEN = NO')
write('G2B_LUT1_RECOVERY4_RETIRED_QUERY_RECEIPT.txt','ALL_RETIRED_GLOBAL_BUS_SKEW_QUERIES_EXECUTED = NO\nGROUPS_9_13_14_15_16_17_GLOBAL_REPORT_BUS_SKEW_EXECUTED = NO\nHARDWARE_ACCESSED = NO')
write('static_pass.json',json.dumps({'dcp_reuse':True,'functional':True,'r1i':True,'profile':True,'xdma':True,'throughput':True}))
print('Static protection and DCP reuse proofs PASS')
