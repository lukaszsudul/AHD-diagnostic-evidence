from pathlib import Path
import subprocess,time,os,json
R=Path(__file__).parent
env=dict(os.environ,XILINX_LOCAL_USER_DATA='NO')
existing=subprocess.check_output(['powershell','-NoProfile','-Command',"Get-Process vivado -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Id; exit 0"],text=True).strip()
assert not existing, 'unrelated Vivado exists: '+existing
with (R/'console.log').open('w') as log:
 p=subprocess.Popen(['C:/AMDDesignTools/2025.2/Vivado/bin/vivado.bat','-mode','batch','-source',str(R/'worker.tcl'),'-log',str(R/'vivado.log'),'-journal',str(R/'vivado.jou')],cwd=R,env=env,stdout=log,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
 start=time.time(); (R/'process.json').write_text(json.dumps({'pid':p.pid,'started':start,'command':'task-owned Vivado batch worker'}))
 while p.poll() is None:
  phase='LAUNCH'; budget=900; begun=start
  if (R/'phase.txt').exists():
   phase,budget,begun=(R/'phase.txt').read_text().strip().split('|'); budget=int(budget);begun=int(begun)
  if time.time()-begun>budget:
   (R/'TIMEOUT.json').write_text(json.dumps({'phase':phase,'budget':budget,'pid':p.pid,'elapsed':time.time()-begun}))
   subprocess.run(['taskkill','/PID',str(p.pid),'/T','/F'],stdout=log,stderr=log)
   break
  time.sleep(1)
 p.wait(); (R/'exit.json').write_text(json.dumps({'returncode':p.returncode,'finished':time.time()}))
print((R/'exit.json').read_text())
