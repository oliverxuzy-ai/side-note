# HoverNote — Unit Test Plan

> Scope of this round: lock down the four features added on top of the M0–M4
> baseline (live-edit gaps, configurable hotkey, slash menu) and the version
> tooling. Storage/ULID/frontmatter already have a green baseline (see
> `SideNoteTests.swift` / `NoteStoreTests.swift`) — not re-planned here.

## Principles

- **xcodebuild is the only truth.** SourceKit cross-file false-positives are
  ignored; a test "exists" only when it runs under `xcodebuild … test`.
- **Test the seam, not the pixels.** AppKit drawing (bullets, code-block
  rounding, the floating panel position) is verified by the owner visually.
  Unit tests cover the *logic that decides* what gets drawn: regexes, the
  `highlight()` attribute pass, pure model functions, persistence round-trips.
- **No mock where a real object is cheap.** `highlight()` runs against a real
  `NSTextStorage`; hotkey persistence runs against real `UserDefaults` (key
  cleaned in `tearDown`).

## Coverage matrix

| Area | Unit | What it asserts | Not unit-tested (why) |
|------|------|-----------------|------------------------|
| Live-edit · ordered list | `testOrderedListRegex` | `^(\s*)\d+\. ` anchored; captures leading WS; rejects `1.x`, `1)`, mid-line | marker glyph position (visual) |
| Live-edit · highlight pass | `testHighlightMarksCodeBlock` | every fenced line incl. ``` gets `.snCodeBlock` + mono; inline `*` inside NOT bolded | rounded bg + hairline (CoreGraphics draw) |
| | `testHighlightMarksQuote` | `.snQuote` set + paragraph `firstLineHeadIndent == 12` | 2pt sage bar (draw) |
| | `testHighlightHangsLists` | bullet/ordered/task lines get a `paragraphStyle` with `headIndent > firstLineHeadIndent` | wrap alignment (visual) |
| | `testHighlightTaskCheckboxAttr` | `- [ ]`→`.snCheckbox=false`; `- [x]`→`true` + strikethrough on content | clickable toggle (NSTextView event) |
| | `testHighlightInlineCodeBackground` | inline code content run gets `.backgroundColor` | corner radius/padding (Text API limit) |
| Slash · model | `testSlashFilterMatchesTitleAndKeywords` | ``""``→8; `todo`/`h1`/`num` hit; `zzz`→∅; case-insensitive | — |
| | `testSlashCommandSnippetsWellFormed` | every `caretOffset` in-bounds; titles unique; code-block caret on empty middle line | — |
| Slash · trigger | `testSlashTriggerRegex` | fires at line start / after space; letters-only token; anchored to caret end; not mid-word | caret-rect math, panel show/hide (AppKit) |
| Hotkey · persistence | `testRevealHotkeyDefault` | unset → ⌃⇧Space; `displayString == "⌃⇧␣"` | global RegisterEventHotKey (system) |
| | `testRevealHotkeySaveLoadReset` | save→load round-trips carbon code+mods; reset → default; posts `didChange` | recorder NSView keyDown (event) |
| Version tooling | `testVersionFileIsSemver` | `VERSION` is `X.Y.Z` and matches `MARKETING_VERSION` in `project.yml` | CI workflow, dmg packaging (integration) |

## Out of scope (deliberately)

- `HotkeyService` global registration — needs the window server; covered by
  manual smoke (press the shortcut).
- `SlashMenuController` panel placement / `NSTextView.doCommandBy` routing —
  AppKit responder chain; manual smoke.
- DMG pipeline & GitHub Action — integration, exercised by an actual tag push.

## Exit criterion

`xcodebuild -project SideNote.xcodeproj -scheme SideNote -configuration Debug
test` → all green, every row above (except "not unit-tested") has a passing
case.
