#!/usr/bin/env python3
"""Reject an ISO missing the SCIM ZhuYin runtime requirements."""
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
    'lib/modules/*/kernel/drivers/virtio/virtio_pci.ko*',
    'usr/share/fonts/**/*microhei*',
]
missing += [pattern for pattern in patterns if not list(root.glob(pattern))]
if missing:
    raise SystemExit('Missing runtime requirements:\n' + '\n'.join(missing))
print('SCIM ZhuYin and runtime file requirements passed')
