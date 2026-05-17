<div align="center">

# HoverNote

**A Mac sidebar Markdown notebook that slides in from the edge of your screen.**
The most quietly beautiful notes app on macOS — or it's not worth shipping.

![platform](https://img.shields.io/badge/platform-macOS%2014%2B-1F1E18?style=flat-square)
![swift](https://img.shields.io/badge/Swift-5.10-6E8060?style=flat-square)
![ui](https://img.shields.io/badge/SwiftUI-native-6E8060?style=flat-square)
![status](https://img.shields.io/badge/status-v0.1.0%20(draft)-B8C2A8?style=flat-square)
![license](https://img.shields.io/badge/license-MIT-6E8060?style=flat-square)

</div>

> **North star** — the 0.4-second body state change when the panel slides out
> from the screen edge. Every decision in this project serves that single moment.

---

## What it is

A native macOS app (macOS 14+, SwiftUI) that lives in your menu bar and slides
out from the right edge on a global hotkey or an edge-hover. You write Markdown
that styles itself as you type (Bear-style, no edit/preview switch). You pin or
delete notes with a swipe. You close it — and it slides off-screen the same way.

It's not trying to be the most powerful note tool. It's trying to be the one
your shoulders relax around.

Every note is a plain `.md` file with YAML frontmatter in `~/Documents/SideNote/`.
Open them in Obsidian, Vim, or any editor. No database, no sync, no lock-in.

---

## Current state

| Milestone | Scope | State |
|-----------|-------|-------|
| **M0** Setup | xcodegen scaffold, SwiftUI app, deps | ✅ done |
| **M1** Slide-in spike | NSPanel + single-spring slide, glass, shadow | ✅ done |
| **M2** Core read/write | file storage, Markdown render, editor, search, CRUD | ✅ done |
| **M3** Visual polish | fonts, typography, micro-motion, edge-hover | ✅ code done · ⏳ fonts/demo |
| **M4** Ship | self-signed `.dmg` on GitHub Releases | ✅ draft cut · ⏳ publish |
| **post** Feedback iter | live editing, bullets/to-do, swipe-to-pin/delete | ✅ done |

**Two owner-only items remain before a public v0.1.0**: dropping the PP Editorial
New font into `SideNote/Resources/Fonts/` (display headlines fall back to a
system serif until then) and recording the 30-second demo. The release is cut as
a **GitHub draft** with the `.dmg` attached, pending those — see [`PLAN.md`](PLAN.md).

---

## Download & install

Once published, grab the latest `HoverNote-x.y.z.dmg` from
**[Releases](https://github.com/oliverxuzy-ai/HoverNote/releases)**.
*(v0.1.0 is currently a draft pending the demo + display font.)*

1. Double-click the `.dmg` to mount it
2. Drag **HoverNote.app** onto the **Applications** shortcut
3. **First launch — right-click the app → Open** (then *Open* again in the dialog)

> Step 3 is required once. HoverNote is self-signed (ad-hoc), not notarized, so
> macOS Gatekeeper will refuse a normal double-click the first time. Right-click
> → Open tells macOS you trust it. After that it launches normally. Notarization
> is a v2 item.

**Requirements**: macOS 14.0 (Sonoma) or later. Apple Silicon & Intel.

There is no Dock icon — HoverNote lives in the **menu bar**. Click the menu-bar
icon or press `⌃⇧Space` to slide it in.

---

## Features (v1)

- **Three ways in** — menu-bar icon, `⌃⇧Space` global hotkey, or right-edge
  hover (opt-in, off by default; needs Accessibility permission)
- **Real slide-in** — a single SwiftUI spring drives the whole surface; live
  `.regularMaterial` glass over your wallpaper
- **Live Markdown editing** — Bear-style, no edit/preview toggle. Markers stay
  visible but recede; H1–H3, **bold**, *italic*, `inline code`, code blocks,
  blockquotes, links style themselves as you type. Real `•` bullets and
  clickable `- [ ]` / `- [x]` to-do checkboxes. Cursor/undo never disrupted.
- **Swipe actions** — swipe a card right to pin/unpin, left to delete. Works
  with **trackpad two-finger** and mouse drag.
- **Plain-file storage** — atomic writes, FSEvents two-way sync, external-edit
  conflict banner, delete-to-Trash
- **Pinned notes** — small sage pin on the card; pinned float to the top
- **Title + tag search**
- **Sage monochrome** — one hue, no warm color anywhere ([`DESIGN.md`](DESIGN.md))

### Keyboard

| Shortcut | Action |
|----------|--------|
| `⌃⇧Space` | Toggle the panel |
| `⌘N` | New note |
| `⌘F` | Focus search |
| `⌘P` | Pin / unpin selected |
| `⌘⌫` | Delete selected (to Trash) |
| `⌘,` | Preferences |

---

## Design system

Everything visual lives in [`DESIGN.md`](DESIGN.md). The short version:

| Layer     | Value |
|-----------|-------|
| Canvas    | SwiftUI 3-layer glass: `.regularMaterial` + sage tint 10% + warm wash 20% |
| Accent    | `#6E8060` refined rosemary sage — the only color in the system |
| Surface   | `rgba(255,255,255,0.55)` translucent cards over the glass |
| Display   | PP Editorial New *(pending — falls back to system serif)* |
| Body      | General Sans (Fontshare, bundled) |
| Mono      | JetBrains Mono (Apache-2.0, bundled) |
| Base unit | 4pt (macOS HIG) |
| Slide-in  | 0.42s spring · slide-out 0.22s ease-in |

If you touch visual code, read `DESIGN.md` first. No deviation without an
explicit, recorded reason.

---

## Build from source

This repo uses [xcodegen](https://github.com/yonaskolb/XcodeGen) — the Xcode
project is a declarative `project.yml`, not a binary blob. `SideNote.xcodeproj`
is intentionally gitignored.

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

**Requirements** — Xcode 15+ (tested on 26.4), macOS 14.0+ deployment target,
no Apple Developer account for local dev (ad-hoc *Sign to Run Locally*).

---

## Stack

- **Swift 5.10 / SwiftUI**, macOS 14.0 minimum
- **Live Markdown** — regex highlighter + custom `NSLayoutManager` drawing
  bullets/checkboxes (no Markdown library; `swift-markdown` was dropped)
- **Swipe** — hand-rolled: `scrollWheel` for trackpad two-finger,
  `NSPanGestureRecognizer` for mouse drag (no swipe library)
- **Hotkey** — [`soffes/HotKey`](https://github.com/soffes/HotKey) *(only dependency)*
- **Storage** — filesystem, `~/Documents/SideNote/<ULID>.md`
- **Edge-hover** — `CGEventTap` (why there is no Mac App Store build for v1)
- No Rust, no Electron, no Tauri. Native materials are the whole point.

---

## Scope

**In v1** — slide-in/out (3 triggers), live Markdown editing (incl. to-do),
swipe-to-pin/delete, pin, tags, title+tag search, note CRUD, light theme only,
FSEvents two-way sync, self-signed `.dmg`.

**Out for now** — dark theme (needs its own mood board), cloud sync, iOS, AI
features, Mac App Store (sandbox blocks `CGEventTap`), notarization, Markdown
tables/images (v1.1), pin drag-physics (v1.1).

**Out forever (probably)** — tags-as-folders, nested categories, anything that
asks you to pre-classify. The app rewards writing, not filing.

---

## Roadmap

- **v1** *(~3–4 weeks solo)* — ship the light theme, beautiful enough for a
  30-second demo without cringing
- **v1.1** — images & tables in Markdown, pin drag-physics, more polish
- **v2** — dark theme (own mood board → own `/design-consultation`),
  notarization, Sparkle auto-update, possibly an iOS companion

---

## Acknowledgments

- **Kinfolk** — for proving sage can be a brand
- **Things 3 (Cultured Code)** — the bar for Mac-native craft
- **Linear** — monochrome design systems aren't boring
- **PP Editorial New** (Pangram Pangram) · **General Sans** (Indian Type
  Foundry) · **JetBrains Mono** — the typefaces
- **Bear** — the live-editing model: style as you type, no mode switch
- **SideNotes** — the category-defining workhorse we're trying to out-design

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
