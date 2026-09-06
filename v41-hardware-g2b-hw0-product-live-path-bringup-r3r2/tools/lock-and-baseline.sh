set -eu
umask 077
test "$(hostname)" = VCDE-DUT-1
test "$(cat /proc/sys/kernel/random/boot_id)" = 52b0bf13-e9d1-4558-ae13-d08f4ecc8dac
test ! -e /tmp/ahd-g2b-hw0-product-r3r2-20260906T182010Z.lock
test ! -e /home/vcdeagent1/vcde_artifacts/g2b_hw0_product_r3r2/20260906T182010Z
mkdir /tmp/ahd-g2b-hw0-product-r3r2-20260906T182010Z.lock
mkdir -p /home/vcdeagent1/vcde_artifacts/g2b_hw0_product_r3r2
mkdir /home/vcdeagent1/vcde_artifacts/g2b_hw0_product_r3r2/20260906T182010Z
cd /home/vcdeagent1/vcde_artifacts/g2b_hw0_product_r3r2/20260906T182010Z
mkdir scripts logs artifacts
python3 - <<'PY'
import pathlib,json,datetime,subprocess
r={'task':'G2B-HW0-PRODUCT-R3R2','state':'HELD','boot':'52b0bf13-e9d1-4558-ae13-d08f4ecc8dac','utc':datetime.datetime.now(datetime.timezone.utc).isoformat()}
pathlib.Path('/tmp/ahd-g2b-hw0-product-r3r2-20260906T182010Z.lock/receipt.json').write_text(json.dumps(r))
pathlib.Path('logs/linux-lock.json').write_text(json.dumps(r))
for bdf in ('0000:01:00.0','0000:00:01.1'):
 out=subprocess.check_output(['lspci','-s',bdf,'-vvv'],text=True)
 pathlib.Path('logs/'+bdf.replace(':','_')+'-before.txt').write_text(out)
 print(out)
 p=pathlib.Path('/sys/bus/pci/devices')/bdf
 print('AER',bdf,json.dumps({f.name:f.read_text() for f in p.glob('aer_*')}))
pathlib.Path('logs/kernel-before.txt').write_bytes(subprocess.check_output(['dmesg','--color=never']))
print('LINUX_LOCK=HELD')
print('BASELINE=CAPTURED')
PY
