---
title: F5.1 — Track Import
feature: F5.1
version: V0.1
phase: "Phase 5 — Backing Tracks"
status: proposed
tags:
  - feature-pr
  - v0-1
---

# F5.1 — Track Import

[[../releases/v0-1|← V0.1]] · [[../implementation-plan|Plan index]]

## Task PR checklist

- [x] [[#Task PR F5.1.1 — Document picker|F5.1.1 — Document picker]]
- [x] [[#Task PR F5.1.2 — Backing track model|F5.1.2 — Backing track model]]
- [x] [[#Task PR F5.1.3 — File management|F5.1.3 — File management]]

## Task PR F5.1.1 — Document picker

Import common audio formats.

## Task PR F5.1.2 — Backing track model

```swift
struct BackingTrack {
    let id: UUID
    let fileURL: URL
    var name: String
}
```

## Task PR F5.1.3 — File management

Imported audio becomes owned by the app rather than relying permanently on an external URL.

---
