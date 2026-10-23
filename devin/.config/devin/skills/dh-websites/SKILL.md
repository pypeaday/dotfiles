---
name: dh-websites
description: "Digital Harbor client-website standards. Use when building, editing, deploying, or reviewing any Digital Harbor client site (a repo ending in -website under ~/projects/personal, or anything deployed to *.digitalharbor.workers.dev / a DH-managed domain). Covers the Lighthouse-100 bar, llms.txt, WebMCP, and the standard Resend contact-form + deploy conventions."
---

# DH Website Standards

Rules for every Digital Harbor client site. Apply when creating a new site
and when editing an existing one — flag violations you find, don't silently
leave them.

Reference implementation: `~/projects/personal/zingler-meats-website`
(static Astro + Worker). Older siblings predate parts of this standard —
bring them up to it opportunistically, not mid-unrelated-task.

## 0. New-site checklist

Cloning the reference repo beats any generator script — every convention in
this file comes along for free:

1. `rsync -a --exclude node_modules --exclude dist --exclude .git
   --exclude .wrangler --exclude .astro --exclude package-lock.json
   ../zingler-meats-website/ <slug>-website/` — repo name is
   `<slug>-website`, worker name matches (`wrangler.toml` `name`).
2. Adapt `src/site.ts` first (it's the only facts file), then component
   copy. Rename/repurpose sections as needed — bw-lawn turned CareTips into
   a "visit prep" section and swapped the form's `deer` field for
   `address` + `cornerLot` (match the form fields to the business).
3. SEO files: favicon.svg, `public/index.md`, `llms.txt`, `robots.txt`,
   `sitemap.xml`. **All public URLs use the canonical
   `<slug>.mydigitalharbor.com`** — never the workers.dev URL.
4. `npm install && just deploy` (after `source .envrc`).
5. `RESEND_API_KEY` — hand-made shared secret, lives in a sibling repo's
   `.dev.vars` (e.g. `power-washing-website/.dev.vars`) or the vault.
   `grep RESEND_API_KEY <sibling>/.dev.vars | cut -d= -f2 |
   npx wrangler secret put RESEND_API_KEY` — never print it.
6. Attach the custom domain: `cloudflare_workers_custom_domain` for
   `<slug>.mydigitalharbor.com` on the DH account (zone
   `mydigitalharbor.com`, service = the worker name) — dashboard or API;
   verify with `GET /accounts/$CLOUDFLARE_ACCOUNT_ID/workers/domains
   ?hostname=<slug>.mydigitalharbor.com`.
7. Verify the bar on the canonical URL: Lighthouse (below) + the mobile
   overflow sweep.
8. Register: `sites.yaml` (client + site), `DigitalHarbor/src/data/sites.ts`,
   Twenty (company + person + CUSTOMER opp + note). Push repo to
   `ssh://git@git-ghost:222/nic/<slug>-website.git` and set `repo:` in
   sites.yaml — don't leave it LOCAL-ONLY.
9. OG image — no rasterizer installed; screenshot a 1200×630 HTML mock with
   the playwright chromium: `chrome --headless --no-sandbox
   --screenshot=public/images/og.png --window-size=1200,630
   --hide-scrollbars file:///tmp/og.html`.

### Mobile overflow sweep — runnable

`playwright-core` is installed in several sibling repos
(e.g. `1man1band-website/node_modules`). Run from there:

```js
import { chromium } from 'playwright-core';
const browser = await chromium.launch({
  executablePath: process.env.CHROME_PATH, args: ['--no-sandbox'],
});
for (const w of [320, 390, 768]) {
  const page = await browser.newPage({
    viewport: { width: w, height: 844 }, hasTouch: true,
  });
  await page.goto(url, { waitUntil: 'networkidle' });
  const res = await page.evaluate(() => ({
    scrollW: document.documentElement.scrollWidth,
    clientW: document.documentElement.clientWidth,
    offenders: [...document.querySelectorAll('body *')].filter((el) => {
      const r = el.getBoundingClientRect();
      return r.right > innerWidth + 1 || r.left < -1;
    }).slice(0, 8).map((el) => el.tagName + '.' + el.className),
  }));
  console.log(w, res);
  await page.close();
}
await browser.close();
```

## 1. Lighthouse 100 — the bar

Every DH site must score **100 in Accessibility, Best Practices, and SEO**,
and **≥98 Performance** (aim for 100; the last 1–2 points are Lighthouse's
simulated-throttling noise — if the filmstrip frames are identical and TBT/
CLS are 0, the residual isn't a real defect). Measured against the deployed
URL — not localhost.

Verify:

```bash
CHROME_PATH=$(echo ~/.cache/ms-playwright/*/chrome-linux64/chrome) \
  npx lighthouse <url> --quiet \
  --only-categories=performance,accessibility,best-practices,seo \
  --chrome-flags="--headless=new --no-sandbox" \
  --output=json --output-path=/tmp/lh.json
python3 -c "import json;d=json.load(open('/tmp/lh.json'));print({k:v['score'] for k,v in d['categories'].items()})"
```

Re-run after any change to the hero, fonts, head tags, or JS.

How to get there on our stack:

- **Static-first.** Astro `output: 'static'` + Worker serving via the ASSETS
  binding. Only JS that earns its bytes — no framework hydration.
- **Fonts: self-hosted, static-instanced, subset.** Third-party font CSS is
  the #1 perf killer (cross-origin stylesheet → woff2 chain counts as the
  Lantern critical path even when async). Recipe:
  - Download the family's variable woff2 from Google Fonts, then per used
    weight: `fonttools instancer 'wght=700' in.woff2 -o out.woff2`, then
    `fonttools subset out.woff2 --unicodes='U+0000-00FF,U+2000-206F' --flavor=woff2`
    (run via `uv run --with fonttools fonttools …` — system python has no
    fontTools). One file per weight actually used; **don't ship italics for
    one `<em>`** — reword instead.
  - Serve from `public/fonts/`, `@font-face` with
    `font-display: optional` for *all* faces (swap repaints every text node
    when the font lands — that repaint *is* your late LCP/SI), and
    `<link rel="preload" as="font" crossorigin>` for each critical file in
    the layout head.
  - Never icon fonts — inline SVG.
- **Inline the site's own CSS.** `build.inlineStylesheets: 'always'` in
  astro.config.mjs puts the compiled Tailwind in a `<style>` tag — kills the
  second render-blocking request on our one-pagers.
- **Scroll reveals: transform-only.** `opacity: 0` initial states hide
  elements from Lighthouse's contrast audit (they pass while invisible, then
  fail real users) *and* delay visual completeness. Animate
  `transform: translateY` only — content paints immediately, and every text
  node's contrast is actually measured. Then fix what the audit finds —
  small/secondary text needs `ink-600`-grade color on light backgrounds.
- **a11y heading order.** No skipped levels — hero `h1` → section `h2` →
  card `h3`. Decorative mini-labels (trust bars, eyebrow tags) are styled
  `<p>`, not headings.
- **Worker-first routing.** `assets = { ..., run_worker_first = true }` in
  wrangler.toml — otherwise Cloudflare serves matching assets directly and
  `src/worker.ts` never sees the request (Link headers, future middleware).
- **Images.** Explicit width/height or aspect-ratio, `loading="lazy"` below
  the fold, modern formats (avif/webp) where we control the asset.
- **Head.** `<title>` + meta description (unique per page), canonical,
  `og:title`/`og:description`/`og:type`/`og:image`, `theme-color`, favicon.
- **a11y.** Semantic landmarks (header/main/footer/nav), skip link, one h1,
  labels on every form control, visible focus styles, contrast ≥ 4.5:1,
  `prefers-reduced-motion` honored.
- **SEO files.** `public/robots.txt` (allow all + sitemap) and
  `public/sitemap.xml` on every site, even one-pagers.

### Mobile experience — the floor

Most client traffic is phones. Verify on real mobile viewports — a narrowed
desktop window doesn't tell the truth.

- **No horizontal scroll — ever.**
  `document.documentElement.scrollWidth === document.documentElement.clientWidth`
  at 320, 390, and 768 CSS px, on the deployed URL, on the homepage + longest
  page. Sweep for offenders headlessly:
  ```js
  [...document.querySelectorAll("body *")].filter((el) => {
    const r = el.getBoundingClientRect();
    return r.right > innerWidth + 1 || r.left < -1;
  })
  ```
  Usual causes on our stack: un-wrapping nav rows, fixed-width/`w-max`
  elements near screen edges, absolutely-positioned cards/decorations,
  negative-margin or `inset: -10%`-style pseudo bleeds, long unbreakable
  strings. Elements hidden with `opacity: 0` still count — they occupy
  layout space.
  - **Content overflow → fix the element** (`flex-wrap`, `w-full` below
    `sm:`, `min-w-0` on flex children, clamp to measured space).
  - **Decorative bleed → contain it.** Glows, absolute decorations, and
    pseudo-element bleeds that are *supposed* to overhang get an
    `overflow-hidden`/`overflow: clip` ancestor, or `overflow-x: clip` on
    `html`+`body` at the root. **`clip`, never `hidden`** — `hidden` creates
    a scroll container and breaks `position: sticky`; `clip` doesn't.
    Wide fixed-size decorations (e.g. `w-[48rem]` glow divs on a 390px
    phone) MUST have a clipped ancestor or the root clip — this caused a
    real mobile h-scroll incident on mydigitalharbor.com (2026-10-19).
- **Touch targets** ≥ ~40px tall — padding on the `<a>`/`<button>`, not just
  the label text.
- **Perf-test mobile honestly.** Emulate ~390×844, `hasTouch: true`, CPU
  throttle 4×. Desktop numbers hide the jank phones feel. Per-frame CSS
  filters (`drop-shadow`, `blur`) on animated elements don't show in JS
  timing — they only show in raster; swap for plain strokes/opacity or bake
  the effect into a static layer.
- **Every scroll animation**: transform/opacity writes only, no DOM layout
  reads in the rAF loop, no work while the section is off-screen.

## 2. llms.txt — required

- `public/llms.txt`, served at `/llms.txt`. Format per llmstxt.org:
  `# Site Name` H1, `> ` blockquote summary, then `##` sections of
  `- [Label](url): one-line note` links — markdown mirrors of pages first,
  then key external links (hours/location, regulator pages, etc.).
- **Markdown mirrors.** `public/index.md` mirrors the homepage content. On
  multi-page sites, each page gets a `<slug>.md` mirror.
- **Discovery.** In the layout `<head>`:
  `<link rel="alternate" type="text/markdown" href="/index.md">` and
  `<link rel="describedby" href="/llms.txt">`.
- **Header signal.** In `src/worker.ts`, append
  `Link: </llms.txt>; rel="describedby"` to `text/html` responses so agents
  that never parse the HTML still find it.
- Keep llms.txt honest — same claims as the page, no invented services.

## 3. WebMCP — optional progressive enhancement

WebMCP is a **draft** spec (W3C WebML CG; Chrome early preview Feb 2026).
Include it on new sites, but treat it as an enhancement layer:

- Always feature-detect: `if ('modelContext' in navigator)` — never gate any
  user-facing functionality on it.
- Register a small tool set via `navigator.modelContext.registerTool()`:
  read-only tools (`get_business_info`, `get_services`, `get_pricing`,
  `get_hours`) returning data sourced from the same `src/site.ts` the page
  renders — no duplicated facts.
- One action tool max (`submit_contact`) that posts to the same
  `/api/contact` endpoint the form uses — never a parallel pipeline.
- Keep the script inline, tiny (<3 KB), and `defer`-safe.

## 4. Standing conventions (unchanged)

- Contact form → `POST /api/contact` in `src/worker.ts` → Resend
  (`noreply@notifiq.net`, shared key as `RESEND_API_KEY` secret, honeypot
  field, `reply_to` = submitter). Leads land on `NOTIFY_EMAIL`.
- `src/site.ts` is the single source of business facts (name, phone, hours,
  pricing) — components read it, nothing hardcodes it.
- `site.demo: true` shows the demo banner; flip at go-live.
- **Client URLs: `<slug>.mydigitalharbor.com`** (e.g.
  `zingler.mydigitalharbor.com`) — clean demo/hosting URL without the client
  buying a domain. When a custom domain lands, it becomes canonical; set the
  canonical/og:url/sitemap/robots/llms.txt URLs to the public URL and
  redeploy. The `*.workers.dev` slug stays internal plumbing.
- Footer carries the "Site by Digital Harbor" mark (copper `#d97b45` dot →
  mydigitalharbor.com).
- Deploy: `source .envrc` (DH account token via terraform-cloudflare-factory)
  → `just deploy` — always the recipe, **never bare `npx wrangler deploy`**.
  The worker ships `./dist`, and `deploy` depends on `build` precisely
  because a stale bundle ships stale HTML + stale `public/` assets
  (claritycare went live with the old OG and pre-restyle HTML this way,
  2026-10-23). Worker secrets via `just email-secret`.
- **Prove the new build is live before verifying anything.** After deploy,
  grep the served HTML for a marker only the new build emits (a class, font
  name, unique string): `curl -s <url>/ | grep -o '<marker>'`. For binary
  assets, diff bytes: `curl -s <url>/images/og.png | md5sum` vs the local
  file. Only *then* run Lighthouse / the mobile sweep — scores measured on
  a stale deploy are fiction.
- Register new sites in `terraform-cloudflare-factory/registry/sites.yaml` +
  `DigitalHarbor/src/data/sites.ts`, and update Twenty (company + person +
  CUSTOMER opportunity + project note).
