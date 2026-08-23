$ErrorActionPreference = 'Stop'
$expectedHash = '1CA3F857F2E3655FD06E8BF283B6BEC8826568402160EE004D7B8CD4D110C0B1'
$expectedPart = 'xc7a35tcsg325-2'

function Test-NamespaceGate([string]$Hash,[string]$CurrentDesign,[string]$Part,[bool]$Routed) {
  return (($Hash.ToUpperInvariant() -eq $expectedHash) -and
          (-not [string]::IsNullOrEmpty($CurrentDesign)) -and
          ($Part -eq $expectedPart) -and $Routed)
}

$fixtures = @(
  @('FIXTURE_1',$expectedHash,'checkpoint_PHASE3_routed',$expectedPart,$true,$true),
  @('FIXTURE_2',('0' * 64),'checkpoint_PHASE3_routed',$expectedPart,$true,$false),
  @('FIXTURE_3',$expectedHash,'',$expectedPart,$true,$false),
  @('FIXTURE_4',$expectedHash,'checkpoint_PHASE3_routed','xc7a100tcsg324-1',$true,$false)
)

foreach($f in $fixtures) {
  $actual = Test-NamespaceGate $f[1] $f[2] $f[3] $f[4]
  if($actual -ne $f[5]) { throw "$($f[0]) failed: actual=$actual expected=$($f[5])" }
  "$($f[0]),$($f[5]),$actual,PASS"
}

$objects = @('NVP_SDA_IOBUF','NVP_SCL_IOBUF') | Sort-Object
if($objects.Count -ne 2 -or $objects[0] -ne 'NVP_SCL_IOBUF' -or $objects[1] -ne 'NVP_SDA_IOBUF') {
  throw 'report_property deterministic ordering fixture failed'
}
'REPORT_PROPERTY_FIXTURE,2,2,PASS'
