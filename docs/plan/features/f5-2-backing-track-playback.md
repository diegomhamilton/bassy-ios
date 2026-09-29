---
title: F5.2 — Backing Track Playback
feature: F5.2
version: V0.1
phase: "Phase 5 — Backing Tracks"
status: proposed
tags:
  - feature-pr
  - v0-1
---

# F5.2 — Backing Track Playback

[[../releases/v0-1|← V0.1]] · [[../implementation-plan|Plan index]]

## Task PR checklist

- [x] [[#Task PR F5.2.1 — Player node|F5.2.1 — Player node]]
- [x] [[#Task PR F5.2.2 — Transport|F5.2.2 — Transport]]
- [x] [[#Task PR F5.2.3 — Track gain|F5.2.3 — Track gain]]
- [x] [[#Task PR F5.2.4 — Session UI|F5.2.4 — Session UI]]

## Task PR F5.2.1 — Player node

Add:

```text
AVAudioPlayerNode
```

to the audio graph.

## Task PR F5.2.2 — Transport

Implement:

```text
play
pause
stop
seek
```

## Task PR F5.2.3 — Track gain

Backing-track gain is independent from instrument gain.

## Task PR F5.2.4 — Session UI

Example:

```text
BACKING TRACK

Come Together.mp3

00:42 ━━━━━━━●━━━━━━━━ 04:18

      ◀︎    ▶︎    ■

Volume ━━━━━━━━━●━━
```

## Feature acceptance criteria

Backing track and live bass play simultaneously.

Bass remains independently recordable.

---
