import fs from "node:fs/promises";
import path from "node:path";
import crypto from "node:crypto";
import { Workbook } from "file:///C:/Users/%C5%81ukasz%20Sudu%C5%82/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/@oai/artifact-tool/dist/artifact_tool.mjs";

const outputDirectory = process.argv[2];
if (!outputDirectory) throw new Error("usage: build_review_csvs.mjs <output-directory>");

const prior = String.raw`C:\AHD_R2_REVIEW_20260828\input_r2_evidence\v41-research-r2-r1i-causal-hardware-owner-mediated-continuation-halted-20260828`;
const workspace = String.raw`C:\Users\Łukasz Suduł\Documents\ChatGPT\AHD_20260807`;
const orchestratedRuns = path.join(workspace, "R2_OWNER_MEDIATED_CONTINUATION_STAGE", "R2_PRIMARY_CAMPAIGN_ORCHESTRATED_AFTER_R02", "runs");

const rawCapturePaths = [
  String.raw`C:\AHD_R2_OWNER_EXEC_20260828\primary\R01_C0\telemetry\EXTRACTED\RAW_CAPTURE_TRANSPORT.json`,
  String.raw`C:\AHD_R2_OWNER_EXEC_20260828\primary\R02_C1\telemetry\EXTRACTED\RAW_CAPTURE_TRANSPORT.json`,
  ...[
    "003_R2OM-R01-P3-C3", "004_R2OM-R01-P4-C2", "005_R2OM-R02-P1-C1",
    "006_R2OM-R02-P2-C2", "007_R2OM-R02-P3-C0", "008_R2OM-R02-P4-C3",
    "009_R2OM-R03-P1-C2", "010_R2OM-R03-P2-C3",
  ].map((name) => path.join(orchestratedRuns, name, "04_CANDIDATE_TELEMETRY", "output", "EXTRACTED", "RAW_CAPTURE_TRANSPORT.json")),
];

function parseCsv(text) {
  const rows = [];
  let row = [], field = "", quoted = false;
  for (let i = 0; i < text.length; i += 1) {
    const c = text[i];
    if (quoted) {
      if (c === '"' && text[i + 1] === '"') { field += '"'; i += 1; }
      else if (c === '"') quoted = false;
      else field += c;
    } else if (c === '"') quoted = true;
    else if (c === ',') { row.push(field); field = ""; }
    else if (c === '\n') { row.push(field.replace(/\r$/, "")); rows.push(row); row = []; field = ""; }
    else field += c;
  }
  if (field.length || row.length) { row.push(field.replace(/\r$/, "")); rows.push(row); }
  const headers = rows.shift();
  return rows.filter((r) => r.some((v) => v !== "")).map((r) => Object.fromEntries(headers.map((h, i) => [h, r[i] ?? ""])));
}

function csvEscape(value) {
  if (value === null || value === undefined) return "";
  const s = String(value);
  return /[",\r\n]/.test(s) ? `"${s.replaceAll('"', '""')}"` : s;
}

function toCsv(headers, rows) {
  return [headers, ...rows.map((row) => headers.map((h) => row[h]))]
    .map((row) => row.map(csvEscape).join(","))
    .join("\r\n") + "\r\n";
}

function sha256(buffer) {
  return crypto.createHash("sha256").update(buffer).digest("hex").toUpperCase();
}

function delta32(a, b) {
  return (b - a + 0x1_0000_0000) % 0x1_0000_0000;
}

function receiptMap(text) {
  const out = {};
  for (const line of text.split(/\r?\n/)) {
    const index = line.indexOf("=");
    if (index > 0) out[line.slice(0, index)] = line.slice(index + 1);
  }
  return out;
}

function hexWord(capture, offset) {
  return capture.words[`0x${offset.toString(16).toUpperCase().padStart(5, "0")}`];
}

function decimalWord(capture, offset) {
  return Number.parseInt(hexWord(capture, offset).slice(2), 16);
}

async function optionalSha(file) {
  try { return sha256(await fs.readFile(file)); }
  catch { return "NOT_AVAILABLE"; }
}

const rawResultRows = parseCsv(await fs.readFile(path.join(prior, "R2_RAW_RESULTS.csv"), "utf8"));
const completionRows = parseCsv(await fs.readFile(path.join(prior, "audit", "R2_PRIMARY_RUN_COMPLETIONS_APPEND_ONLY.csv"), "utf8"));
if (rawResultRows.length !== 10 || completionRows.length !== 10 || rawCapturePaths.length !== 10) {
  throw new Error("expected exactly ten immutable observations");
}

const recalculationRows = [];
const comparisonRows = [];
for (let i = 0; i < 10; i += 1) {
  const seq = i + 1;
  const result = rawResultRows[i];
  const completion = completionRows[i];
  const rawPath = rawCapturePaths[i];
  const rawBytes = await fs.readFile(rawPath);
  const raw = JSON.parse(rawBytes.toString("utf8"));
  const [t0, t1] = raw.raw_captures;
  const a = t0.video_counter_observations;
  const b = t1.video_counter_observations;
  const frameDelta = delta32(a.FRAME.value, b.FRAME.value);
  const vclkDelta = delta32(a.VCLK.value, b.VCLK.value);
  const savDelta = delta32(a.SAV.value, b.SAV.value);
  const frameElapsed = b.FRAME.monotonic_midpoint - a.FRAME.monotonic_midpoint;
  const vclkElapsed = b.VCLK.monotonic_midpoint - a.VCLK.monotonic_midpoint;
  const savElapsed = b.SAV.monotonic_midpoint - a.SAV.monotonic_midpoint;
  const frameRate = frameDelta / frameElapsed;
  const vclkRate = vclkDelta / vclkElapsed;
  const savRate = savDelta / savElapsed;
  const receiptFile = (await fs.readdir(path.join(prior, "audit", "run_capture_receipts")))
    .find((name) => name.startsWith(String(seq).padStart(3, "0") + "_"));
  const receipt = receiptMap(await fs.readFile(path.join(prior, "audit", "run_capture_receipts", receiptFile), "utf8"));
  const aggregateSha = sha256(rawBytes);
  const extractedDirectory = path.dirname(rawPath);
  const t0Sha = await optionalSha(path.join(extractedDirectory, "T0_RAW_CAPTURE.json"));
  const t1Sha = await optionalSha(path.join(extractedDirectory, "T1_RAW_CAPTURE.json"));
  const telemetryResultSha = await optionalSha(path.join(extractedDirectory, "TELEMETRY_RESULT.json"));
  const reported = Number(result.frame_rate_hz);
  const population = frameDelta === 0 ? "ZERO" : (frameDelta === 25 ? "A_25_EVENTS" : (frameDelta === 26 ? "B_26_EVENTS" : "OTHER"));
  const roundedIndependent = Number(frameRate.toFixed(6));
  const hashMatch = aggregateSha === receipt.RAW_CAPTURE_SHA256;
  if (!hashMatch) throw new Error(`raw aggregate hash mismatch for sequence ${seq}`);
  if (Math.abs(reported - roundedIndependent) > 0.0000005) throw new Error(`reported-rate mismatch for sequence ${seq}`);

  recalculationRows.push({
    sequence_index: seq,
    run_id: result.run_id,
    candidate: result.candidate,
    historical_classification: result.classification,
    population,
    aggregate_raw_capture_sha256: aggregateSha,
    receipt_raw_capture_sha256: receipt.RAW_CAPTURE_SHA256,
    aggregate_hash_receipt_match: hashMatch ? "YES" : "NO",
    t0_raw_capture_sha256: t0Sha,
    t1_raw_capture_sha256: t1Sha,
    telemetry_result_sha256: telemetryResultSha,
    frame_t0_value: a.FRAME.value,
    frame_t1_value: b.FRAME.value,
    frame_delta: frameDelta,
    frame_t0_monotonic_s: a.FRAME.monotonic_midpoint,
    frame_t1_monotonic_s: b.FRAME.monotonic_midpoint,
    actual_frame_elapsed_s: frameElapsed,
    reported_hz_6dp: result.frame_rate_hz,
    independently_calculated_hz: frameRate,
    reported_minus_independent_hz: reported - frameRate,
    rounded_value_match: roundedIndependent === reported ? "YES" : "NO",
    vclk_t0_value: a.VCLK.value,
    vclk_t1_value: b.VCLK.value,
    vclk_delta: vclkDelta,
    vclk_elapsed_s: vclkElapsed,
    vclk_hz: vclkRate,
    sav_t0_value: a.SAV.value,
    sav_t1_value: b.SAV.value,
    sav_delta: savDelta,
    sav_elapsed_s: savElapsed,
    sav_hz: savRate,
    sav_derived_frame_hz_1125_lines: savRate / 1125,
    recalculation_status: "PASS_EXACT_RAW_MONOTONIC_RECALCULATION",
    linked_raw_evidence_path: `audit/linked_raw_captures/${String(seq).padStart(3, "0")}_${result.run_id}_RAW_CAPTURE_TRANSPORT.json`,
  });

  comparisonRows.push({
    sequence_index: seq,
    run_id: result.run_id,
    candidate: result.candidate,
    historical_classification: result.classification,
    population,
    bitstream_sha256: result.bitstream_sha256,
    runtime_source_commit: result.runtime_source_commit,
    block_id: result.block_id,
    protocol: result.protocol,
    capabilities: result.capabilities,
    diagnostic_magic: result.diagnostic_magic,
    runtime_build_flags: result.runtime_build_flags,
    programming_result: result.programming_result,
    program_receipt_sha256: result.program_receipt_sha256,
    independent_done: result.independent_done,
    independent_done_receipt_sha256: result.independent_done_receipt_sha256,
    host_transition_receipt_sha256: result.host_transition_receipt_sha256,
    program_completed_utc: result.program_completed_utc,
    done_completed_utc: result.done_completed_utc,
    remote_capture_utc: result.remote_capture_utc,
    epoch: result.epoch,
    boot_id: result.boot_id,
    host: "VCDE-DUT-1",
    kernel: "7.0.0-29-generic",
    endpoint_identity: "10ee:7011 subsystem 10ee:0007 class 058000",
    pcie_link: "GEN1_X1",
    xdma_module_sha256: "1AEF06244DF308FEE544A2662B73855C81BEB88BC929E7885D8D113E474B320A",
    init_done: result.init_done,
    init_error: result.init_error,
    nvp_status_word: hexWord(t0, 0x8c),
    total_autoinit_nack: result.total_autoinit_nack,
    retry_count: result.retry_count,
    recovered_count: result.recovered_count,
    retry_exhausted: result.retry_exhausted,
    scl_timeout: result.scl_timeout,
    bad_marker_count: decimalWord(t0, 0x64),
    bad_length_count: decimalWord(t0, 0x68),
    overflow_count: decimalWord(t0, 0x6c),
    malformed_count: decimalWord(t0, 0x70),
    dropped_count: decimalWord(t0, 0x74),
    nvp_lock_state: "NOT_RECORDED",
    video_present: result.video_present,
    frame_delta: frameDelta,
    frame_elapsed_s: frameElapsed,
    frame_hz: frameRate,
    vclk_hz: vclkRate,
    sav_hz: savRate,
    sav_derived_frame_hz_1125_lines: savRate / 1125,
    formal_restore_pass: completion.safe_formal_baseline_restored,
    formal_receipt_sha256: completion.next_safe_baseline_receipt_sha256,
    candidate_capture_receipt_sha256: result.capture_receipt_sha256,
    aggregate_raw_capture_sha256: aggregateSha,
    independently_recorded_abnormality_beyond_frame: (seq === 10 ? "NO" : "NOT_APPLICABLE"),
  });
}

const recalcHeaders = Object.keys(recalculationRows[0]);
const comparisonHeaders = Object.keys(comparisonRows[0]);
const outputs = [
  ["R2_REVIEW_FRAME_RATE_RECALCULATION.csv", recalcHeaders, recalculationRows],
  ["R2_REVIEW_RUN_COMPARISON.csv", comparisonHeaders, comparisonRows],
];
await fs.mkdir(outputDirectory, { recursive: true });
const validation = [];
for (const [name, headers, rows] of outputs) {
  const csv = toCsv(headers, rows);
  const outputPath = path.join(outputDirectory, name);
  await fs.writeFile(outputPath, csv, "utf8");
  const workbook = await Workbook.fromCSV(csv, { sheetName: "Evidence" });
  const inspection = await workbook.inspect({ kind: "sheet,region", maxChars: 2000, tableMaxRows: 3, tableMaxCols: 8 });
  validation.push({ name, rows: rows.length, columns: headers.length, sha256: sha256(Buffer.from(csv, "utf8")), artifact_tool_inspection: inspection.ndjson });
}
await fs.writeFile(path.join(outputDirectory, "audit_artifact_tool_csv_validation.json"), JSON.stringify(validation, null, 2) + "\n", "utf8");
console.log(JSON.stringify(validation.map(({ name, rows, columns, sha256 }) => ({ name, rows, columns, sha256 })), null, 2));
