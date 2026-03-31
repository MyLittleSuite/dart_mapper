---
phase: quick
plan: 260331-eaj
subsystem: ci
tags: [github-actions, publish, polling, pub-dev]
dependency_graph:
  requires: []
  provides: [wait_for_dart_mapper job in publish workflow]
  affects: [.github/workflows/publish.yml]
tech_stack:
  added: []
  patterns: [bash polling loop, curl HTTP status check, GitHub Actions job chaining]
key_files:
  created: []
  modified:
    - .github/workflows/publish.yml
decisions:
  - Version extracted via grep+awk from pubspec.yaml — no hardcoding
  - 20 attempts x 30 seconds = 10 minute max wait ceiling
  - ::error:: annotation surfaces timeout in GitHub Actions UI
metrics:
  duration: 3min
  completed_date: "2026-03-31"
  tasks: 1
  files_changed: 1
---

# Quick Task 260331-eaj: Add wait_for_dart_mapper Polling Job to Publish Workflow Summary

**One-liner:** Added `wait_for_dart_mapper` intermediate job to `publish.yml` that polls pub.dev until `dart_mapper` is indexed before `dart_mapper_generator` runs.

## What Was Done

Inserted a new `wait_for_dart_mapper` job into `.github/workflows/publish.yml` between the existing `dart_runner` (publishes `dart_mapper`) and `dart_mapper_generator` (publishes the generator) jobs.

The polling job:
- Reads the version dynamically from `packages/dart_mapper/pubspec.yaml` via `grep '^version:'` + `awk '{print $2}'`
- Polls `https://pub.dev/api/packages/dart_mapper/versions/$VERSION` using `curl -s -o /dev/null -w "%{http_code}"`
- Exits 0 immediately when HTTP 200 is returned
- Retries up to 20 times with 30-second intervals (10 minutes max)
- Emits `::error::` GitHub Actions annotation and exits 1 on timeout

The `dart_mapper_generator` job's `needs:` was updated from `dart_runner` to `wait_for_dart_mapper`, forming a strict linear chain:

```
dart_runner → wait_for_dart_mapper → dart_mapper_generator
```

## Deviations from Plan

None — plan executed exactly as written.

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 | 9cc24f6 | chore(quick-260331-eaj): add wait_for_dart_mapper polling job to publish workflow |

## Self-Check: PASSED

- `.github/workflows/publish.yml` exists and contains `wait_for_dart_mapper` (2 occurrences)
- Commit 9cc24f6 verified in git log
- Dependency chain: dart_runner → wait_for_dart_mapper → dart_mapper_generator confirmed
