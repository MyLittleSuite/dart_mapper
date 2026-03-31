---
phase: quick
plan: 260331-fxc
subsystem: dart_mapper_generator
tags: [bug-fix, inheritance, enum, golden-tests]
dependency_graph:
  requires: []
  provides: [inherit-configuration-ignore-propagation, enum-auto-mapping-bindings]
  affects: [bindings_analyzer_context, enum_mapping_code_processor, golden_test_suite]
tech_stack:
  added: []
  patterns: [_renamingMappings unified getter, BindableMappingMethod.bindings direct access]
key_files:
  created:
    - packages/dart_mapper_generator/test/golden/src/inherit_configuration_ignore_test_src.dart
    - packages/dart_mapper_generator/test/golden/src/enum_auto_mapping_test_src.dart
  modified:
    - packages/dart_mapper_generator/lib/src/analyzers/contexts/bindings_analyzer_context.dart
    - packages/dart_mapper_generator/lib/src/processors/mapping_code/enum_mapping_code_processor.dart
    - packages/dart_mapper_generator/test/golden/golden_test.dart
decisions:
  - ignoredTargets/forceNonNullTargets use _renamingMappings for consistency with all other getters
  - EnumMappingCodeProcessor uses method.bindings directly (BindableMappingMethod base property)
  - Test model IgnoreSource.secret is String? (nullable) — ignore: true semantics require nullable source
metrics:
  duration: ~10min
  completed: "2026-03-31"
  tasks: 3
  files: 5
---

# Quick Task 260331-fxc: Fix @InheritConfiguration ignore propagation and enum auto-mapping bindings

**One-liner:** Fixed two silent code-gen bugs: `@InheritConfiguration` now propagates `ignore`/`forceNonNull` flags, and auto-generated enum helper methods now include proper switch cases.

## Tasks Completed

| Task | Name | Commit | Status |
|------|------|--------|--------|
| 1 | Fix ignoredTargets/forceNonNullTargets getters + enum methodBindings | b3f8cb9 | Done |
| 2 | Add golden test src files for both bug fixes | fb0ec52 | Done |
| 3 | Register new test groups in golden_test.dart + all tests pass | 43250f3 | Done |

## Bug Fixes Applied

### Fix 1 — `BindingsAnalyzerContext.ignoredTargets` and `forceNonNullTargets`

**File:** `packages/dart_mapper_generator/lib/src/analyzers/contexts/bindings_analyzer_context.dart`

**Before:** Both getters called `MappingAnnotation.load(method)` directly, which only reads annotations on the current method. When `@InheritConfiguration` is used, inherited annotations are stored in `inheritedRenaming` / `inheritedRenamingReversed`, not on the method itself — so the flags were silently dropped.

**After:** Both getters now use `_renamingMappings` (which already merges `inheritedRenaming + inheritedRenamingReversed + MappingAnnotation.load(method)`), consistent with all other getters in the same class.

### Fix 2 — `EnumMappingCodeProcessor.methodBindings`

**File:** `packages/dart_mapper_generator/lib/src/processors/mapping_code/enum_mapping_code_processor.dart`

**Before:** `methodBindings` used a switch expression narrowing to `DefinedMappingMethod` — returning `[]` for any other type. Auto-generated enum helper methods are `GeneratedPrivateMappingMethod`, not `DefinedMappingMethod`, so they always got an empty bindings list → empty switch body → unreachable throw only.

**After:** `methodBindings = method.bindings` — `bindings` is declared on `BindableMappingMethod`, the common base for both types. No type narrowing needed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated IgnoreSource.secret to String? in test model**
- **Found during:** Task 3 (first test run)
- **Issue:** Plan specified `secret: String` in `IgnoreSource`, but `ignore: true` semantics in the expression factory require the source field to be nullable (non-nullable source + ignore triggers a guard that throws). The existing example also uses nullable source fields with `ignore: true`.
- **Fix:** Changed `IgnoreSource.secret` to `String?` so the test exercises the real working path.
- **Files modified:** `inherit_configuration_ignore_test_src.dart`
- **Commit:** 43250f3

## Verification

- `dart analyze lib/ test/` — no issues
- `dart test test/golden/golden_test.dart` — 107 tests passed (2 new groups: InheritIgnoreMapper x3, ColorBoxMapper x4)

## Self-Check: PASSED

- b3f8cb9 exists: confirmed
- fb0ec52 exists: confirmed
- 43250f3 exists: confirmed
- All modified files exist and analyze clean
