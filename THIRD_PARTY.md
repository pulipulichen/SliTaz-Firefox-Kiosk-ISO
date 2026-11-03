# Upstream licenses and sources

The existing AGPL-3.0 LICENSE covers this project's original code. It does not
relicense software in the ISO. Each component keeps its upstream terms.

The pinned base ISO input is in `config/sources.lock.json`. Added binary packages
are installed from SliTaz's x86_64 cooking repository, which is not an immutable
snapshot; their receipts remain in the ISO and installed versions in
`packages.tsv`.

- SliTaz packages: <https://mirror.slitaz.org/>. Receipts are retained in
  `/var/lib/tazpkg/installed/`. Source mirror:
  <https://mirror.slitaz.org/sources/>; recipes: <http://hg.slitaz.org/wok/>.
- Firefox: <https://www.mozilla.org/firefox/>; upstream Mozilla notices retained.
- SCIM: <https://github.com/scim-im/scim>, the input-method framework.
- SCIM Tables: <https://github.com/scim-im/scim-tables>, the ZhuYin table engine/data.
- WenQuanYi Micro Hei: Chinese font, from the SliTaz package repository.

Before a general public release, archive exact corresponding source for every
redistributed GPL/LGPL binary from the base image and package mirror, including
build recipes and modifications. A package manifest is not a substitute for
meeting copyleft source-distribution obligations. The complete ISO is not
AGPL-only and is not an official SliTaz or Mozilla release.
