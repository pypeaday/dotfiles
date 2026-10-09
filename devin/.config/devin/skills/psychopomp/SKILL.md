---
name: psychopomp
description: "Make a narrated motion-graphics video with Psychopomp: intro videos, service/product walkthroughs, comedic unhinged reviews, explainer reels. Use when the user asks for a video, intro, reel, or motion graphic of a project, service, repo, or idea — all rendered locally (GPU + local TTS, no API keys)."
---

# Psychopomp reels (local pipeline)

Code-first motion graphics: a Rust Scene Program emits a Scene Plan, rendered to
1080p60 on the 3090 with locally-generated narration. Repo:
`~/projects/personal/psychopomp` (local clone; upstream is
`github.com/kitlangton/psychopomp` — do not push).

**Read first**: the repo's `.agents/skills/psychopomp` and `explainer-motion`
skills (reel workflow + motion rules) and `SCENE_PLANS.md` (authoring API).
Existing scenes to copy: `scenes/digital-harbor-intro` (small narrated intro),
`scenes/homelab-epic` (multi-fleet constellation, two voices, RollingNumber).

## Environment (UbuntuDev distrobox — these are all required)

- Rust: `cargo +stable` (default toolchain 1.83 is too old; edition 2024 needs the
  installed `stable` 1.99).
- GPU render: the container has no nvidia userspace. Extracted driver libs live
  at `~/nvidia-595/vk/` — always render with:
  `VK_ICD_FILENAMES=~/nvidia-595/vk/nvidia_icd.json LD_LIBRARY_PATH=~/nvidia-595/vk`
  Without it, wgpu silently falls back to llvmpipe (~45x slower). Check the log
  line `GPU: NVIDIA GeForce RTX 3090 (Vulkan)` — if it says llvmpipe, the env
  didn't take.
- Narration/media generation: prepend `~/.local/bin` to PATH when running a
  scene, or the `say`/`uvx` shims won't be found.

## Local TTS (no API keys)

The engine calls `say` and `uvx`; both are shimmed at `~/.local/bin/`:

- `Voice::say("<name>")` in a scene → `say` shim → `tts-generate`:
  - `cb-calm` — Chatterbox exaggeration 0.3 (professional)
  - `cb-unhinged` — exaggeration 1.1 (comedic); `cb:<n>` for any level
  - `kokoro:<voice>` — Kokoro voices (`am_onyx`/`am_fenrir` deepest,
    `bm_daniel`/`bm_george` British, `am_adam` neutral)
  - `en_US-ryan-high` etc — piper fallback, robotic; drafts only
  - Two voices per film: `media.say("a",&calm,..)` + `media.say("b",&manic,..)`
- `uvx` shim → faster-whisper word timing (`WHISPER_MODEL_LOCAL`, default base.en)
- `~/.tts-lexicon` — `word respelling` per line, applied to scripts before
  synthesis. Currently `live lyve`. Add brand-name fixes here.
- Chatterbox is CPU-pinned (cuFFT dies in this container); ~2x realtime is fine
  for clips. `TTS_CUDA=1` to retry GPU.

## Workflow

1. **Facts first.** Know exactly what you're introducing before scripting —
   read the actual repo/services/PRs. Every narrated claim must be traceable.
2. **New scene**: `scenes/<name>/{Cargo.toml,src/main.rs}` — copy
   `digital-harbor-intro` (narrated) or `homelab-epic` (multi-voice). Workspace
   globs `scenes/*`, no Cargo.toml edit needed. Commit to the local clone.
3. **Script** the clips (`const` texts, one per beat). Every visual beat needs an
   anchor phrase the transcript will contain.
4. **Generate**: `PATH=~/.local/bin:$PATH cargo +stable run -p psychopomp-<name>`
   → writes `<scene>.json` + narration mp3s. Only changed clips regenerate.
5. **Anchor audit** (the step everyone misses): `clip.at("phrase")` panics if
   the *whisper transcript* lacks the phrase — and transcripts differ from the
   script ("Sonarr"→"Sonar", "Forgejo"→"Forgajoe", "monorepo"→"Monoripo").
   Check `scenes/<name>/media.lock.json` `words` arrays and anchor to transcript
   words. Use `at_any([...])` for variants, `at_after(p, earlier)` for repeated
   words, `at_every` for chants.
6. **Validate + frame-check**: `plan validate`, then
   `plan snapshot <plan> t1,t2,... /tmp/frames --theme harbor` — look at every
   beat before rendering. `--theme harbor` is our brand palette (added to the
   engine); stock: neutral, tokyo-night, black, opencode, evergreen, original.
7. **Render**: `plan render <plan> output/<name>.mp4 --theme harbor` with the
   GPU env vars. Verify with ffprobe (1920x1080, 60fps, aac) and transcribe the
   audio back with faster-whisper to confirm narration landed.
8. **Deliver**: two sinks —
   - local gallery: `psychopomp/output/` shows up at `127.0.0.1:8788`
     "for review" automatically
   - homelab: `rsync -av ~/projects/personal/psychopomp/output/*.mp4
     ghost:/tank/encrypted/nas/media/reels/` → copyparty at
     `reels.paynepride.com` (`-e2dsa` picks up new files on its own)

## Gallery

`python3 ~/projects/personal/psychopomp/scripts/gallery.py ~/projects/personal/psychopomp/output --port 8788`
— may already be running; `curl -s -o /dev/null http://127.0.0.1:8788` checks.
The homelab copyparty service (`compose/ghost/reels` in homelab-mono) is the
browsable/archive home; rsync finished reels there when the user wants them
published, and mention `reels.paynepride.com`.

## Gotchas learned

- `media.lock.json` keys clips by spec hash — voice/text changes regenerate
  only that clip; `PSYCHOPOMP_MEDIA=plan` dry-runs, `prune` deletes orphans.
- Scene `at()` anchors panic *after* generating — that's normal on first run;
  fix anchors to the transcript and rerun (media stays cached).
- `EmDashHead`-style prop names, `locals.runtime.env`, etc. — Astro-side, not
  relevant here. Relevant here: `Spoken::at(phrase)` returns nanos; use
  `seconds(x)`/`SECOND` for offsets, `saturating_sub` before 0.
- ffmpeg subprocess gets the render env — keep `LD_LIBRARY_PATH` pointed only
  at `~/nvidia-595/vk` (trimmed dir); the full `extracted/` dir has glvnd libs
  that break ffmpeg's libGL.
