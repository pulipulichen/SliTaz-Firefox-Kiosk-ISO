# Upstream licenses and sources

The existing AGPL-3.0 LICENSE covers this project's original code. It does not
relicense software in the ISO. Each component keeps its upstream terms.

Exact source inputs are in `config/sources.lock.json`. Releases include source
archives for the added compiled libraries and IBus engine. Upstream notices are
copied to `/usr/share/doc/kiosk/upstream/` inside the ISO.

- SliTaz packages: <https://mirror.slitaz.org/>. Receipts remain in
  `/var/lib/tazpkg/installed/`. `packages.tsv` records installed versions.
  Source mirror: <https://mirror.slitaz.org/sources/>;
  recipes: <http://hg.slitaz.org/wok/>.
- Firefox: <https://www.mozilla.org/firefox/>; upstream Mozilla notices retained.
- librime: <https://github.com/rime/librime> (BSD-3-Clause).
- ibus-rime: <https://github.com/rime/ibus-rime> (GPL-3.0).
- RIME data: prelude, bopomofo, terra-pinyin, stroke under <https://github.com/rime>;
  retain individual dictionary notices and attribution.
- yaml-cpp: <https://github.com/jbeder/yaml-cpp> (MIT).
- LevelDB: <https://github.com/google/leveldb> (BSD-3-Clause).
- marisa-trie: <https://github.com/s-yata/marisa-trie> (BSD/LGPL dual license).
- IBus, OpenCC, Boost, WenQuanYi: SliTaz package receipts identify upstream terms.

Before a general public release, archive exact corresponding source for every
redistributed GPL/LGPL binary from the base image and package mirror, including
build recipes and modifications. Added RIME source archives alone do not satisfy
all base-image source obligations. The complete ISO is not AGPL-only and is not
an official SliTaz or Mozilla release.
