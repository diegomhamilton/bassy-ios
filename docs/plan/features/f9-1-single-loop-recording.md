---
title: F9.1 — Single Loop Recording
feature: F9.1
version: V0.2
phase: "Phase 9 — Basic Looper"
status: proposed
tags:
  - feature-pr
  - v0-2
---

# F9.1 — Single Loop Recording

[[../releases/v0-2|← V0.2]] · [[../implementation-plan|Plan index]]

## Task PR checklist

- [x] [[#Task PR F9.1.1 — Loop model|F9.1.1 — Loop model]]
- [x] [[#Task PR F9.1.2 — First-pass recording|F9.1.2 — First-pass recording]]
- [x] [[#Task PR F9.1.3 — Seamless playback|F9.1.3 — Seamless playback]]
- [x] [[#Task PR F9.1.4 — Loop state machine|F9.1.4 — Loop state machine]]
- [x] [[#Task PR F9.1.5 — Basic looper UI|F9.1.5 — Basic looper UI]]

## Task PR F9.1.1 — Loop model

```swift
struct Loop {
    let id: UUID

    var name: String

    let fileURL: URL
    let frameCount: AVAudioFrameCount

    var volume: Float
    var muted: Bool
}
```

## Task PR F9.1.2 — First-pass recording

Workflow:

```text
Record Loop
    ↓
play bass
    ↓
Stop
    ↓
loop length established
    ↓
loop begins repeating
```

## Task PR F9.1.3 — Seamless playback

Loop playback must repeat without audible scheduling gaps or clicks.

## Task PR F9.1.4 — Loop state machine

```swift
enum LoopState {
    case empty
    case recording
    case playing
    case muted
}
```

## Task PR F9.1.5 — Basic looper UI

Before recording:

```text
┌───────────────────────┐

       LOOP 1

       ● RECORD

└───────────────────────┘
```

After recording:

```text
┌───────────────────────┐

       LOOP 1

       ▶ PLAYING

    MUTE      CLEAR

└───────────────────────┘
```

## Feature acceptance criteria

User can create one loop and play bass over it indefinitely.

---
