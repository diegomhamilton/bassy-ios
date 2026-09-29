---
title: iOS Bass App
aliases:
  - Bass App Project Home
tags:
  - ios
  - audio
  - project
---

# iOS Bass App

An Obsidian-ready project vault for a native iOS practice and recording app for bass and guitar.

## Current implementation

F0.1 provides a native SwiftUI application shell with explicit dependency
injection, structured logging, unit tests, and Session, Tone, and Library
destinations. Open `BassPractice.xcodeproj` in Xcode and run the
`BassPractice` scheme on an iOS 17 or newer simulator.

## Start here

- [[docs/plan/implementation-plan|Implementation plan through V0.4]] — review release scope and toggle feature checklists.
- [[docs/prompts/codex-kickoff|Codex kickoff guideline]] — use this to begin the first implementation session.
- [iOS feature validation skill](.agents/skills/ios-feature-validation/SKILL.md) — build, test, launch, reject boot-screen captures, and assemble review evidence after implementation.
- [[docs/prompts/README|Agent prompt rules]] — every prompt crafted for another agent belongs here.
- [[docs/snapshots/README|Snapshot conventions]] — required evidence at human-review checkpoints.
- [[docs/snapshots/2026-09-29_F0-1_application-skeleton/README|F0.1 application skeleton checkpoint]] — build, test, and simulator evidence.

## Product direction

The app begins as a reliable practice and recording tool: select an input and instrument profile, monitor through gain/EQ/effects, play backing tracks, record, loop, and restore sessions. Later releases add metronome-aware practice, advanced loop editing, richer tone workflows, diagnostics, and export.

## Working agreement

Implementation is delivered as small Task PRs stacked into Feature PRs. Use the repository's `$ios-feature-validation` skill after implementation. A human-review checkpoint is ready only after the required validation route has built and tested the app, launched the simulator, captured verified screens, and documented the evidence under `docs/snapshots/`.

> [!important]
> Open this folder itself as the Obsidian vault. Keep implementation decisions, agent prompts, and review evidence linked from this home note.
