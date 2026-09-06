set -eu
umask 077
boot='__EXPECTED_BOOT_ID__'
lock='/tmp/ahd-g2b-hw0-product-r3r3-20260906T200624Z-post.lock'
root='/home/vcdeagent1/vcde_artifacts/g2b_hw0_product_r3r3/20260906T200624Z'
test "$(hostname)" = 'VCDE-DUT-1'
test "$(cat /etc/machine-id)" = '0e90f50d9465492b80258da5658446f8'
test "$(uname -r)" = '7.0.0-29-generic'
test "$(uname -m)" = 'x86_64'
test "$(cat /proc/sys/kernel/random/boot_id)" = "$boot"
test ! -e "$lock"
test -d "$root/logs"
mkdir "$lock"
python3 - <<'PY'
import datetime, json, pathlib, subprocess
P=pathlib.Path
boot='__EXPECTED_BOOT_ID__'
lock=P('/tmp/ahd-g2b-hw0-product-r3r3-20260906T200624Z-post.lock')
root=P('/home/vcdeagent1/vcde_artifacts/g2b_hw0_product_r3r3/20260906T200624Z')
receipt={'task':'G2B-HW0-PRODUCT-R3R3','phase':'POST_REBOOT','state':'HELD','boot':boot,'utc':datetime.datetime.now(datetime.timezone.utc).isoformat()}
(lock/'receipt.json').write_text(json.dumps(receipt)+'\n')
(root/'logs/post-reboot-linux-lock.json').write_text(json.dumps(receipt,indent=2)+'\n')
(root/'logs/kernel-postreboot-before-load.txt').write_bytes(subprocess.check_output(['dmesg','--color=never']))
for bdf in ('0000:01:00.0','0000:00:01.1'):
    result=subprocess.run(['lspci','-s',bdf,'-vvv'],capture_output=True)
    (root/'logs'/('lspci-'+bdf.replace(':','_')+'-postreboot.txt')).write_bytes(result.stdout+result.stderr)
print(json.dumps(receipt))
PY
echo POST_REBOOT_LINUX_LOCK=HELD
