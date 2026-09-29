---
title: F3.1 — Gain Processing
feature: F3.1
version: V0.1
phase: "Phase 3 — DSP V1"
status: proposed
tags:
  - feature-pr
  - v0-1
---

# F3.1 — Gain Processing

[[../releases/v0-1|← V0.1]] · [[../implementation-plan|Plan index]]

## Task PR checklist

- [x] [[#Task PR F3.1.1 — Processing node abstraction|F3.1.1 — Processing node abstraction]]
- [x] [[#Task PR F3.1.2 — Input gain processor|F3.1.2 — Input gain processor]]
- [x] [[#Task PR F3.1.3 — Gain UI|F3.1.3 — Gain UI]]

## Task PR F3.1.1 — Processing node abstraction

Define a reusable processing concept.

```swift
protocol AudioProcessor {
    var id: UUID { get }
    var bypassed: Bool { get set }
}
```

The implementation may wrap Audio Units internally.

## Task PR F3.1.2 — Input gain processor

Signal path:

```text
Input
 ↓
Gain
 ↓
EQ
 ↓
Effects
```

## Task PR F3.1.3 — Gain UI

Expose:

```text
Input Gain
Output Gain
Bypass
```

---
