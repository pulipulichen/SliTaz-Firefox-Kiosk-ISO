Experimental SliTaz x86_64 Firefox Live ISO for Proxmox VE.

- DHCP with automatic wired-interface selection, including VirtIO.
- Automatic unprivileged login, opening `http://gw/` with an address bar.
- WenQuanYi Micro Hei CJK font, IBus RIME Bopomofo, Ctrl+Space toggle.
- Upstream hybrid BIOS/UEFI boot structure retained.
- Runs in RAM without persistent storage.

Download `slitaz-firefox-kiosk-x86_64.iso` and verify against `SHA256SUMS`.
Source archives, package inventory and library checks accompany the image.
Build-time checks do not replace PVE graphical testing. These are prereleases
until DHCP, rendering and actual Chinese input are verified in the PVE console.
Self-signed certificates require normal manual acceptance. See README.md.
