# Video / TTS / Reels pipeline — learned facts

Working setup as of the Inquirer trailers (Oct 2026). Read before any video,
voiceover, or reels-feed task.

## Video projects & routing

- Default framework is **HyperFrames** — the `/hyperframes` router skill picks
  the workflow (`product-launch-video` for site promos, `faceless-explainer`
  for invented-visuals pieces). **Psychopomp** is only for the local-GPU
  narrated rust-scene style (`homelab-epic`, `digital-harbor-intro`).
- Where projects live:
  - Inquirer chapter trailers:
    `~/projects/personal/pilgrims-process/videos/inquirer-ch<N>-trailer/` —
    one HyperFrames project per chapter, cloned forward from the previous
    chapter's dir (keeps BRIEF/frame.md/caption-skin + component registry).
  - Inquirer chapter source text (for SCRIPT.md):
    `~/Downloads/ThePilgrimsProcess-Audiobook/.work/chapters/NN-<slug>.txt` —
    20 chapters; audiobook MP3s alongside. Outside the repo, in Downloads —
    don't assume it survives a cleanup.
  - DH site promo: `~/projects/personal/DigitalHarbor/videos/digital-harbor-promo/`.
  - Shipped MP4s → the reels feed (see below); local renders stay in each
    project's gitignored `renders/`.

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

## Voice cloning (Andrew Belcher edition)

- `chatterbox-tts` is installed in `~/.venv-tts` (0.1.7). On CPU,
  `perth.PerthImplicitWatermarker` is `None` — patch
  `perth.PerthImplicitWatermarker = perth.DummyWatermarker` before
  `ChatterboxTTS.from_pretrained(device="cpu")`.
- Clone ref clip: `~/projects/personal/pilgrims-process/voice/andrew-ref-aug30.wav`
  (30s clean preaching from `~/Downloads/August 30 2026.mp3` @ ~741s, loudnorm+afftdn).
  Sermon source MP3s are in `~/Downloads` (~7h total); "Andrew overview.mp3" is a
  multi-speaker session — bad clone source.
- Container has no CUDA (devices exist, no driver userspace); host has RTX 3090 +
  python3.12 at `~/.local/bin/python3.12` — for a full-book clone build, make a
  host venv via `distrobox-host-exec`. Chatterbox CPU ≈ ~9s per second of audio —
  fine for samples, too slow for 20 chapters.
- First test sample: `reels.paynepride.com/andrew-ch3-sample.mp3` (ch3 line 6 in
  Andrew's voice) vs `bmgeorge-ch3-sample.mp3` (same line, bm_george).
- **Zero-shot verdict (user, 2026)**: rejected — pitch ~20Hz above reference
  even from a low-register clip, reads as uncanny. bm_george stays the
  production voice; closing the gap needs fine-tuning on the sermon corpus
  (~30-60min clean segments, GPT-SoVITS/F5 on host 3090), not more ref clips.

## Kokoro pronunciation & cadence (bm_george, Pilgrim's Process)

- Diagnose with `KPipeline(...).g2p(text)` — returns `(phonemes, tokens)`;
  `token.phonemes` per word. IPA map: `A`=eɪ, `Q`=oʊ, `W`=aʊ, `I`=aɪ, `Y`=ɔɪ,
  `ˈ`=primary stress.
- `~/.tts-lexicon` is a respelling map applied by `audiobook-build` before
  synthesis — one `src = dst` (or `src dst`) per line, case-sensitive,
  `\b`-bounded, applied in file order (put phrase rules before word rules).
  Always verify a respell through `g2p()` before adding it.
- Verified fixes in the book: `denied→denyed` (G2P says "den-EED"),
  `Koine→koinay`, `criest→cryest`, `Bereans→Be-REE-ans`, `Beth→Bethh`,
  `wound the weak→woond` phrase-then-`wound→wownd` (misaki swaps both
  senses). All other homographs + KJV `-eth` forms check out in context —
  run the sentence-level g2p scan before adding more.
- `audiobook-build` inserts **graded pauses** via `AB_GAP_SENT` (0.4),
  `AB_GAP_PARA` (1.1), `AB_GAP_SCENE` (2.0), `AB_GAP_TITLE` (1.5) env vars.
  Scene gaps key off `chapters/NN-*.breaks` sidecars generated at extract
  time — this book's `· · ·` marks are chapter-openers only, so scene gaps
  rarely fire; para gap does the cadence work. `AB_SPEED` env (0.95 = trailer
  pace). Chunk WAVs are deleted after concat — re-gapping a chapter =
  deleting its MP3 and re-synthesizing (~17min/chapter on CPU).

## HyperFrames setup & capture

- **Offline / unauthenticated**: without `HEYGEN_API_KEY`, `hyperframes`
  automatically falls back to local engines (Kokoro voice + MusicGen music).
- **Mid-session skill installs**: `npx hyperframes skills update` (or
  `skills add <workflow>`) writes to `~/.agents/skills/`. If the current
  session's `skill` tool says "not found" before the skill index refreshes,
  read `~/.agents/skills/<name>/SKILL.md` directly.
- `hyperframes usage` (and other account/billing subcommands) return
  `unsupported_harness` under Devin — they only work in the harnesses
  hyperframes natively supports. Check install/version with
  `npx hyperframes --version` instead (aspiring-headlight).
- **`npx hyperframes capture <url>`**: writes `capture/screenshots/contact-sheet.jpg`
  (view this first), `scroll-*.png`, and `capture/extracted/{tokens,design-styles,fonts-manifest}.json`.
  Without `GEMINI_API_KEY` / `GOOGLE_API_KEY`, `asset-descriptions.md` uses
  DOM/catalog metadata instead of Vision. Sites using self-hosted `@fontsource/*`
  packages emit `Captured font has no downloaded source` warnings during preset
  generation — load the font files or Google Fonts equivalents in the composition.

## Storyboard & frame packets

- `STORYBOARD.md` frame headings must be `## Frame` (H2) — `### Frame` parses
  as zero frames and the packet builder fails with
  "STORYBOARD.md has no frame blocks".
- The `blueprint:` field takes a **blueprint id** (optionally suffixed
  ` (Reproduce)` / ` (Adapt)`) or the word `compose`. Freeform scene text
  there is resolved as a filename under `hyperframes-animation/blueprints/`
  and crashes the builder.

## hyperframes transcribe

- `npx hyperframes transcribe <file.wav> --json` → writes `transcript.json`
  **into cwd, overwriting on every run**. Rename/copy it per clip immediately.
- The JSON is a bare list of `{text,start,end,id}` word objects (no wrapper).
- Whisper smears silence into neighboring words; after a splice the gap may
  appear inside a word's span — check `start`/`end` of the words AROUND it.
- Whisper inside `~/.venv-tts` itself is broken — a transcription attempt died
  on `av.open()` rejecting the `metadata_errors` kwarg (pyav version drift).
  Don't hand-roll whisper in that venv; `npx hyperframes transcribe` is the
  proven path.

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
- Caption fonts must be **staged**: a `frame.md` family with no matching
  `.woff2/.woff/.ttf/.otf` in `assets/fonts/` or `capture/assets/fonts/`
  silently falls back (check warns "captions will fall back"). Stage a file
  named after the family (`Playfair_Display*.woff2`, `EB_Garamond*.woff2`)
  so it ships with the project.
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
