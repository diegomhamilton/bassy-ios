---
title: iOS Bass App — Implementation Plan
aliases:
  - Implementation Plan
tags:
  - ios
  - audio
  - product-plan
status: proposed
---

# iOS Bass App — Implementation Plan

This is the review index for the V0.1–V0.5 plan. Review release scope first, then open individual Feature PR notes for atomic task and acceptance-criteria review.

## Release scope

- [[releases/v0-1|V0.1 — Play, Process, Record]]
- [[releases/v0-2|V0.2 — Basic Looper]]
- [[releases/v0-3|V0.3 — Metronome and Practice Timing]]
- [[releases/v0-4|V0.4 — Backing Tracks]]
- [[releases/v0-5|V0.5 — Workflow, Reliability, and Export]]
- [[releases/backlog|Backlog — Unscheduled features]]

Each versioned release file contains checked-by-default feature scope. Uncheck a feature to propose moving it to Backlog.

## Delivery and architecture

- [[reference/delivery-model|Delivery model]]
- [[reference/recommended-merge-order|Recommended merge order]]
- [[reference/parallelizable-work|Parallelizable work]]
- [[reference/pr-and-task-conventions|PR and Task conventions]]
- [[reference/architecture-rules|Architecture rules]]
- [[reference/deferred-work|Deferred work]]
- [[reference/expected-product-states|Expected product states]]

## Traceability

- [[features/f0-2-simplified-practice-ui|F0.2 — Simplified Practice UI]] — added after navigation exploration; prioritize before further V0.1 features.
- [[archive/implementation-plan-full|Archived full plan]] — preserved source before splitting.
- [[../prompts/codex-kickoff|Initial Codex session guideline]]
- [[../snapshots/README|Human-checkpoint snapshot conventions]]

> [!important]
> Feature files are the atomic review units. Release files own scope selection. Reference files own cross-cutting engineering rules.
