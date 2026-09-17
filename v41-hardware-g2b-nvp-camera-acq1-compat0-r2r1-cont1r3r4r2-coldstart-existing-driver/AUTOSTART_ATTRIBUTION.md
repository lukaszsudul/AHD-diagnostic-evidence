# Pre-cold XDMA loader attribution

Task: `G2B-NVP-CAMERA-ACQ1-COMPAT0-R2R1-CONT1R3R4R2-COLDSTART`.

## Observed current boot

- DUT: `VCDE-DUT-1`, machine ID `0e90f50d9465492b80258da5658446f8`, boot ID `32d7b853-06fe-4004-9c4b-9b4abafbe896`.
- The protected `10ee:7021` function at `0000:0b:00.0` is bound to live module `xdma`; its 21 class entries and device nodes resolve to that function. The governed AHD `10ee:7011` function at `0000:01:00.0` is unbound. The AHD module `xdma_ahd_pcie` is absent.
- At `2026-09-16T21:27:06+02:00`, the current-boot journal records an interactive `sudo` invocation from a TTY by `vcdeagent2`: `/usr/sbin/insmod` of a task-local `xdma.ko`. The immediately following kernel messages show `xdma` version `2025.2.0` probing `0000:0b:00.0`. This supports manual loading for the current boot; it does not establish the module's on-disk bytes, because that exact file is no longer present.
- The live `xdma` srcversion is `0BD06700E95DB5A1067F2A2`. The installed kernel file reported by `modinfo` has srcversion `8F61105E6B60B5A7A441D9A`. The installed file is not interchangeable with the identified live module. `modules.alias` contains `platform:xdma`; no matching PCI autoload alias for the protected `10ee:7021` function was found in the bounded query.

## Bounded startup-source check

- No relevant entry was found in `/etc/modules`, `modules-load.d`, `modprobe.d`, current-user crontab, `rc.local`, relevant systemd units/timers/jobs, or controller-side AHD/G2B scheduler and hardware processes. The apparent OpenVPN, USB mode-switch, Telit and generic systemd matches were unrelated text matches, not project loaders.
- `systemd-modules-load.service` is a normal active/exited service, but no relevant static module-load entry was found. No pending systemd job was observed.
- The current boot's module-load journal supports `MANUAL_ONLY_LOADING_SUPPORTED`. The separate prospective conclusion is `NO_AUTOLOAD_FOUND_IN_BOUNDED_SCOPE`, **not** proof that future or delayed autoload is impossible. No startup file or driver was edited or executed to test it.
- A read-only `/proc/*/fd` pass found no visible XDMA node holder, but 277 process FD directories were inaccessible to the governed unprivileged account. Thus global node-holder absence is **not proven**. There was no visible active AHD/G2B project helper or project lock, and no observed shutdown inhibitor of type `shutdown`. The Owner must still save or close any work using the protected function before normal shutdown.

## Safety decision

This attribution permits only the already authorized **one Owner-mediated whole-DUT cold-start observation**. It does not permit unloading or replacing the foreign driver, editing autostart, reprogramming without the later admission gates, or repeating the power cycle if the namespace reoccupies. After reboot, the namespace, loader jobs and both PCI functions must be measured again before AHD activation.

Controller-private raw receipts:

| Receipt | Bytes | SHA-256 |
| --- | ---: | --- |
| `connection-pre-cold-survey-1.json` | 32738 | `8BBC41DEFE538A60F7F8EABB3FF7A9293EDD258581AF2093D7735492894C7697` |
| `connection-loader-followup-1.json` | 5016 | `D8B4354550E293F6B2349C879754CE1BEC26AD04959513CBB80466F672770AE1` |
| `connection-pre-cold-holders-followup-1.json` | 3828 | `2646061700C410EBC1CC23F629017ED3E0DBADCC3C3316867A43952637E66C9B` |
