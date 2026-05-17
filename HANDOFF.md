# HANDOFF — HoverNote

> Fresh-context handoff. Read this + `DESIGN.md` + `PLAN.md` before working.

## Goal

A Mac menu-bar app: a sage-glass Markdown notes panel that slides in from the
right screen edge. SwiftUI, macOS 14+, native materials. **North star: the
0.4-second body state change when the panel slides out.** Design *is* the
product — interaction/animation craft is judged at Bear / Things 3 / Linear
tier; "generic" is a failure (this bar is non-negotiable, see Memory below).

Repo: `git@github.com:oliverxuzy-ai/HoverNote.git` · branch `main` · latest
commit `b5f49a2`. Local-only `changes.md` is auto-appended by a `pre-push`
git hook (gitignored, not in repo).

## Current progress

Milestones M0–M4 complete + two rounds of post-DMG user feedback shipped:

- **M0–M2**: xcodegen scaffold, NSPanel single-spring slide + 3-layer glass +
  triple shadow, file storage (`~/Documents/SideNote/<ULID>.md`, YAML
  frontmatter, FSEvents sync, atomic writes), search, CRUD.
- **M3**: General Sans + JetBrains Mono bundled & runtime-registered;
  micro-motion tokens; edge-hover trigger (CGEventTap + Accessibility,
  opt-in via Preferences).
- **M4**: `.dmg` pipeline works. **GitHub release `v0.1.0` is cut as a DRAFT**
  (`isDraft: true`, tag pushed, `HoverNote-0.1.0.dmg` attached). NOT public.
- **Post-feedback**: live Markdown editing (Bear-style, no edit/preview
  toggle — regex highlighter + custom `NSLayoutManager` drawing real `•`
  bullets and clickable `☐/☑` to-do; markers recede but text is intact);
  `swift-markdown` dependency removed; swipe-to-pin (right) / swipe-to-delete
  (left) with **trackpad two-finger** (custom `scrollWheel`) + mouse drag
  (`NSPanGestureRecognizer`); MIT `LICENSE` added.

17 unit tests green (storage round-trip, ULID, highlighter regex tokenization).
HotKey is the only remaining SPM dependency.

## What worked

- **Verify with `xcodebuild`, ignore SourceKit** — SourceKit constantly
  false-flags "cannot find type X" cross-file. Only `xcodebuild` is truth.
- Build/test: `xcodegen generate` then
  `xcodebuild -project SideNote.xcodeproj -scheme SideNote -configuration Debug build|test`.
- `.dmg`: `xcodebuild -configuration Release archive` → copy
  `HoverNote.app` from `*.xcarchive/Products/Applications/` → `create-dmg`
  (route A = ad-hoc "Sign to Run Locally", no exportArchive).
- Live editing without breaking cursor/undo: only change *attributes* (and
  draw glyphs in a custom layout manager), never mutate the text buffer.
- Hand-rolled gestures over libraries — keeps zero extra deps and full
  control of feel (project ethos).
- Every behavior/scope change is logged in `DESIGN.md` Decisions Log — keep
  doing this; it is the project's discipline.

## What didn't work / gotchas

- **`NSPanGestureRecognizer.allowedScrollTypesMask` does NOT exist on macOS**
  (UIKit-only). Trackpad two-finger swipe MUST be handled via
  `scrollWheel(with:)` (precise deltas + phase). Mouse drag via pan recognizer.
- **`.frame(width: 0)` does NOT clip in SwiftUI** — a `Color` background
  bled outside as colored bands behind every card. Fix: conditionally render
  + `.clipped()` (see `SwipeableCard.swift`).
- **Concurrent xcodebuild on shared DerivedData corrupts codesign** (the
  embedded test bundle ends up unsigned → "Command CodeSign failed"). Don't
  run a background archive while foreground-building. Fix: `rm -rf` the
  project's DerivedData dir and rebuild.
- `create-dmg` fails if a stale `/Volumes/HoverNote` is mounted — detach
  first. And zsh aborts a `&&` chain if a glob (`/Volumes/HoverNote*`) has
  no match — guard globs.
- Publishing the GitHub release was blocked by the auto-mode classifier; the
  user ran the `gh release` / tag push themselves (or grants permission).
- PP Editorial New (display font) is gated behind an email/click on
  pangrampangram.com — cannot be fetched programmatically.

## Next steps

1. **Owner-only, blocks public v0.1.0** (not code):
   - Drop `PPEditorialNew-Regular.otf` + `PPEditorialNew-Italic.otf` into
     `SideNote/Resources/Fonts/` (code auto-detects by PostScript name; until
     then headlines fall back to system serif — `EditorFont`/`Typography`).
   - Record the 30-second demo (slide-in → switch → create → pin → slide-out).
   - Then rebuild the `.dmg`, replace the draft-release asset, and the user
     publishes (un-drafts) `v0.1.0`. Do NOT publish unilaterally.
2. After font is added: rebuild Release `.dmg`, send to user to verify the
   north-star feel with real type.
3. Open follow-ups the user may raise: image thumbnails on cards (v1.1; no
   image attachments in v1), further animation polish.

## Map

- `SideNote/Features/Editor/LiveMarkdownEditor.swift` — live editor,
  `MarkdownLayoutManager`, `MarkdownTextView`, highlighter regexes.
- `SideNote/Features/Sidebar/SwipeableCard.swift` — swipe (scrollWheel +
  pan), action tiles. `NoteCard.swift` — card visuals (current = original
  layout + small footer pin).
- `SideNote/DesignSystem/` — `DesignTokens` (colors/motion), `Typography`,
  `FontRegistration`, `Interactions` (button styles).
- `SideNote/Core/` — `Storage` (NoteStore/NoteFile/FrontmatterCodec/ULID),
  `Triggers` (PanelController/HotkeyService/EdgeHoverService), `Window`.
- `DESIGN.md` = visual source of truth (sage monochrome, **no warm/red** —
  delete swipe uses near-black). `PLAN.md` = milestone log.

## Memory

Persistent feedback memory recorded: this user holds HoverNote to
Bear/Things-tier interaction craft; lead with the crafted version, never the
first thing that compiles; respect DESIGN.md's ban on decorative loaders
(local IO is instant — no shimmer/spinners).
