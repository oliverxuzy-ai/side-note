<div align="center">

# HoverNote

**A Mac sidebar Markdown notebook that slides in from the edge of your screen.**
The most quietly beautiful notes app on macOS — or it's not worth shipping.

**English** · [简体中文](README.zh-CN.md)

![platform](https://img.shields.io/badge/platform-macOS%2014%2B-1F1E18?style=flat-square)
![swift](https://img.shields.io/badge/Swift-5.10-6E8060?style=flat-square)
![SwiftUI](https://img.shields.io/badge/SwiftUI-native-6E8060?style=flat-square)
[![release](https://img.shields.io/github/v/release/oliverxuzy-ai/HoverNote?sort=semver&style=flat-square&color=6E8060&label=release)](https://github.com/oliverxuzy-ai/HoverNote/releases/latest)
![license](https://img.shields.io/badge/license-MIT-6E8060?style=flat-square)

</div>

> **North star** — the 0.4-second body state change when the panel slides out
> from the screen edge. Every decision in this project serves that single moment.

---

## What it is

A native macOS app (macOS 14+, SwiftUI) that lives in your **menu bar** and
slides out from the right edge on a hotkey or an edge-hover. You write Markdown
that styles itself as you type — Bear-style, no edit/preview switch. You pin or
delete notes with a swipe. You close it, and it slides off-screen the same way.

It's not trying to be the most powerful note tool. It's trying to be the one
your shoulders relax around.

Every note is a plain `.md` file with YAML frontmatter on disk — open them in
Obsidian, Vim, or any editor. No database, no sync, no lock-in.

---

## Install

Grab the latest **`HoverNote-x.y.z.dmg`** from
**[Releases](https://github.com/oliverxuzy-ai/HoverNote/releases/latest)**.

1. Double-click the `.dmg` to mount it
2. Drag **HoverNote.app** onto the **Applications** shortcut
3. **First launch — right-click the app → Open** (then *Open* again in the dialog)

> Step 3 is required only once. HoverNote is self-signed (ad-hoc), not
> notarized, so macOS Gatekeeper refuses a plain double-click the first time.
> Right-click → Open tells macOS you trust it; after that it launches normally.
> Notarization is a v2 item.

**Requirements**: macOS 14.0 (Sonoma) or later · Apple Silicon & Intel.

There is no Dock icon — HoverNote lives in the **menu bar**. Click the menu-bar
icon or press your reveal shortcut (default `⌃⇧Space`) to slide it in.

---

## Features

- **Three ways in** — menu-bar icon, a global hotkey, or right-edge hover
  (opt-in, off by default; needs Accessibility permission). The hotkey is
  **configurable** in Preferences with a key recorder (defaults to `⌃⇧Space`).
- **Real slide-in** — a single SwiftUI spring drives the whole surface; live
  `.regularMaterial` glass over your wallpaper.
- **Live Markdown editing** — Bear-style, no edit/preview toggle. Markers stay
  visible but recede. H1–H3, **bold**, *italic*, `inline code`, links, fenced
  code blocks (rounded panel), blockquotes (sage rule) style themselves as you
  type. Real `•` bullets, ordered lists with proper hanging indent, and
  clickable `- [ ]` / `- [x]` to-do checkboxes. Cursor and undo are never
  disrupted.
- **Slash menu** — type `/` for a menu: Heading 1–3, bullet list, to-do,
  numbered list, quote, code block. Arrow keys or mouse, ↵ to insert.
- **Swipe actions** — swipe a card right to pin/unpin, left to delete. Works
  with **trackpad two-finger** and mouse drag.
- **Plain-file storage** — atomic writes, FSEvents two-way sync, an
  external-edit conflict banner, delete-to-Trash.
- **Pinned notes** — a small sage pin on the card; pinned notes float to top.
- **Title + tag search.**
- **Considered interaction craft** — hover feedback on every control, sage
  selection language shared across cards and menus, restrained motion.
- **Sage monochrome** — one hue, no warm color anywhere ([`DESIGN.md`](DESIGN.md)).

### Keyboard

| Shortcut | Action |
|----------|--------|
| `⌃⇧Space` *(configurable)* | Toggle the panel |
| `/` | Slash command menu (in the editor) |
| `⌘N` | New note |
| `⌘F` | Focus search |
| `⌘P` | Pin / unpin selected |
| `⌘⌫` | Delete selected (to Trash) |
| `⌘,` | Preferences |

---

## Design system

Everything visual lives in [`DESIGN.md`](DESIGN.md). The short version:

| Layer | Value |
|-------|-------|
| Canvas | SwiftUI 3-layer glass: `.regularMaterial` + sage tint 10% + warm wash 20% |
| Accent | `#6E8060` refined rosemary sage — the only color in the system |
| Surface | `rgba(255,255,255,0.55)` translucent cards over the glass |
| Display | PP Editorial New *(not bundled yet — falls back to a system serif)* |
| Body | General Sans (Fontshare, bundled) |
| Mono | JetBrains Mono (Apache-2.0, bundled) |
| Base unit | 4pt (macOS HIG) |
| Slide-in | 0.42s spring · slide-out 0.22s ease-in |

If you touch visual code, read `DESIGN.md` first. No deviation without an
explicit, recorded reason.

---

## Build from source

This repo uses [xcodegen](https://github.com/yonaskolb/XcodeGen) — the Xcode
project is a declarative `project.yml`, not a binary blob. `SideNote.xcodeproj`
is intentionally gitignored. (The Xcode target / Swift module is still named
`SideNote` internally; only the product is **HoverNote** — see the rename note
in [`DESIGN.md`](DESIGN.md).)

```bash
brew install xcodegen          # one-time

xcodegen generate              # after clone, or after editing project.yml
open SideNote.xcodeproj        # then ⌘R
```

```bash
# command line, no Xcode UI
xcodegen generate
xcodebuild -project SideNote.xcodeproj -scheme SideNote -configuration Debug build
xcodebuild -project SideNote.xcodeproj -scheme SideNote -configuration Debug test
```

**Requirements** — Xcode 16+ (CI pins latest-stable), macOS 14.0+ deployment
target, no Apple Developer account for local dev (ad-hoc *Sign to Run Locally*).

### Releases are automatic

Every push to `main` runs `.github/workflows/release.yml`, which derives the
next version from conventional commits (`feat` → minor, `fix` → patch; docs/
chore → no release), builds the signed-to-run `.dmg`, and publishes a public
GitHub release. A major bump is manual (Actions → Release → *Run workflow* →
`bump = major`). `VERSION` + `scripts/` back the local path.

---

## Stack

- **Swift 5.10 / SwiftUI**, macOS 14.0 minimum.
- **Live Markdown** — regex highlighter + a custom `NSLayoutManager` that draws
  bullets/checkboxes and code-block / quote backgrounds (no Markdown library;
  `swift-markdown` was dropped).
- **Swipe & hover** — hand-rolled: `scrollWheel` for trackpad two-finger,
  `NSPanGestureRecognizer` for mouse drag, `NSTrackingArea` for reliable hover
  (no UI library).
- **Hotkey** — [`soffes/HotKey`](https://github.com/soffes/HotKey) *(the only
  dependency)*.
- **Storage** — filesystem, `~/Documents/SideNote/<ULID>.md`.
- **Edge-hover** — `CGEventTap` (why there is no Mac App Store build for v1).
- No Rust, no Electron, no Tauri. Native materials are the whole point.

---

## Scope

**In** — slide-in/out (3 triggers, configurable hotkey), live Markdown editing
incl. to-do, slash menu, swipe-to-pin/delete, pin, tags, title+tag search, note
CRUD, light theme, FSEvents two-way sync, automated self-signed `.dmg`
releases.

**Out for now** — dark theme (needs its own mood board), cloud sync, iOS, AI
features, Mac App Store (sandbox blocks `CGEventTap`), notarization, Markdown
tables/images (v1.1), pin drag-physics (v1.1).

**Out forever (probably)** — tags-as-folders, nested categories, anything that
asks you to pre-classify. The app rewards writing, not filing.

---

## Known gaps

Honest about what's not done:

- **PP Editorial New display font isn't bundled** — headlines fall back to a
  system serif (the font is gated behind an email on the foundry site).
- **No demo video yet.**
- **Search field focus ring doesn't render** — a SwiftUI focus/hover quirk in
  the nonactivating panel; tracked, low impact.

---

## Roadmap

- **Shipped** — light theme, live Markdown (incl. to-do + slash menu),
  swipe actions, configurable hotkey, automated public releases.
- **v1.1** — Markdown images & tables, pin drag-physics, search-ring fix,
  bundled display font + demo, more polish.
- **v2** — dark theme (its own mood board → `/design-consultation`),
  notarization, Sparkle auto-update, possibly an iOS companion.

---

## Acknowledgments

- **Kinfolk** — for proving sage can be a brand.
- **Things 3 (Cultured Code)** — the bar for Mac-native craft.
- **Linear** — monochrome design systems aren't boring.
- **Bear** — the live-editing model: style as you type, no mode switch.
- **PP Editorial New** (Pangram Pangram) · **General Sans** (Indian Type
  Foundry) · **JetBrains Mono** — the typefaces.
- **SideNotes** — the category-defining workhorse we're trying to out-design.

---

## License

[MIT](LICENSE) © 2026 oliverxuzy. Do whatever you want with the code.

Bundled third-party fonts keep their own licenses and are **not** covered by
MIT: General Sans (Fontshare free license), JetBrains Mono (Apache-2.0), and
PP Editorial New (Pangram Pangram terms, if added). See
[`THIRD-PARTY-NOTICES.md`](THIRD-PARTY-NOTICES.md).

---

<div align="center">

*Built with patience by [@oliverxuzy](https://github.com/oliverxuzy-ai).*

</div>
