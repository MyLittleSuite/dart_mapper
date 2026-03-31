---
phase: quick
plan: 260331-fc5
subsystem: packaging
tags: [pub-dev, documentation, dartdoc, pubspec]
dependency_graph:
  requires: []
  provides: [pub-dev-score-fixes]
  affects: [dart_mapper, dart_mapper_generator]
tech_stack:
  added: []
  patterns: [dartdoc, pub-dev-example-convention]
key_files:
  created:
    - packages/dart_mapper/example/example.dart
    - packages/dart_mapper_generator/example/example.dart
  modified:
    - pubspec.yaml
    - packages/dart_mapper_generator/lib/dart_mapper_generator.dart
    - packages/dart_mapper_generator/lib/src/builders/dart_mapper_builder.dart
decisions:
  - Root pubspec renamed to dart_mapper_workspace to avoid name collision with packages/dart_mapper on pub.dev repository verification
metrics:
  duration: 2min
  completed_date: "2026-03-31"
  tasks: 2
  files: 5
---

# Quick Task 260331-fc5: Fix pub.dev Score Issues — Rename Root Pubspec Summary

**One-liner:** Fixed three pub.dev score issues: root pubspec name collision resolved, example/ stubs added to both packages, and dartdoc added to all public generator API elements.

## What Was Done

### Task 1: Rename root pubspec and add example stubs (commit: 77deef2)

- Changed `name: dart_mapper` to `name: dart_mapper_workspace` in root `pubspec.yaml` to eliminate the name collision that caused pub.dev repository URL verification to fail when cloning the repo and finding two `name: dart_mapper` entries.
- Created `packages/dart_mapper/example/example.dart` with a `main()` function demonstrating `@Mapper` and `@Mapping` annotations on inline model classes, with a comment explaining build_runner usage.
- Created `packages/dart_mapper_generator/example/example.dart` with a `main()` function and inline documentation explaining the build-time-only nature of the package along with the required `build.yaml` snippet.

### Task 2: Add dartdoc to dart_mapper_generator public API (commit: 3cddebc)

- Added a library-level `///` doc comment to `packages/dart_mapper_generator/lib/dart_mapper_generator.dart` immediately before the `library;` declaration.
- Added a multi-line `///` dartdoc comment to `dartMapperBuilder` in `packages/dart_mapper_generator/lib/src/builders/dart_mapper_builder.dart` covering its return value, build.yaml wiring, and the `options` parameter.
- Result: 2/2 public API elements documented (100% coverage, exceeds pub.dev 20% threshold).

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None - both example files contain functional `main()` functions with accurate, self-contained content.

## Self-Check: PASSED

- pubspec.yaml `name: dart_mapper_workspace` — FOUND
- packages/dart_mapper/example/example.dart — FOUND
- packages/dart_mapper_generator/example/example.dart — FOUND
- packages/dart_mapper_generator/lib/dart_mapper_generator.dart has `///` comment — FOUND
- packages/dart_mapper_generator/lib/src/builders/dart_mapper_builder.dart has `///` comment — FOUND
- Commits 77deef2, 3cddebc — FOUND (git log verified)
- dart analyze: No issues found on all 4 analyzed files
