Experimental SliTaz x86_64 Firefox Desktop Live ISO for Proxmox VE.

- DHCP, VirtIO network, ordinary maximized Firefox at https://172.22.10.1:8006/.
- Firefox first-run welcome screens suppressed; desktop, LXPanel and terminal retained.
- WenQuanYi CJK fonts and Traditional Chinese SCIM ZhuYin (Ctrl+Space).
- Static fio 3.35 built with Alpine musl + libaio-dev, with configure/runtime
  checks and a 4K direct-I/O libaio smoke test during the ISO build.
- Two manually launched database-like benchmark desktop icons:
  * 4K R70/W30: 70% random reads, 30% random writes
  * 4K R50/W50: 50% random reads, 50% random writes
- Both use /dev/sda (dedicated disposable disk ONLY), libaio, direct=1,
  iodepth=32, numjobs=1, 60s ramp-up + 600s measured, full disk address span.
- DANGER: destructive writes to /dev/sda! Requires an interactive root
  confirmation string ERASE /dev/sda after mount/swap/holder checks.
  The tests are not started automatically.
- Fio results are temporarily stored in /tmp/fio-results in RAM.

The I/O parameters are inspired by Red Hat Ceph Storage performance benchmark
guidance, but this is a custom test, not a Red Hat benchmark certification.
Download slitaz-firefox-kiosk-x86_64.iso and verify SHA256SUMS.
Still an experimental prerelease until PVE boots, Firefox/SCIM, and the two
fio tests are verified interactively. Self-signed PVE certificates require
normal manual acceptance. See README.md.
