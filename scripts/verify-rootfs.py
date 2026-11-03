#!/usr/bin/env python3
"""Build-time requirements; fail before publishing an incomplete image."""
from pathlib import Path
import sys

root = Path(sys.argv[1])
required = [
    'usr/bin/ibus-daemon', 'usr/share/ibus/component/rime.xml',
    'opt/rime/libexec/ibus-rime/ibus-engine-rime',
    'opt/rime/share/rime-data/bopomofo.schema.yaml',
    'opt/rime/share/rime-data/terra_pinyin.dict.yaml',
    'etc/skel/.config/ibus/rime/default.custom.yaml',
    'usr/local/bin/kiosk-session', 'usr/local/sbin/kiosk-network',
]
missing = [name for name in required if not (root / name).exists()]
patterns = ['lib/modules/*/kernel/drivers/net/virtio_net.ko*',
            'lib/modules/*/kernel/drivers/virtio/virtio_pci.ko*',
            'usr/lib/gtk-3.0/*/immodules/im-ibus.so',
            'usr/share/fonts/**/*microhei*']
missing += [pattern for pattern in patterns if not list(root.glob(pattern))]
if missing:
    raise SystemExit('Missing runtime requirements:\n' + '\n'.join(missing))
print('Runtime file requirements passed')
