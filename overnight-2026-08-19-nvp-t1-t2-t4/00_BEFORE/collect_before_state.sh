set -eu
echo "UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "HOSTNAME=$(hostname)"
echo "BOOT_ID=$(cat /proc/sys/kernel/random/boot_id)"
sudo -n true
echo "SUDO_NONINTERACTIVE=PASS"
echo "ENDPOINT_COUNT=$(lspci -Dnn -d 10ee:7011 | wc -l)"
lspci -Dnn -d 10ee:7011
lspci -Dvv -s 0000:01:00.0 | sed -n '1,38p'
echo RESOURCE_BEGIN
cat /sys/bus/pci/devices/0000:01:00.0/resource
echo RESOURCE_END
echo "DRIVER_LINK=$(readlink /sys/bus/pci/devices/0000:01:00.0/driver || true)"
lsmod | awk '$1=="xdma" {print}'
modinfo xdma | sed -n '1,20p'
module=$(modinfo -n xdma)
echo "XDMA_MODULE_SHA256=$(sha256sum "$module" | awk '{print $1}')"
find /dev -maxdepth 1 -type c -name 'xdma*' -printf '%f %t:%T\n' | sort
reader=/home/vcdeagent1/FPGA_AHD_HOST/phase2_precheck_accepted/evidence/xdma_axil_read
echo "READER_PATH=$reader"
echo "READER_SHA256=$(sha256sum "$reader" | awk '{print $1}')"
for pair in BLOCK_ID:0x0000 PROTOCOL:0x0004 CAPABILITIES:0x0008 DIAGNOSTIC_MAGIC:0x2000; do
  label=${pair%%:*}
  offset=${pair#*:}
  echo "REG_${label}_BEGIN"
  sudo -n "$reader" /dev/xdma0_user "$offset" 0
  echo "REG_${label}_END"
done
echo KERNEL_HEALTH_BEGIN
journalctl -k -b --no-pager -o short-precise |
  grep -Eai 'aer|pcie|xdma|oops|panic|hung|completion timeout|fatal' |
  grep -Evai 'apparmor|amdgpu|KHO' | tail -n 120 || true
echo KERNEL_HEALTH_END
