---
title: F1.2 — Audio Engine Core
feature: F1.2
version: V0.1
phase: "Phase 1 — Audio Hardware Foundation"
status: proposed
tags:
  - feature-pr
  - v0-1
---

# F1.2 — Audio Engine Core

[[../releases/v0-1|← V0.1]] · [[../implementation-plan|Plan index]]

## Task PR checklist

- [x] [[#Task PR F1.2.1 — Engine lifecycle|F1.2.1 — Engine lifecycle]]
- [x] [[#Task PR F1.2.2 — Input node integration|F1.2.2 — Input node integration]]
- [x] [[#Task PR F1.2.3 — Monitoring|F1.2.3 — Monitoring]]
- [x] [[#Task PR F1.2.4 — Audio format diagnostics|F1.2.4 — Audio format diagnostics]]
- [x] [[#Task PR F1.2.5 — Interruption recovery|F1.2.5 — Interruption recovery]]

## Task PR F1.2.1 — Engine lifecycle

Create an `AudioEngine`.

Responsibilities:

```text
configure graph
start
stop
restart after route change
report engine state
```

Suggested state:

```swift
enum AudioEngineState {
    case stopped
    case starting
    case running
    case interrupted
    case failed(Error)
}
```

## Task PR F1.2.2 — Input node integration

Connect:

```text
AVAudioInputNode
        ↓
instrument processing
        ↓
main mixer
        ↓
output
```

Initially processing can simply pass the signal through.

## Task PR F1.2.3 — Monitoring

Add live monitoring:

```text
Input → Engine → Output
```

Expose:

```swift
monitoringEnabled
monitoringGain
```

## Task PR F1.2.4 — Audio format diagnostics

Record and display/debug:

- sample rate;
- channel count;
- input format;
- output format;
- IO buffer duration.

This PR is especially useful for testing Cube Baby compatibility.

## Task PR F1.2.5 — Interruption recovery

Handle:

- phone interruption;
- audio session interruption;
- device disconnect;
- route changes.

## Feature acceptance criteria

Bass connected through the interface can be heard through the configured output continuously.

---
