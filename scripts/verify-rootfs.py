#!/usr/bin/env python3
"""Reject an ISO missing SCIM ZhuYin, CJK fonts, or unproven VirtIO support."""
from pathlib import Path
import sys

root = Path(sys.argv[1])
required = [
    'usr/bin/scim',
    'usr/local/bin/kiosk-session',
    'usr/local/sbin/kiosk-network',
]
missing = [name for name in required if not (root / name).exists()]
patterns = [
    'usr/share/scim/tables/ZhuYin*.bin',
    'usr/lib/scim-*/**/IMEngine/table.so',
    'lib/modules/*/kernel/drivers/net/virtio_net.ko*',
    'usr/share/fonts/**/*microhei*',
]
missing += [pattern for pattern in patterns if not list(root.glob(pattern))]

# VirtIO PCI can be built into the kernel (=y); no virtio_pci.ko is
# installed in that case. Check for an actual module or positive evidence.
pci_modules = list(root.glob('lib/modules/*/kernel/drivers/virtio/virtio_pci.ko*'))
builtin_files = list(root.glob('lib/modules/*/modules.builtin'))
kernel_configs = list(root.glob('boot/config-*'))
builtin_module = any(
    'drivers/virtio/virtio_pci.ko' in p.read_text(errors='replace')
    for p in builtin_files
)
builtin_config = any(
    'CONFIG_VIRTIO_PCI=y' in p.read_text(errors='replace').splitlines()
    for p in kernel_configs
)
if pci_modules:
    print('VirtIO PCI: kernel module present')
elif builtin_module or builtin_config:
    print('VirtIO PCI: built-in kernel driver confirmed')
else:
    missing.append('virtio_pci: neither .ko nor builtin evidence found')
    print('VirtIO PCI inspection: modules.builtin files:',
          [str(p.relative_to(root)) for p in builtin_files])
    print('VirtIO PCI inspection: available virtio files:',
          [str(p.relative_to(root)) for p in root.glob('lib/modules/**/*virtio*')][:80])
    print('VirtIO PCI inspection: kernel config files:',
          [str(p.relative_to(root)) for p in kernel_configs])

if missing:
    raise SystemExit('Missing runtime requirements:\n' + '\n'.join(missing))
print('SCIM ZhuYin and runtime file requirements passed')
