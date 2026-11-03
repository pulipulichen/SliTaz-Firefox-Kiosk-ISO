Experimental SliTaz x86_64 Firefox desktop Live ISO for Proxmox VE.

- DHCP including VirtIO NIC and automatic wired interface detection.
- A normal maximized Firefox window opening https://172.22.10.1:8006/.
- Firefox first-run and update welcome pages suppressed via policies and profile preferences.
- Retains the desktop (Openbox, PCManFM, LXPanel), terminal, and network settings access.
- WenQuanYi CJK fonts; SCIM Traditional Chinese ZhuYin as the default engine,
  Ctrl+Space toggle. This is not RIME or Chewing.
- Includes static fio 3.35 plus a desktop launcher and script for a safe
  10-minute database-like 70/30 random-read/write test against a regular file.
- Upstream hybrid BIOS/UEFI boot structure retained.
- Runs in RAM, without persistent storage unless specifically mounted.

Download slitaz-firefox-kiosk-x86_64.iso and verify SHA256SUMS.
Package inventory, source lock, and runtime library checks accompany the image.
Still an experimental prerelease until the Firefox desktop, Ctrl+Space ZhuYin,
and fio test have been verified interactively in PVE.
Self-signed HTTPS certificates require normal manual acceptance.
See README.md for fio's default RAM-backed test limitation.
