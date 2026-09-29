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

## Start here

- [[docs/plan/implementation-plan|Implementation plan through V0.4]] — review release scope and toggle feature checklists.
- [[docs/prompts/codex-kickoff|Codex kickoff guideline]] — use this to begin the first implementation session.
- [[docs/prompts/README|Agent prompt rules]] — every prompt crafted for another agent belongs here.
- [[docs/snapshots/README|Snapshot conventions]] — required evidence at human-review checkpoints.

## Product direction

The app begins as a reliable practice and recording tool: select an input and instrument profile, monitor through gain/EQ/effects, play backing tracks, record, loop, and restore sessions. Later releases add metronome-aware practice, advanced loop editing, richer tone workflows, diagnostics, and export.

## Working agreement

Implementation is delivered as small Task PRs stacked into Feature PRs. A human-review checkpoint is ready only after XcodeBuildMCP has built and tested the app, launched the simulator, captured the relevant screens, and documented the evidence under `docs/snapshots/`.

> [!important]
> Open this folder itself as the Obsidian vault. Keep implementation decisions, agent prompts, and review evidence linked from this home note.
