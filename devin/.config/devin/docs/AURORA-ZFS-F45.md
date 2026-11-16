# Aurora drops ZFS in F45 — research + plan (aurora host)

Researched 2026-11-10. Source issue: https://github.com/ublue-os/aurora/issues/1765
Parent tracker: https://github.com/ublue-os/aurora/issues/2758 ("fedora 45 tracker")

## What's happening

- **Aurora removes ZFS from Fedora 45–based images** (Fall 2026). Pinned maintainer
  post by @renner0e, 2026-05-14; title finalized 2026-05-15.
- **Fedora 45 released 2026-11-03** (kernel 7.2, two slips from Oct 20 target).
  Aurora `:stable` rebase to F45 is imminent — days, not months.
- Why: Fedora's fast kernel cadence vs out-of-tree OpenZFS lag. `stable` kept
  getting pinned to EOL kernels or releases held waiting for ZFS builds, delaying
  security fixes for everyone. ZFS was never documented or in the installer —
  "a little secret extra" (@inffy). The 6.18→ZFS 2.3.6 lag was ~3 months.
- `akmods`/`akmods-zfs` images **keep building** (`ublue-os/akmods`,
  `build_files/zfs`, tracks OpenZFS GitHub releases) — uCore needs them. So
  custom images can re-add ZFS; the support burden just moves to the user.
- Deprecation notifier shipped (ublue-os/aurora#2613, merged ~Jul 30); users with
  pools got desktop notifications Aug–Oct 2026. aurora host has
  `aurora-zfs-deprecation-notifier.timer` enabled.
- Bluefin same deprecation; **Bluefin LTS keeps ZFS** (CentOS 6.12 kernel, stable
  for its lifecycle). No Aurora LTS exists. CachyOS kernels / Origami Linux were
  suggested and rejected ("no plans to bring custom kernels to Aurora" — @inffy).

## aurora host impact (verified 2026-11-10)

- Image: `aurora-dx-nvidia-open:stable`, deployed 44.20261027.1, staged
  44.20261110.1 — **still F44**. Auto-update timer inactive → updates are manual;
  the user controls the cutover moment.
- Pool `orbit`: single 2TB Crucial SSD (`part1`), 1.81T / 721G used, ONLINE.
  Imports via `/etc/zfs/zpool.cache` + `zfs-import-cache.service` /
  `zfs-mount.service` (units ship with the image's ZFS — gone in F45).
- Load-bearing datasets:
  - `orbit/projects` → `/var/home/nic/projects` (all dev work, incl. this repo dir)
  - `orbit`, `orbit/home-restore`, `orbit/emergency` → `/var/orbit`
  - `orbit/volumes/*` → `/var/docker-storage-zfs` — docker is **active** with
    volumes for komodo, mcphub, ollama, open-webui, sd, speakr, tdarr
- If an F45 image boots: no zfs kmod/utils/services → pool doesn't import →
  `~/projects` empty, docker starts against empty mountpoint dirs under `/var`
  (writable, persistent) → services write fresh state into the wrong place.
  Rootfs is fine; boot isn't broken — the data just silently isn't there.
- Data is never trapped: single-disk pool exports/imports anywhere ZFS runs
  (uCore, FreeBSD, the custom-image path below).

## Options

### A. Custom image with ZFS re-added (recommended for this host)

Reference: https://github.com/renner0e/aurora-zfs-example (maintainer's own
example, "purely an example — I will not maintain this").

Mechanism (its Containerfile):
- `FROM ghcr.io/ublue-os/aurora:$FEDORA_VERSION`, then `zfs.sh`:
  - erases stock kernel + kmods, installs kernel RPMs from
    `ghcr.io/ublue-os/akmods:coreos-stable-$FEDORA_VERSION` (versionlocked)
  - installs ZFS kmod+userland from
    `ghcr.io/ublue-os/akmods-zfs:coreos-stable-$FEDORA_VERSION`
  - xone/v4l2loopback kmods from the same akmods stream, depmod, modules-load
    `zfs.conf`, rebuild initramfs
- Escape hatch documented in-file: pin
  `akmods-zfs:coreos-stable-<ver>-<kver>` tags when upstream kernel outruns ZFS.
- GH Actions workflow + cosign.pub included (ublue image-template style).

Tweaks needed for `aurora-dx-nvidia-open`:
- base image → `aurora-dx-nvidia-open` (same versioned tags exist, e.g. `:44`)
- also install **nvidia-open kmod** RPMs from the same akmods stream — the stock
  image's nvidia kmod won't match the coreos-stable kernel
- install `kernel-modules-extra`/`kernel-modules-core` too (example only does
  core+modules; desktop needs extras)
- verify `zfs-import-cache`/`zfs-mount` units enabled in the built image
  (zpool.cache already persists in /etc)

Tradeoffs: kernel now tracks the **coreos-stable akmods stream** (≈ what Aurora
stable already shipped — ZFS already gates the kernel today). When Fedora+ZFS
desync, YOUR build gates/pins — the burden maintainers dropped becomes yours.
Danathar's repos: `aurora-zfs-simple` (same approach, more auditable) vs
`zfs-aurora-complex` (builds OpenZFS from upstream releases, mismatch detection,
promotion/signing — works but self-described "vibe coded LLM mousetrap"; wjoel
hit one weird session on it). Fork + build your own rather than rebasing onto
someone else's image (trust concern raised in-thread).

### B. Migrate storage ZFS → btrfs (drop ZFS entirely)

- 721G used → needs a ≥1TB spare target. rsync or `zfs send`→files; recreate
  mountpoints as btrfs subvolumes; stop docker first; repoint mounts; export
  pool; keep the 2TB disk as cold backup.
- One-time pain, zero maintenance, stock Aurora forever. Loses native
  zfs send/recv + checksums; btrfs snapshots + btrbk approximate snapshots.
  novate in-thread: "Sharing my fix: zfs -> btrfs".

### C. Stay on F44 (bridge, not destination)

- `bootc switch ghcr.io/ublue-os/aurora-dx-nvidia-open:44` pins the F44 stream
  (versioned tags confirmed to exist). F44 EOL ≈ 4 weeks after F46 GA (~May
  2027). Buys ~6 months to do A or B calmly. Rollback is always
  `bootc rollback`.

### D. Move ZFS workloads to ghost / uCore

- uCore keeps ZFS permanently. The 7 docker services could migrate to ghost, but
  `~/projects` must stay local — doesn't remove the need for A or B on the
  desktop. Not sufficient alone.

### E. Bluefin LTS

- Keeps ZFS for its whole lifecycle, but GNOME + CentOS base; user is on
  KDE/DX/nvidia-open. Mentioned for completeness.

## Suggested sequence (if A)

1. Now: don't run updates past F44 (manual anyway). Optionally `bootc switch
   :44` tag as a seatbelt.
2. Fork `aurora-zfs-example`; retarget to `aurora-dx-nvidia-open`; add
   nvidia-open + kernel-modules-extra; wire signing.
3. Build on F44 base now, `bootc switch` to it, verify `zpool status`, all
   mountpoints, `docker ps` services healthy. Old deployment stays for rollback.
4. At F45 cutover: bump `FEDORA_VERSION=45`; if `akmods-zfs:coreos-stable-45`
   lags kernel 7.2, pin the last-good tagged pair.
5. Revisit in ~6 months: if image maintenance annoys, do B (btrfs migration)
   with the orbit disk as cold spare.

## Sources

- https://github.com/ublue-os/aurora/issues/1765 (+ full comments via API)
- https://github.com/ublue-os/aurora/issues/2758 (F45 tracker)
- https://github.com/renner0e/aurora-zfs-example (Containerfile, build_files/zfs.sh)
- https://github.com/Danathar/aurora-zfs-simple , https://github.com/Danathar/zfs-aurora-complex
- https://github.com/ublue-os/akmods/tree/main/build_files/zfs
- Fedora 45 GA 2026-11-03: redhat.com blog "Announcing Fedora 45", fosslinux.com
- Host state: `zpool status`, `findmnt -t zfs`, `rpm-ostree status`, systemctl
  unit list via distrobox-host-exec (2026-11-10)
