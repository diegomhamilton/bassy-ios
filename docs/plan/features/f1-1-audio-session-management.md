---
title: F1.1 — Audio Session Management
feature: F1.1
version: V0.1
phase: "Phase 1 — Audio Hardware Foundation"
status: proposed
tags:
  - feature-pr
  - v0-1
---

# F1.1 — Audio Session Management

[[../releases/v0-1|← V0.1]] · [[../implementation-plan|Plan index]]

## Task PR checklist

- [x] [[#Task PR F1.1.1 — AVAudioSession abstraction|F1.1.1 — AVAudioSession abstraction]]
- [x] [[#Task PR F1.1.2 — Route change observation|F1.1.2 — Route change observation]]
- [x] [[#Task PR F1.1.3 — Input device discovery|F1.1.3 — Input device discovery]]
- [x] [[#Task PR F1.1.4 — Preferred input selection|F1.1.4 — Preferred input selection]]

## Task PR F1.1.1 — AVAudioSession abstraction

Create:

```swift
protocol AudioSessionManaging {
    func activate() async throws
    func deactivate() async
}
```

Configure the app for simultaneous:

```text
input
processing
recording
playback
monitoring
```

Likely category:

```swift
.playAndRecord
```

with appropriate options determined during hardware testing.

## Task PR F1.1.2 — Route change observation

Observe:

```swift
AVAudioSession.routeChangeNotification
```

Represent routes internally:

```swift
struct AudioRoute {
    let inputs: [AudioDevice]
    let outputs: [AudioDevice]
}
```

## Task PR F1.1.3 — Input device discovery

Expose available inputs.

Example:

```swift
enum AudioInputKind {
    case builtInMicrophone
    case usb
    case bluetooth
    case unknown
}
```

Do not encode Cube Baby-specific behavior into the domain layer.

## Task PR F1.1.4 — Preferred input selection

Allow selecting an available input where iOS permits it.

Handle:

- disconnected device;
- route becoming unavailable;
- app background/foreground;
- audio interruption.

## Feature acceptance criteria

Connecting or disconnecting an interface updates the app without restarting it.

---
