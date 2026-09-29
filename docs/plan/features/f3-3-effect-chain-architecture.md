---
title: F3.3 — Effect Chain Architecture
feature: F3.3
version: V0.1
phase: "Phase 3 — DSP V1"
status: proposed
tags:
  - feature-pr
  - v0-1
---

# F3.3 — Effect Chain Architecture

[[../releases/v0-1|← V0.1]] · [[../implementation-plan|Plan index]]

## Task PR checklist

- [x] [[#Task PR F3.3.1 — Effect model|F3.3.1 — Effect model]]
- [x] [[#Task PR F3.3.2 — Effect ordering|F3.3.2 — Effect ordering]]
- [x] [[#Task PR F3.3.3 — Bypass|F3.3.3 — Bypass]]
- [x] [[#Task PR F3.3.4 — Effect preset persistence|F3.3.4 — Effect preset persistence]]

This is primarily an architectural PR.

## Task PR F3.3.1 — Effect model

```swift
struct EffectChain {
    var effects: [EffectConfiguration]
}
```

## Task PR F3.3.2 — Effect ordering

Support:

```text
Gain
 ↓
EQ
 ↓
Effect A
 ↓
Effect B
 ↓
Output
```

## Task PR F3.3.3 — Bypass

Every processor supports bypass.

## Task PR F3.3.4 — Effect preset persistence

Create:

```swift
struct EffectPreset {
    let id: UUID
    var name: String
    var inputProfile: UUID?
    var effects: [EffectConfiguration]
}
```

## Feature acceptance criteria

Architecture supports adding future processors without modifying the recorder or mixer.

---
