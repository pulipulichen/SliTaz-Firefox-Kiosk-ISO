Experimental SliTaz x86_64 Firefox Live ISO for Proxmox VE.

- DHCP with automatic wired-interface selection, including VirtIO.
- Automatic unprivileged login, opening `http://gw/` with an address bar.
- WenQuanYi Micro Hei CJK font, SCIM ZhuYin table input, Ctrl+Space toggle.
- No RIME source compilation or build toolchain in the image.
- Upstream hybrid BIOS/UEFI boot structure retained.
- Runs in RAM without persistent storage.

Download `slitaz-firefox-kiosk-x86_64.iso` and verify against `SHA256SUMS`.
Package inventory, source lock, and runtime library checks accompany the image.
These are prereleases until DHCP, rendering and actual ZhuYin input are verified
in PVE. First-time SCIM engine selection may be necessary. Self-signed
certificates require normal manual acceptance. See README.md.
