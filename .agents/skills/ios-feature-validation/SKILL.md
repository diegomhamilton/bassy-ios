---
name: ios-feature-validation
description: Validate an implemented native iOS feature with Xcode builds, focused and full tests, simulator launches, screenshot gates, and checkpoint evidence. Use after implementation or when refreshing review evidence; do not use it to implement the feature itself.
---

# iOS feature validation

Validate the existing implementation without expanding or recreating it.

## Workflow

1. Confirm the requested feature, reviewed commit, active branch, clean status, scheme, and intended test scope.
2. Check XcodeBuildMCP availability once. Use it when available. If absent, record that gate as blocked and use direct Xcode tools only as provisional evidence unless the user explicitly accepts the fallback.
3. Discover available simulator destinations once and retain one UDID for the entire checkpoint.
4. During iteration, run only the affected test suite with quiet output. At the final checkpoint, run the complete scheme once into a stable DerivedData directory.
5. Use host-level access for CoreSimulator operations when the restricted environment cannot connect to `CoreSimulatorService`. Request the authorization once, but execute discovery, boot, install, launch, and capture as separate observable commands so a stall has a clear boundary.
6. Recheck the selected base simulator after `xcodebuild test`; XCTest may use a clone and leave the base device shut down. Boot it when needed and wait for `bootstatus -b` before installing, launching, or capturing.
7. Install the app from the already-tested DerivedData output. Do not rebuild merely to launch it.
8. Launch deterministic review states when the app provides launch arguments. Stop at the first failed install, launch, or capture. Run `scripts/check_screenshot.swift` only after capture succeeds and the image exists, and discard any image it identifies as a likely boot screen.
9. Visually inspect accepted screenshots once for the requested state, clipping, stale content, or unrelated sensitive information.
10. Record the validation method, exact test result, simulator identity, DerivedData location, reviewed commit, screenshots, blocked gates, and the one human decision requested.

Read [references/xcode-simulator-workflow.md](references/xcode-simulator-workflow.md) when commands or failure recovery are needed.

## Stop conditions

- Do not change production code while performing a validation-only request.
- Stop after one confirmed XcodeBuildMCP availability check; do not spend retries proving that an unavailable integration is unavailable.
- Stop and report exact failures when the full test run fails.
- Do not accept screenshots captured before simulator boot completion or from a different implementation commit.
- Never represent direct `xcodebuild` success as an XcodeBuildMCP pass.
