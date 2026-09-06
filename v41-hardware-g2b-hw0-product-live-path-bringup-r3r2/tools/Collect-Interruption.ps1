$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$code=@'
import pathlib,json,base64,hashlib,subprocess
p=pathlib.Path('/home/vcdeagent1/vcde_artifacts/g2b_hw0_product_r3r2/20260906T182010Z')
files={}
for f in (p/'logs').iterdir():
 if f.is_file():files[f.name]=f.read_bytes()
for name,args in {'journal-original-tail.txt':['journalctl','-b','52b0bf13e9d14558ae13d08f4ecc8dac','-n','180','--no-pager'], 'journal-intermediate.txt':['journalctl','-b','3decbc633fc743fe88b08901d225846b','--no-pager'], 'kernel-current.txt':['dmesg'], 'boot-list.txt':['journalctl','--list-boots','--no-pager']}.items():
 r=subprocess.run(args,capture_output=True);files[name]=r.stdout+r.stderr
state={'boot':pathlib.Path('/proc/sys/kernel/random/boot_id').read_text().strip(),'taint':pathlib.Path('/proc/sys/kernel/tainted').read_text().strip(),'modules':pathlib.Path('/proc/modules').read_text(),'nodes':[str(x) for x in pathlib.Path('/dev').glob('xdma*')],'linux_lock_exists':pathlib.Path('/tmp/ahd-g2b-hw0-product-r3r2-20260906T182010Z.lock').exists(),'driver_bound':pathlib.Path('/sys/bus/pci/devices/0000:01:00.0/driver').is_symlink(),'speed':pathlib.Path('/sys/bus/pci/devices/0000:01:00.0/current_link_speed').read_text().strip(),'width':pathlib.Path('/sys/bus/pci/devices/0000:01:00.0/current_link_width').read_text().strip(),'capture_files':[x.name for x in (p/'logs').glob('T*')],'artifacts':[x.name for x in (p/'artifacts').iterdir()]}
files['interruption-state.json']=(json.dumps(state,indent=2)+'\n').encode()
print(json.dumps({k:{'sha256':hashlib.sha256(v).hexdigest().upper(),'data':base64.b64encode(v).decode()} for k,v in files.items()}))
'@
& "$PSScriptRoot\Invoke-R3R2DutConnection.ps1" -ReceiptName interruption-collection -Sudo -TimeoutSeconds 30 -RemoteCommand ("python3 - <<'COLLECT'`n"+$code+"`nCOLLECT") | Out-Null
$receipt=Get-Content -Raw "$root\logs\connection-interruption-collection.json" | ConvertFrom-Json
$bundle=$receipt.stdout | ConvertFrom-Json -AsHashtable
$dest=Join-Path $root 'artifacts\dut-text'
New-Item -ItemType Directory -Path $dest -ErrorAction Stop | Out-Null
foreach($name in $bundle.Keys){
 if([IO.Path]::GetFileName($name) -cne $name){throw 'BAD_NAME'}
 $bytes=[Convert]::FromBase64String($bundle[$name].data)
 $path=Join-Path $dest $name
 [IO.File]::WriteAllBytes($path,$bytes)
 if((Get-FileHash $path).Hash -cne $bundle[$name].sha256){throw 'DOWNLOAD_HASH_FAIL'}
}
"TEXT_FILES_VERIFIED=$($bundle.Count)"
