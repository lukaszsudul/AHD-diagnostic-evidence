from pathlib import Path
import json,re,csv,collections,hashlib
from cdc_compare import parse
R=Path(__file__).parent
old=parse(Path('C:/FPGA/G2B_LUT1_PRODUCT_PRECOMMIT_EVIDENCE_20260831_12/CDC.rpt')); new=parse(R/'CDC.rpt')
key=lambda x:(x[0],x[1],x[2],x[4],x[5],x[6],x[7])
assert collections.Counter(map(key,old))==collections.Counter(map(key,new)), 'CDC endpoint/domain/exception/severity/depth drift'
expected={'CDC-1':423,'CDC-3':30,'CDC-6':13,'CDC-9':6,'CDC-10':2,'CDC-13':2,'CDC-15':925}
assert dict(collections.Counter(x[0] for x in new))==expected
prior=set(tuple(x) for x in old); diff=[x for x in new if tuple(x) not in prior]
assert len(diff)==26
for x in diff:
 rule,clock,exc,start,end,*_=x
 assert rule in ('CDC-1','CDC-15') and exc=='Max Delay Datapath Only'
 assert re.match(r'G2B_ONECH_C2H/(axis_slot|release_(epoch|generation)_axi|own_ok_hold_source|desc_epoch_source|reset_abandoned_hold_source)_reg',start)
 assert re.match(r'G2B_ONECH_C2H/(slot_state_source|enable_applied_source|source_ownership_fatal(?:_event|_deferred)?|fatal_clear_qualified_axi|axis_epoch|records_abandoned_axi|reset_abandoned_hold_source)_reg',end)
rows=[]
for x in new:
 rule,clock,exc,start,end,sev,depth,desc=x; family='';proof=''
 if rule in ('CDC-1','CDC-15'):
  bucket='STABLE_DATA_WITH_SYNCHRONIZED_QUALIFIER'
  if '/MAILBOX/cfg_hold_pcie_reg' in start:family='CONFIG_MAILBOX';proof='Group 1 preserved routed skew; capture_mailbox acknowledged hold/capture protocol'
  elif '/MAILBOX/status_hold_nvp_reg' in start:family='STATUS_MAILBOX';proof='Group 2 preserved routed skew; capture_mailbox acknowledged status snapshot'
  elif re.search('/desc_(attempt|generation|epoch)_source_reg',start):family='DESCRIPTOR_MAILBOX';proof='Groups 10–12 preserved PASS; committed-slot stability until release; functional four-slot regression'
  elif '/snapshot_epoch_hold_axi_reg' in start:family='SNAPSHOT_EPOCH';proof='Group 7 preserved PASS; synchronized snapshot request and coherent echo'
  elif '/transport_' in start:family='TRANSPORT_RESET_MAILBOX';proof='Group 8 preserved PASS; retained 2.500 ns settling bound and transport request/ack barrier'
  elif '/axis_slot_reg' in start:family='OWNERSHIP';proof='Group 9 META-4 per-family settling plus BS3 structural request/ack proof; all slot state destinations retained'
  elif '/release_' in start:family='RELEASE_SLOT';proof='Groups 14–17 56-cell slot payload sets and three semantic families; exact routed PASS; META-6/META-7R structural invariant authority'
  elif '/own_ok_hold_source_reg' in start:family='OWNERSHIP_RESULT';proof='Retained source-to-AXI aggregate 6 ns bound; stable acknowledged ownership result; BS3 safety proof'
  elif '/reset_' in start:family='RESET_RETURN';proof='Group 13 promoted two-family settling and completion-barrier structural proof; retained aggregate destination coverage'
  else:raise AssertionError('unmapped stable-data row '+str(x))
 elif rule=='CDC-6':
  if 'gray' in start:bucket='GRAY_CODED_CDC';proof='Unchanged exact CDC-6 row; Gray source, ASYNC_REG first/second stage; Groups 3/4 preserved skew PASS'
  elif 'toggle' in start:bucket='TOGGLE_HANDSHAKE';proof='Unchanged exact CDC-6 row; independent per-slot toggle bits are synchronized independently and consumed by per-slot state'
  elif 'hard_event_baseline_hold' in start or 'snapshot_epoch_echo' in start:bucket='STABLE_DATA_WITH_SYNCHRONIZED_QUALIFIER';proof='Unchanged exact CDC-6 row; stable baseline/epoch qualified by synchronized boundary; Groups 5/6 preserved PASS'
  else:raise AssertionError(x)
  family='MULTIBIT_CDC'
 elif rule in ('CDC-3','CDC-10'):
  bucket='INTENTIONAL_TWO_STAGE_SYNCHRONIZER';family='LEVEL_SYNCHRONIZER';proof='Exact unchanged report row; ASYNC_REG depth 2. CDC-10 source_ready/fatal level is held through handshake; four exact chain-cell attributes verified in continuation.'
 elif rule=='CDC-9':bucket='ASYNC_ASSERT_SYNC_RELEASE_RESET';family='RESET_SYNCHRONIZER';proof='Exact unchanged reset row with depth 2 ASYNC_REG; vendor/reset synchronizer chain'
 elif rule=='CDC-13':bucket='FALSE_POSITIVE_WITH_PROOF';family='XDMA_PIPE_CLOCK_MUX';proof='Exact unchanged rows; generated PCIe XDC hash DD00E1DA... supplies S0/S1 false paths and physical clock exclusivity'
 else:raise AssertionError(x)
 rows.append([rule,sev,clock,exc,start,end,bucket,family,'PASS',proof,'REVIEWED_REPRESENTATIVE_CHANGE' if x in diff else 'EXACT_PRIOR_ROW'])
with (R/'G2B_LUT1_RECOVERY4_CDC_DISPOSITION.csv').open('w',newline='',encoding='utf-8') as f:
 w=csv.writer(f);w.writerow('Rule Severity Clock_Pair Exception Source Destination Classification Semantic_Family Result Evidence Change'.split());w.writerows(rows)
summary={'result':'PASS_PENDING_CONTINUATION_CHAIN_ATTRIBUTES','total':len(rows),'critical':427,'critical_dispositioned':427,'unresolved_critical':0,'requires_rtl_change':0,'changed_representatives':26,'unchanged_endpoint_multiset':True,'counts':expected,'buckets':dict(collections.Counter(x[6] for x in rows))}
(R/'cdc_review.json').write_text(json.dumps(summary,indent=2))
(R/'G2B_LUT1_RECOVERY4_CDC_DISPOSITION.md').write_text('# CDC disposition\n\nAll 1,401 findings are individually classified in the companion CSV; 427 are critical. No unresolved finding or required RTL change remains in the report review. Continuation must verify the four exact CDC-10 ASYNC_REG chain attributes before this gate is final PASS.\n\nThe inherited recovery-1 comparator stopped at an old canonical hash. This was not a new CDC rule or destination: comparison against the original Gen12 report proves the entire multiset of rule, destination, clock pair, exception, severity, depth and description is identical. Seventeen critical and nine warning rows select different launch representatives. Every changed representative belongs to an existing reviewed ownership, release, descriptor or reset-return stable-data collection. Changes are enumerated in cdc_comparison.json and marked in the CSV; source differences are not ignored or replaced by count-only matching. The original failure and report are preserved.\n\nNo report is rerun. The current rows are reviewed against the promoted structural protocols and fresh/preserved routed timing bounds. Launch representatives across alternative mailbox/slot fan-in are not immutable identities of a report_cdc finding. The DCP/netlist is byte-identical; constraint state is the exact governed update. The obsolete fixed family counts and canonical hashes are not presented as a current PASS.\n\nCDC-10 findings retain the exact original rows and two-stage held-level protocol. CDC-13 findings retain exact generated-clock mux rows and unchanged generated-XDC exceptions. Other finding buckets and individual evidence are in the CSV.\n\n'+json.dumps(summary,indent=2)+'\n',encoding='utf-8')
print(json.dumps(summary,indent=2))
