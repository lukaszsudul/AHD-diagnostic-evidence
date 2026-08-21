param([Parameter(Mandatory=$true)][string]$FilePath,
      [Parameter(Mandatory=$true)][string[]]$ArgumentList,
      [Parameter(Mandatory=$true)][string]$EvidenceDirectory)
$sw=[System.Diagnostics.Stopwatch]::StartNew()
$psi=[System.Diagnostics.ProcessStartInfo]::new()
$psi.FileName=$FilePath; $psi.UseShellExecute=$false
$psi.RedirectStandardOutput=$true; $psi.RedirectStandardError=$true
foreach($a in $ArgumentList){[void]$psi.ArgumentList.Add($a)}
$p=[System.Diagnostics.Process]::new(); $p.StartInfo=$psi
$marker=$null; $stdout=[Collections.Generic.List[string]]::new()
try {
  if(-not $p.Start()){throw 'process start failed'}
  while(-not $p.StandardOutput.EndOfStream){
    $line=$p.StandardOutput.ReadLine(); $stdout.Add($line)
    if($null -eq $marker -and $line.StartsWith('R1_PROGRAM_RETURN_MARKER=')){$marker=$sw.ElapsedTicks}
  }
  $stderr=$p.StandardError.ReadToEnd(); $p.WaitForExit(); $exitTicks=$sw.ElapsedTicks
  if($null -eq $marker){throw 'unique program-return marker not observed'}
  New-Item -ItemType Directory -Force -Path $EvidenceDirectory|Out-Null
  $stdout|Set-Content -Encoding utf8 (Join-Path $EvidenceDirectory 'program_stdout.log')
  $stderr|Set-Content -Encoding utf8 (Join-Path $EvidenceDirectory 'program_stderr.log')
  @("STOPWATCH_FREQUENCY=$([Diagnostics.Stopwatch]::Frequency)","R1_PROGRAM_RETURN_MARKER_STOPWATCH_TICKS=$marker","R1_PROGRAM_PROCESS_EXIT_STOPWATCH_TICKS=$exitTicks","PROCESS_EXIT_CODE=$($p.ExitCode)")|Set-Content -Encoding ascii (Join-Path $EvidenceDirectory 'program_reference.txt')
  if($p.ExitCode -ne 0){exit $p.ExitCode}
} finally { if(-not $p.HasExited){$p.Kill($true)}; $p.Dispose() }
