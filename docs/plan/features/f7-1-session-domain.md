---
title: F7.1 — Session Domain
feature: F7.1
version: V0.1
phase: "Phase 7 — Session Persistence"
status: proposed
tags:
  - feature-pr
  - v0-1
---

# F7.1 — Session Domain

[[../releases/v0-1|← V0.1]] · [[../implementation-plan|Plan index]]

## Task PR checklist

- [x] [[#Task PR F7.1.1 — Session model|F7.1.1 — Session model]]
- [x] [[#Task PR F7.1.2 — Repository|F7.1.2 — Repository]]
- [x] [[#Task PR F7.1.3 — Serialization|F7.1.3 — Serialization]]
- [x] [[#Task PR F7.1.4 — Autosave|F7.1.4 — Autosave]]

## Task PR F7.1.1 — Session model

```swift
struct MusicSession {
    let id: UUID

    var name: String

    var inputProfileID: UUID?
    var effectPresetID: UUID?

    var recordings: [Recording]
    var loops: [Loop]

    var createdAt: Date
    var updatedAt: Date
}
```

## Task PR F7.1.2 — Repository

```swift
protocol SessionRepository {
    func create() throws -> MusicSession
    func save(_ session: MusicSession) throws
    func load(id: UUID) throws -> MusicSession
    func list() throws -> [MusicSession]
    func delete(id: UUID) throws
}
```

## Task PR F7.1.3 — Serialization

Persist session metadata independently of audio files.

## Task PR F7.1.4 — Autosave

Important changes trigger debounced saving.

---
