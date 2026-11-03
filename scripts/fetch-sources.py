#!/usr/bin/env python3
"""Download hash-locked upstream inputs; extract source archives safely."""
import hashlib
import json
from pathlib import Path
import shutil
import sys
import tarfile
import urllib.request

repo = Path(__file__).resolve().parents[1]
cache = Path(sys.argv[1]).resolve()
cache.mkdir(parents=True, exist_ok=True)
locks = json.loads((repo / 'config/sources.lock.json').read_text())
for name, entry in locks.items():
    target = cache / ('base.iso' if name == 'base-iso' else name + '.tar.gz')
    if not target.exists():
        print('Downloading', name, flush=True)
        partial = target.with_suffix('.partial')
        with urllib.request.urlopen(entry['url'], timeout=120) as src, partial.open('wb') as dst:
            shutil.copyfileobj(src, dst)
        partial.rename(target)
    with target.open('rb') as stream:
        digest = hashlib.file_digest(stream, 'sha256').hexdigest()
    if digest != entry['sha256']:
        raise SystemExit('SHA256 mismatch: ' + str(target) + '; review upstream before updating the lock')
    if name == 'base-iso':
        continue
    out = cache / 'sources' / name
    if out.exists():
        shutil.rmtree(out)
    out.mkdir(parents=True)
    with tarfile.open(target) as archive:
        # Strip exactly one upstream directory; data filter rejects path escapes.
        for member in archive.getmembers():
            parts = member.name.split('/', 1)
            if len(parts) < 2 or not parts[1]:
                continue
            member.name = parts[1]
            archive.extract(member, out, filter='data')
