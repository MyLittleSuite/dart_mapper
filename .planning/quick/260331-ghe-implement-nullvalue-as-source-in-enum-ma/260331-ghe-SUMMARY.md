---
phase: quick
plan: 260331-ghe
subsystem: enum-mapping
tags: [enum, nullValue, code-gen, golden-test, docs]
dependency_graph:
  requires: []
  provides: [nullValue-as-source enum mapping]
  affects: [enum_mapping_code_processor, enums_mapping_method_analyzer, bindings_analyzer_context, defined_mapping_method]
tech_stack:
  added: []
  patterns: [nullSourceTarget sentinel field, DefinedMappingMethod extension pattern]
key_files:
  created:
    - packages/dart_mapper_generator/test/golden/src/null_value_source_test_src.dart
    - example/lib/enums/enum_mapper.g.dart
  modified:
    - packages/dart_mapper_generator/lib/src/analyzers/contexts/bindings_analyzer_context.dart
    - packages/dart_mapper_generator/lib/src/analyzers/binding/enums_mapping_method_analyzer.dart
    - packages/dart_mapper_generator/lib/src/models/mapper/mapping/method/defined_mapping_method.dart
    - packages/dart_mapper_generator/lib/src/analyzers/bindings_analyzer.dart
    - packages/dart_mapper_generator/lib/src/processors/mapping_code/enum_mapping_code_processor.dart
    - example/lib/enums/enum_mapper.dart
    - packages/dart_mapper_generator/test/golden/golden_test.dart
    - docs/guides/enum-mapping.mdx
decisions:
  - nullSourceTarget field mirrors anyRemainingTarget/hasAnyUnmapped pattern in DefinedMappingMethod
  - Golden test uses inline enum definitions (no dart_mapper_example dependency in generator package)
  - Validation in _bindTwoEnums rejects nullValue on non-nullable source type at generation time
metrics:
  duration: ~10min
  completed_date: "2026-03-31"
  tasks: 3
  files: 9
---

# Quick 260331-ghe: Implement nullValue as Source in Enum Mapping — Summary

**One-liner:** `@ValueMapping(source: ValueMapping.nullValue, target: 'X')` on nullable-source enum methods now emits `null => TargetEnum.X` in the generated switch expression.

## What Was Built

Closed the feature gap where `ValueMapping.nullValue` only worked as a target (via `anyUnmapped`). Users can now express "null input maps to a known default" cleanly.

### Generator pipeline (5 files)

The `nullSourceTarget` sentinel flows through the same pathway as `anyRemainingTarget`:

1. `BindingsAnalyzerContext.nullSourceTarget` getter reads the `<NULL>` key from the enum values map.
2. `EnumsMappingMethodAnalyzer._bindTwoEnums` validates that `<NULL>` source requires a nullable source type; throws `InvalidGenerationSourceError` otherwise.
3. `DefinedMappingMethod.nullSourceTarget` field stores the target enum value name.
4. `BindingsAnalyzer` passes `bindingsContext.nullSourceTarget` when constructing `DefinedMappingMethod`.
5. `EnumMappingCodeProcessor` checks `method is DefinedMappingMethod && method.nullSourceTarget != null` in the null-case branch and emits `refer(safeEnumDisplayName).property(method.nullSourceTarget!)`.

### Example (2 files)

`NullValueSourceEnumMapper` added to `example/lib/enums/enum_mapper.dart` with `anyRemaining: blue` and `nullValue: red`. `NullValueSourceEnumMapperImpl` hand-written in `enum_mapper.g.dart` with correct `null => PrimaryTargetColor.red`, name-matched, and `_ => PrimaryTargetColor.blue` cases.

### Tests (2 files)

New `null_value_source_test_src.dart` golden test with three `@ShouldGenerate(contains: true)` assertions. Added `nullValue` group to `golden_test.dart`. All 112 tests pass.

### Docs (1 file)

Fixed the "Null Fallback with ValueMapping.anyUnmapped" section which incorrectly showed `source: ValueMapping.anyRemaining, target: ValueMapping.anyUnmapped`. Corrected to `source: ValueMapping.anyUnmapped, target: ValueMapping.nullValue`. Split "Enum to Int / Int to Enum" into two separate sections.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Golden test cannot import `dart_mapper_example`**

- **Found during:** Task 3
- **Issue:** The plan template used `import 'package:dart_mapper_example/enums/enums.dart'` but `dart_mapper_example` is not a dependency of `dart_mapper_generator`. No other golden test imports from the example package.
- **Fix:** Defined `ExtendedSourceColor` and `PrimaryTargetColor` inline in `null_value_source_test_src.dart`, matching the values from the original example enums exactly.
- **Files modified:** `packages/dart_mapper_generator/test/golden/src/null_value_source_test_src.dart`
- **Commit:** 1d5ba22

## Commits

| Task | Commit | Message |
|------|--------|---------|
| Task 1 | 1f2822a | feat(quick-260331-ghe): wire nullValue-as-source through generator pipeline |
| Task 2 | 8268642 | feat(quick-260331-ghe): add NullValueSourceEnumMapper to example |
| Task 3 | 1d5ba22 | feat(quick-260331-ghe): add golden test and fix enum-mapping.mdx |

## Known Stubs

None — all cases are fully wired.

## Self-Check: PASSED
