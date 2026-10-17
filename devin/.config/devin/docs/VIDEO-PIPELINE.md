# Video / TTS / Reels pipeline — learned facts

Working setup as of the Inquirer trailers (Oct 2026). Read before any video,
voiceover, or reels-feed task.

## tts-generate

- Signature is **positional**: `tts-generate <voice> <textfile> <out.wav>` —
  no flags. Voice spec e.g. `kokoro:bm_george:0.95`.
- Runs on `~/.venv-tts/bin/python` (kokoro + torch live there).
- **Long-form batching (`audiobook-build`)**: PyTorch `kokoro.KPipeline` leaks ~2–3 GB per ~100 chunks in a single process (SpaCy/misaki + glibc arenas) and will exhaust host RAM + swap over a full book. Always wrap `kp(...)` in `with torch.inference_mode():`, call `gc.collect()` + `libc.malloc_trim(0)`, and spawn one subprocess per chapter so all memory is returned to the OS between chapters. Never write multi-hundred-MB chunk directories into `/tmp` (`tmpfs` in RAM).
- For lightweight Docker services on `ghost`, prefer `kokoro-onnx` (`0.6.1` +
  `onnxruntime` + `espeakng-loader`, ~350MB ONNX model, no PyTorch) — same
  Kokoro voice names, ~2.6x realtime on CPU (see `~/projects/personal/listener`).
- **Forced pause**: kokoro won't reliably honor em-dashes as rests. Split the
  line into two reads, then splice:
  `ffmpeg -i a.wav -f lavfi -i "anullsrc=r=24000:cl=mono:d=0.7" -i b.wav
  -filter_complex "[0:a][1:a][2:a]concat=n=3:v=0:a=1[out]" -map "[out]" out.wav`
  → ~0.7s splice lands as ~0.9s felt pause (TTS tails add ~0.2s).
- Normalize VO to `loudnorm=I=-18:LRA=11:TP=-1.5` after splicing.

## HyperFrames setup & capture

- **Offline / unauthenticated**: without `HEYGEN_API_KEY`, `hyperframes`
  automatically falls back to local engines (Kokoro voice + MusicGen music).
- **Mid-session skill installs**: `npx hyperframes skills update` (or
  `skills add <workflow>`) writes to `~/.agents/skills/`. If the current
  session's `skill` tool says "not found" before the skill index refreshes,
  read `~/.agents/skills/<name>/SKILL.md` directly.
- **`npx hyperframes capture <url>`**: writes `capture/screenshots/contact-sheet.jpg`
  (view this first), `scroll-*.png`, and `capture/extracted/{tokens,design-styles,fonts-manifest}.json`.
  Without `GEMINI_API_KEY` / `GOOGLE_API_KEY`, `asset-descriptions.md` uses
  DOM/catalog metadata instead of Vision. Sites using self-hosted `@fontsource/*`
  packages emit `Captured font has no downloaded source` warnings during preset
  generation — load the font files or Google Fonts equivalents in the composition.

## hyperframes transcribe

- `npx hyperframes transcribe <file.wav> --json` → writes `transcript.json`
  **into cwd, overwriting on every run**. Rename/copy it per clip immediately.
- The JSON is a bare list of `{text,start,end,id}` word objects (no wrapper).
- Whisper smears silence into neighboring words; after a splice the gap may
  appear inside a word's span — check `start`/`end` of the words AROUND it.

## MusicGen / hyperframes audio engine

- `media-use`'s audio engine probes `HYPERFRAMES_PYTHON` — set
  `HYPERFRAMES_PYTHON=$HOME/.venv-tts/bin/python` or MusicGen reports
  "deps unavailable" even though they're installed.
- BGM mode `detached-seed-loop` = generate N-second seed, loop it. Reusing one
  track across episodes reads as series identity — cheap win.

## HyperFrames check gotchas

- **SVG `<text>` without `fill` renders black** → instant 1.1:1 contrast fail.
  Set fill explicitly on every text element (class + attr both work).
- Contrast checker samples **mid-fade** — warnings on text that lands via
  opacity tween are semi-unavoidable; fix only resting-state contrast.
- `data-layout-allow-occlusion` marks intentional under-layer text (ghost
  text beneath a canvas/ink layer) — clears `text_occluded` errors.
- `data-track-kind="captions"` on the captions `<div>` in index.html.
- Font fallback chains must not name non-bundled fonts (`SFMono-Regular`
  trips the check); keep only bundled/Google names + generic families.
- No `lint` script — use `npm run check` (lint+runtime+layout+motion+contrast).
- Panned-column camera moves: verify some content is in-frame at every t —
  a column offset that starts below the viewport leaves dead air mid-scene.

## Assembly math (voice-driven films)

- Scene i starts at cumulative sum of prior VO durations (crossfades overlap
  0.5s); frame `data-duration` = voice + ~0.5 tail.
- Alternate `data-track-index` 0/1 per scene so crossfades composite.
- Captions: word absolute time = scene start + word.start; 2–3 words/group.

## Reels feed (reels.paynepride.com)

- Content lives on the **host** volume, not in the repo:
  `ghost:/tank/encrypted/nas/media/reels/`. The compose dir
  (`homelab-mono/compose/ghost/reels/`) has no media subdir — don't cp there.
- Ship: `rsync -av file.mp4 ghost:/tank/encrypted/nas/media/reels/<name>.mp4`
- Pin/tag: `curl -X POST -d 'f=<name>.mp4' https://reels.paynepride.com/tag`
  (toggles; idempotent per name) or `ssh ghost 'echo <name> > .../.review'`.
- Anchors: `reels.paynepride.com/#f-<filename>` scrolls to a card.
- Audiobooks/audio files land in "dev samples"; mp4s pin under review.
