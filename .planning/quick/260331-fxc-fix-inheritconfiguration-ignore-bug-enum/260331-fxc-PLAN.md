---
phase: quick
plan: 260331-fxc
type: execute
wave: 1
depends_on: []
files_modified:
  - packages/dart_mapper_generator/lib/src/analyzers/contexts/bindings_analyzer_context.dart
  - packages/dart_mapper_generator/lib/src/processors/mapping_code/enum_mapping_code_processor.dart
  - packages/dart_mapper_generator/test/golden/src/inherit_configuration_ignore_test_src.dart
  - packages/dart_mapper_generator/test/golden/src/enum_auto_mapping_test_src.dart
  - packages/dart_mapper_generator/test/golden/golden_test.dart
autonomous: true
requirements: []

must_haves:
  truths:
    - "@InheritConfiguration inherits ignore: true from the base method"
    - "@InheritConfiguration inherits forceNonNull: true from the base method"
    - "Auto-generated enum helper methods contain all expected switch cases (not empty)"
    - "Golden tests pass for both scenarios"
  artifacts:
    - path: "packages/dart_mapper_generator/lib/src/analyzers/contexts/bindings_analyzer_context.dart"
      provides: "Fixed ignoredTargets and forceNonNullTargets getters using _renamingMappings"
    - path: "packages/dart_mapper_generator/lib/src/processors/mapping_code/enum_mapping_code_processor.dart"
      provides: "Fixed methodBindings extraction using method.bindings directly"
    - path: "packages/dart_mapper_generator/test/golden/src/inherit_configuration_ignore_test_src.dart"
      provides: "Golden test for @InheritConfiguration inheriting ignore"
    - path: "packages/dart_mapper_generator/test/golden/src/enum_auto_mapping_test_src.dart"
      provides: "Golden test for auto-generated enum helper switch cases"
  key_links:
    - from: "ignoredTargets getter"
      to: "_renamingMappings"
      via: "direct field reference (not MappingAnnotation.load)"
      pattern: "_renamingMappings.*ignore"
    - from: "EnumMappingCodeProcessor.process"
      to: "method.bindings"
      via: "BindableMappingMethod.bindings property"
      pattern: "method\\.bindings"
---

<objective>
Fix two bugs in the dart_mapper_generator: (1) @InheritConfiguration does not propagate ignore/forceNonNull flags, (2) auto-generated enum-to-enum helper methods have empty switch bodies. Add golden tests verifying both fixes.

Purpose: Correctness — inherited ignore flags were silently dropped, and auto-generated enum helpers silently produced invalid code (unreachable throw only).
Output: Two bug fixes + two new golden test src files + golden_test.dart registrations.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md

Key source files:
- packages/dart_mapper_generator/lib/src/analyzers/contexts/bindings_analyzer_context.dart
- packages/dart_mapper_generator/lib/src/processors/mapping_code/enum_mapping_code_processor.dart
- packages/dart_mapper_generator/test/golden/golden_test.dart
- packages/dart_mapper_generator/test/golden/src/inherit_config_test_src.dart (pattern reference)
- packages/dart_mapper_generator/test/golden/src/enums_test_src.dart (pattern reference)
- packages/dart_mapper_generator/test/golden/src/basic_test_src.dart (pattern reference)

<interfaces>
<!-- From bindings_analyzer_context.dart — _renamingMappings already exists: -->
Iterable<ResolvedMapping> get _renamingMappings => [
  ...?inheritedRenaming,
  ...?inheritedRenamingReversed,
  ...MappingAnnotation.load(method),
];

<!-- From generated_private_mapping_method.dart: -->
final class GeneratedPrivateMappingMethod extends BindableMappingMethod { ... }

<!-- From bindable_mapping_method.dart — bindings is on the base: -->
abstract class BindableMappingMethod extends MappingMethod {
  final List<Binding> bindings;
  ...
}
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Fix ignoredTargets and forceNonNullTargets getters + fix enum methodBindings</name>
  <files>
    packages/dart_mapper_generator/lib/src/analyzers/contexts/bindings_analyzer_context.dart
    packages/dart_mapper_generator/lib/src/processors/mapping_code/enum_mapping_code_processor.dart
  </files>
  <action>
**Fix 1 — bindings_analyzer_context.dart (lines 205-213):**

Replace both getters so they use `_renamingMappings` (which already merges `inheritedRenaming + inheritedRenamingReversed + MappingAnnotation.load(method)`) instead of calling `MappingAnnotation.load(method)` directly:

```dart
Set<String> get ignoredTargets => _renamingMappings
    .where((annotation) => annotation.ignore)
    .map((annotation) => annotation.target)
    .toSet();

Set<String> get forceNonNullTargets => _renamingMappings
    .where((annotation) => annotation.forceNonNull)
    .map((annotation) => annotation.target)
    .toSet();
```

All other getters in this file already use `_renamingMappings` — this makes `ignoredTargets` and `forceNonNullTargets` consistent.

**Fix 2 — enum_mapping_code_processor.dart (lines 55-58):**

Replace the switch expression that type-checks for `DefinedMappingMethod` with a direct property access. `bindings` is declared on `BindableMappingMethod` (the common base of both `DefinedMappingMethod` and `GeneratedPrivateMappingMethod`), so no type narrowing is needed:

```dart
final methodBindings = method.bindings;
```

Remove the import of `defined_mapping_method.dart` if it becomes unused after this change (check other usages in the file — `_buildOtherwiseExpression` still references `DefinedMappingMethod`, so keep the import).
  </action>
  <verify>
    cd /home/angeloavv/FlutterProjects/dart_mapper/packages/dart_mapper_generator && dart analyze lib/src/analyzers/contexts/bindings_analyzer_context.dart lib/src/processors/mapping_code/enum_mapping_code_processor.dart
  </verify>
  <done>Both files compile with no analyzer errors. The `ignoredTargets` and `forceNonNullTargets` getters reference `_renamingMappings`. The `methodBindings` assignment is `method.bindings` without a switch expression.</done>
</task>

<task type="auto">
  <name>Task 2: Add golden test src files for both bug fixes</name>
  <files>
    packages/dart_mapper_generator/test/golden/src/inherit_configuration_ignore_test_src.dart
    packages/dart_mapper_generator/test/golden/src/enum_auto_mapping_test_src.dart
  </files>
  <action>
**File 1 — inherit_configuration_ignore_test_src.dart:**

Create this file following the copyright header and doc-comment pattern from `inherit_config_test_src.dart`. The test must verify that `@InheritConfiguration` propagates `ignore: true` so that the ignored field is passed as `null` rather than `src.field`.

```dart
/*
 * Copyright (c) 2026 MyLittleSuite
 * [MIT license header — same as other test src files]
 */

// Golden test source for @InheritConfiguration propagating ignore: true.
//
// Validates that a method annotated with @InheritConfiguration does NOT
// copy the ignored field from source — it passes null for that field.

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

class IgnoreSource {
  final String name;
  final int age;
  final String secret;

  IgnoreSource(this.name, this.age, this.secret);
}

class IgnoreTarget {
  final String name;
  final int age;
  final String? secret;

  IgnoreTarget(this.name, this.age, this.secret);
}

// toTarget ignores 'secret' — must produce: return IgnoreTarget(source.name, source.age, null)
// toTargetDirect inherits that ignore via @InheritConfiguration — must produce the same body.

@ShouldGenerate(
  r'''IgnoreTarget toTarget(IgnoreSource source)''',
  contains: true,
)
@ShouldGenerate(
  r'''return IgnoreTarget(source.name, source.age, null)''',
  contains: true,
)
@ShouldGenerate(
  r'''IgnoreTarget toTargetDirect(IgnoreSource source)''',
  contains: true,
)
@Mapper()
abstract class InheritIgnoreMapper {
  @Mapping(target: 'secret', ignore: true)
  IgnoreTarget toTarget(IgnoreSource source);

  @InheritConfiguration()
  IgnoreTarget toTargetDirect(IgnoreSource source);
}
```

Note: `@ShouldGenerate` with `contains: true` allows fragment matching. `return IgnoreTarget(source.name, source.age, null)` must appear in the generated output for BOTH methods — the single `@ShouldGenerate` check for that fragment covers both because `contains: true` just checks the full generated output string.

**File 2 — enum_auto_mapping_test_src.dart:**

Create this file verifying the auto-generated private helper has the correct switch cases. The mapper takes a class with a `SourceColor` field and maps to a class with a `TargetColor` field — this triggers `GeneratedPrivateMappingMethod` creation via `ExtraMappingMethodAnalyzer`.

```dart
/*
 * Copyright (c) 2026 MyLittleSuite
 * [MIT license header — same as other test src files]
 */

// Golden test source for auto-generated enum-to-enum private helper methods.
//
// Validates that GeneratedPrivateMappingMethod used in EnumMappingCodeProcessor
// produces a switch with all bindings (not an empty switch).

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

enum BoxColor { red, green, blue, extra }

enum ResultColor { red, green, blue, other }

class ColorBox {
  final BoxColor color;

  ColorBox(this.color);
}

class ColorResult {
  final ResultColor color;

  ColorResult(this.color);
}

// toResult must generate a private helper _mapBoxColorToResultColor.
// That helper must have switch cases for red, green, blue (auto-mapped by name).
// 'extra' has no matching name in ResultColor — it falls to the throw wildcard.

@ShouldGenerate(
  r'''_mapBoxColorToResultColor''',
  contains: true,
)
@ShouldGenerate(
  r'''BoxColor.red => ResultColor.red,''',
  contains: true,
)
@ShouldGenerate(
  r'''BoxColor.green => ResultColor.green,''',
  contains: true,
)
@ShouldGenerate(
  r'''BoxColor.blue => ResultColor.blue,''',
  contains: true,
)
@Mapper()
abstract class ColorBoxMapper {
  ColorResult toResult(ColorBox source);
}
```

Note on enum name-matching: `BoxColor.extra` has no match in `ResultColor` (no `extra` value), so it is not auto-populated and falls to the `_ => throw ArgumentError(...)` wildcard. Only red/green/blue get explicit cases. Verify this assumption by checking the auto-population logic in `EnumsMappingMethodAnalyzer` if the test fails.
  </action>
  <verify>
    cd /home/angeloavv/FlutterProjects/dart_mapper/packages/dart_mapper_generator && dart analyze test/golden/src/inherit_configuration_ignore_test_src.dart test/golden/src/enum_auto_mapping_test_src.dart
  </verify>
  <done>Both files exist, contain valid Dart, and `dart analyze` reports no errors.</done>
</task>

<task type="auto">
  <name>Task 3: Register new test src files in golden_test.dart and run all golden tests</name>
  <files>
    packages/dart_mapper_generator/test/golden/golden_test.dart
  </files>
  <action>
Append two new reader+testAnnotatedElements blocks to `golden_test.dart` following the exact same pattern used by every existing group. Add them before the closing `}` of `main()`.

Pattern to replicate (copy style from existing entries):

```dart
  // Group: @InheritConfiguration inheriting ignore flag
  final inheritIgnoreReader = await initializeLibraryReaderForDirectory(
    'test/golden/src',
    'inherit_configuration_ignore_test_src.dart',
  );
  testAnnotatedElements<Mapper>(inheritIgnoreReader, generator);

  // Group: Auto-generated enum helper switch cases (enum-in-class mapping)
  final enumAutoMappingReader = await initializeLibraryReaderForDirectory(
    'test/golden/src',
    'enum_auto_mapping_test_src.dart',
  );
  testAnnotatedElements<Mapper>(enumAutoMappingReader, generator);
```

After editing, run the full golden test suite:

```
cd /home/angeloavv/FlutterProjects/dart_mapper/packages/dart_mapper_generator
dart test test/golden/golden_test.dart --reporter=expanded
```

If tests fail:
- If `inherit_configuration_ignore_test_src.dart` tests fail: check the actual generated output using `dart run build_runner build` on the example, or add a temporary `print` in the test. The `@ShouldGenerate` fragment for the ignored field body may need adjustment if dart_style formats differently (e.g., named parameter `secret: null` vs positional `null`).
- If `enum_auto_mapping_test_src.dart` tests fail: the private helper method name is generated by `GeneratedPrivateMappingMethod._generateUniqueName`. The actual name depends on the field name (`color`), source type (`BoxColor`), and target type (`ResultColor`). Expected name: `_mapBoxColorToResultColor`. If it differs, update the `@ShouldGenerate` fragment to match the actual output.

If the `extra` enum value IS auto-populated (some analyzers handle partial overlap), check and update the expected fragments accordingly.
  </action>
  <verify>
    cd /home/angeloavv/FlutterProjects/dart_mapper/packages/dart_mapper_generator && dart test test/golden/golden_test.dart --reporter=expanded 2>&1 | tail -30
  </verify>
  <done>All golden tests pass, including the two new groups. No regressions in existing tests.</done>
</task>

</tasks>

<verification>
Run the full golden test suite and static analysis:

```bash
cd /home/angeloavv/FlutterProjects/dart_mapper/packages/dart_mapper_generator
dart analyze lib/ test/
dart test test/golden/golden_test.dart --reporter=expanded
```

All tests green. No analyzer warnings in modified files.
</verification>

<success_criteria>
- `ignoredTargets` and `forceNonNullTargets` getters in `BindingsAnalyzerContext` reference `_renamingMappings`
- `methodBindings` in `EnumMappingCodeProcessor` is `method.bindings` (no switch type check)
- `inherit_configuration_ignore_test_src.dart` exists and its `@ShouldGenerate` fragments pass
- `enum_auto_mapping_test_src.dart` exists and its `@ShouldGenerate` fragments pass (switch cases present)
- `golden_test.dart` registers both new groups
- `dart test test/golden/golden_test.dart` exits 0
</success_criteria>

<output>
After completion, create `.planning/quick/260331-fxc-fix-inheritconfiguration-ignore-bug-enum/260331-fxc-SUMMARY.md` using the summary template.
</output>
