# HoverNote

Mac sidebar Markdown 笔记 App，SwiftUI 原生，macOS 14+。

## Design System

**Always read `DESIGN.md` before making any visual or UI decisions.**

All font choices, colors, spacing, motion, and aesthetic direction are defined there.
Do not deviate without explicit user approval. In QA mode, flag any code that doesn't
match DESIGN.md.

Key locks:
- Canvas: `#F1F2E9` (sage-tinted near-white, vibrancy implemented via NSVisualEffectView)
- Accent: `#6E8060` refined rosemary sage (the only color in the system — no warm hue anywhere)
- Display: PP Editorial New / Body: General Sans / Mono: JetBrains Mono
- Memorable thing: "the 0.4s body state change when the panel slides out from screen edge"

## Project Artifacts

- Design system: `DESIGN.md` (this repo)
- Original design doc: `~/.gstack/projects/side-note/zhengyangxu-unknown-design-20260514-194317.md`
- Mood board (light): `~/.gstack/projects/side-note/mood-board-light.png`
- Design preview history: `~/.gstack/projects/side-note/designs/design-system-20260514/`
