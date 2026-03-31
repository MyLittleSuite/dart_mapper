---
phase: quick
plan: 260331-ghe
type: execute
wave: 1
depends_on: []
files_modified:
  - packages/dart_mapper_generator/lib/src/analyzers/contexts/bindings_analyzer_context.dart
  - packages/dart_mapper_generator/lib/src/analyzers/binding/enums_mapping_method_analyzer.dart
  - packages/dart_mapper_generator/lib/src/models/mapper/mapping/method/defined_mapping_method.dart
  - packages/dart_mapper_generator/lib/src/analyzers/bindings_analyzer.dart
  - packages/dart_mapper_generator/lib/src/processors/mapping_code/enum_mapping_code_processor.dart
  - example/lib/enums/enum_mapper.dart
  - example/lib/enums/enum_mapper.g.dart
  - packages/dart_mapper_generator/test/golden/src/null_value_source_test_src.dart
  - packages/dart_mapper_generator/test/golden/golden_test.dart
  - docs/guides/enum-mapping.mdx
autonomous: true
requirements: []

must_haves:
  truths:
    - "@ValueMapping(source: ValueMapping.nullValue, target: 'red') on a nullable-source enum method generates null => PrimaryTargetColor.red in the switch"
    - "Non-nullable source with nullValue sentinel throws InvalidGenerationSourceError at generation time"
    - "Golden test asserts null-source case is emitted correctly"
    - "enum_mapper.dart example includes NullValueSourceEnumMapper"
    - "enum-mapping.mdx documents nullValue as source and fixes the broken anyUnmapped section"
  artifacts:
    - path: packages/dart_mapper_generator/lib/src/analyzers/contexts/bindings_analyzer_context.dart
      provides: nullSourceTarget getter
    - path: packages/dart_mapper_generator/lib/src/models/mapper/mapping/method/defined_mapping_method.dart
      provides: nullSourceTarget field
    - path: packages/dart_mapper_generator/lib/src/processors/mapping_code/enum_mapping_code_processor.dart
      provides: null-case branch that emits target enum value when nullSourceTarget set
    - path: packages/dart_mapper_generator/test/golden/src/null_value_source_test_src.dart
      provides: golden test for nullValue-as-source
  key_links:
    - from: bindings_analyzer_context.dart (nullSourceTarget getter)
      to: bindings_analyzer.dart (DefinedMappingMethod construction)
      via: bindingsContext.nullSourceTarget passed to nullSourceTarget field
    - from: defined_mapping_method.dart (nullSourceTarget field)
      to: enum_mapping_code_processor.dart (null case expression)
      via: method is DefinedMappingMethod && method.nullSourceTarget != null check
---

<objective>
Implement support for `ValueMapping.nullValue` as a source sentinel in enum mapping, so that when a mapper method receives a null enum input, it returns a specific target enum value instead of throwing or returning null.

Purpose: Closes the feature gap where nullValue only worked as a target (via anyUnmapped). Enables users to express "null input maps to a known default" pattern cleanly.
Output: 5 generator files updated, example updated with new mapper + generated impl, golden test added, doc guide corrected and expanded.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md

@packages/dart_mapper_generator/lib/src/analyzers/contexts/bindings_analyzer_context.dart
@packages/dart_mapper_generator/lib/src/analyzers/binding/enums_mapping_method_analyzer.dart
@packages/dart_mapper_generator/lib/src/models/mapper/mapping/method/defined_mapping_method.dart
@packages/dart_mapper_generator/lib/src/analyzers/bindings_analyzer.dart
@packages/dart_mapper_generator/lib/src/processors/mapping_code/enum_mapping_code_processor.dart
@example/lib/enums/enum_mapper.dart
@example/lib/enums/enum_mapper.g.dart
@example/lib/enums/enums.dart
@packages/dart_mapper_generator/test/golden/src/enums_test_src.dart
@packages/dart_mapper_generator/test/golden/golden_test.dart
@docs/guides/enum-mapping.mdx

<interfaces>
<!-- Key types executor needs. No codebase exploration required. -->

From bindings_analyzer_context.dart (line 232-234):
```dart
String? get anyRemainingTarget => enumValues[ValueMapping.anyRemaining];
bool get hasAnyUnmapped => enumValues.containsKey(ValueMapping.anyUnmapped);
Map<String, String> get enumValues => Map.fromEntries(
      ValueMappingAnnotation.load(method).map(
        (element) => MapEntry(element.source, element.target),
      ),
    );
```

From defined_mapping_method.dart:
```dart
final class DefinedMappingMethod extends BindableMappingMethod {
  final String? anyRemainingTarget;
  final bool hasAnyUnmapped;

  const DefinedMappingMethod({
    required super.name,
    super.isOverride = false,
    super.returnType,
    super.optionalReturn = false,
    super.behavior = MappingBehavior.standard,
    super.parameters = const [],
    super.bindings = const [],
    this.anyRemainingTarget,
    this.hasAnyUnmapped = false,
  });
```

From bindings_analyzer.dart (lines 131-153), DefinedMappingMethod construction:
```dart
accumulator.add(
  DefinedMappingMethod(
    name: method.name!,
    isOverride: true,
    returnType: method.returnType,
    optionalReturn: method.returnType.isNullable,
    parameters: ...,
    bindings: bindings,
    behavior: mappingBehavior,
    anyRemainingTarget: bindingsContext.anyRemainingTarget,
    hasAnyUnmapped: bindingsContext.hasAnyUnmapped,
  ),
);
```

From enum_mapping_code_processor.dart (lines 75-82), null case in switch:
```dart
if (sourceField.nullable)
  (
    literal(null),
    method.optionalReturn
        ? literal(null)
        : throwArgumentErrorNotNull(sourceField.name),
  ),
```

From enums_mapping_method_analyzer.dart (lines 124-163), validation block in _bindTwoEnums:
```dart
// Validate mutual exclusion: cannot use both sentinels on same method.
if (enumValuesMap.containsKey(ValueMapping.anyRemaining) &&
    enumValuesMap.containsKey(ValueMapping.anyUnmapped)) {
  throw InvalidGenerationSourceError(...);
}
// Validate non-nullable return with <ANY_UNMAPPED>.
if (enumValuesMap.containsKey(ValueMapping.anyUnmapped) &&
    !context.method.returnType.isNullable) {
  throw InvalidGenerationSourceError(...);
}
```

From dart_mapper ValueMapping constants:
```dart
static const String nullValue = '<NULL>';
static const String anyRemaining = '<ANY_REMAINING>';
static const String anyUnmapped = '<ANY_UNMAPPED>';
```
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Wire nullValue-as-source through the generator pipeline (5 files)</name>
  <files>
    packages/dart_mapper_generator/lib/src/analyzers/contexts/bindings_analyzer_context.dart,
    packages/dart_mapper_generator/lib/src/analyzers/binding/enums_mapping_method_analyzer.dart,
    packages/dart_mapper_generator/lib/src/models/mapper/mapping/method/defined_mapping_method.dart,
    packages/dart_mapper_generator/lib/src/analyzers/bindings_analyzer.dart,
    packages/dart_mapper_generator/lib/src/processors/mapping_code/enum_mapping_code_processor.dart
  </files>
  <action>
Make five targeted edits in dependency order:

**1. bindings_analyzer_context.dart** — Add getter after `hasAnyUnmapped` (line 234):
```dart
String? get nullSourceTarget => enumValues[ValueMapping.nullValue];
```

**2. enums_mapping_method_analyzer.dart** — In `_bindTwoEnums`, after the `hasAnyUnmapped` validation block (after line 142), add:
```dart
// Validate nullValue source requires nullable source type.
if (enumValuesMap.containsKey(ValueMapping.nullValue) &&
    !sourceType.isNullable) {
  throw InvalidGenerationSourceError(
    '<NULL> source requires a nullable source type. '
    'Change the parameter type to nullable (e.g., ExtendedColor?).',
    element: context.method,
  );
}
```

**3. defined_mapping_method.dart** — Add `final String? nullSourceTarget;` field after `hasAnyUnmapped`. Update the constructor to add `this.nullSourceTarget,` (nullable, no default needed). Update `toString()` to append `'nullSourceTarget: $nullSourceTarget'` after `hasAnyUnmapped`.

**4. bindings_analyzer.dart** — In the `DefinedMappingMethod(...)` construction (after `hasAnyUnmapped: bindingsContext.hasAnyUnmapped,`), add:
```dart
nullSourceTarget: bindingsContext.nullSourceTarget,
```

**5. enum_mapping_code_processor.dart** — Replace the null-case expression in the `cases:` list (the `if (sourceField.nullable)` block) with:
```dart
if (sourceField.nullable)
  (
    literal(null),
    method is DefinedMappingMethod && method.nullSourceTarget != null
        ? refer(safeEnumDisplayName).property(method.nullSourceTarget!)
        : method.optionalReturn
            ? literal(null)
            : throwArgumentErrorNotNull(sourceField.name),
  ),
```
This preserves all existing null-case behaviors (throw when non-optional, return null when optional) while adding the new branch when nullSourceTarget is set.
  </action>
  <verify>
    <automated>cd /home/angeloavv/FlutterProjects/dart_mapper/packages/dart_mapper_generator && dart analyze lib/src/analyzers/contexts/bindings_analyzer_context.dart lib/src/analyzers/binding/enums_mapping_method_analyzer.dart lib/src/models/mapper/mapping/method/defined_mapping_method.dart lib/src/analyzers/bindings_analyzer.dart lib/src/processors/mapping_code/enum_mapping_code_processor.dart 2>&1</automated>
  </verify>
  <done>All 5 files pass `dart analyze` with no errors. The nullSourceTarget field flows from context getter through model field to code processor null-case branch.</done>
</task>

<task type="auto">
  <name>Task 2: Add NullValueSourceEnumMapper to example and update generated file</name>
  <files>
    example/lib/enums/enum_mapper.dart,
    example/lib/enums/enum_mapper.g.dart
  </files>
  <action>
**enum_mapper.dart** — Append after `AnyUnmappedEnumMapper` class:
```dart
@Mapper()
abstract class NullValueSourceEnumMapper {
  @ValueMapping(source: ValueMapping.anyRemaining, target: 'blue')
  @ValueMapping(source: ValueMapping.nullValue, target: 'red')
  PrimaryTargetColor convertNullable(ExtendedSourceColor? source);
}
```

**enum_mapper.g.dart** — Append after the closing `}` of `AnyUnmappedEnumMapperImpl` (after line 173). Add the new generated implementation. Use the same header comment style as existing impls (date can be omitted or use a placeholder):
```dart
/// This class is a generated implementation of the abstract class NullValueSourceEnumMapper.
/// Generated by DartMapperGenerator.
class NullValueSourceEnumMapperImpl extends NullValueSourceEnumMapper {
  NullValueSourceEnumMapperImpl();

  @override
  PrimaryTargetColor convertNullable([ExtendedSourceColor? source]) {
    return switch (source) {
      null => PrimaryTargetColor.red,
      ExtendedSourceColor.red => PrimaryTargetColor.red,
      ExtendedSourceColor.green => PrimaryTargetColor.green,
      ExtendedSourceColor.blue => PrimaryTargetColor.blue,
// ignore:unreachable_switch_case
      _ => PrimaryTargetColor.blue,
    };
  }
}
```

Note: The parameter in the generated override uses optional positional form `[ExtendedSourceColor? source]` — follow the existing pattern for nullable source params seen in `EnumMapperImpl.toTargetWithNullableSource` and `toTargetNullableBoth` in the same generated file.
  </action>
  <verify>
    <automated>cd /home/angeloavv/FlutterProjects/dart_mapper/example && dart analyze lib/enums/enum_mapper.dart lib/enums/enum_mapper.g.dart 2>&1</automated>
  </verify>
  <done>Both files pass `dart analyze`. NullValueSourceEnumMapper is declared in the abstract file and NullValueSourceEnumMapperImpl is present in the generated file with the correct null=>red, name-matched, and anyRemaining=>blue cases.</done>
</task>

<task type="auto">
  <name>Task 3: Add golden test and fix enum-mapping.mdx</name>
  <files>
    packages/dart_mapper_generator/test/golden/src/null_value_source_test_src.dart,
    packages/dart_mapper_generator/test/golden/golden_test.dart,
    docs/guides/enum-mapping.mdx
  </files>
  <action>
**null_value_source_test_src.dart** — Create new file following the pattern of `enums_test_src.dart`. Use `ExtendedSourceColor` and `PrimaryTargetColor` (already in `dart_mapper_example/enums/enums.dart`). Add `@ShouldGenerate(contains: true)` assertions for: `null => PrimaryTargetColor.red`, `ExtendedSourceColor.red => PrimaryTargetColor.red`, and `_ => PrimaryTargetColor.blue`. Annotate a single `@Mapper()` abstract class with `@ValueMapping(source: ValueMapping.nullValue, target: 'red')` and `@ValueMapping(source: ValueMapping.anyRemaining, target: 'blue')` on a method `PrimaryTargetColor convertNullable(ExtendedSourceColor? source)`.

File template:
```dart
/*
 * Copyright (c) 2026 MyLittleSuite
 * [MIT license header — same as enums_test_src.dart]
 */

// Golden test source for nullValue-as-source in enum mapping.
//
// Tests: null input maps to a specific target enum value when
// @ValueMapping(source: ValueMapping.nullValue, target: '...') is declared.

import 'package:dart_mapper/dart_mapper.dart';
import 'package:dart_mapper_example/enums/enums.dart';
import 'package:source_gen_test/annotations.dart';

part 'enum_mapper.g.dart';

@ShouldGenerate(
  r'''null => PrimaryTargetColor.red,''',
  contains: true,
)
@ShouldGenerate(
  r'''ExtendedSourceColor.red => PrimaryTargetColor.red,''',
  contains: true,
)
@ShouldGenerate(
  r'''_ => PrimaryTargetColor.blue,''',
  contains: true,
)
@Mapper()
abstract class NullValueSourceEnumMapper {
  @ValueMapping(source: ValueMapping.anyRemaining, target: 'blue')
  @ValueMapping(source: ValueMapping.nullValue, target: 'red')
  PrimaryTargetColor convertNullable(ExtendedSourceColor? source);
}
```

**golden_test.dart** — Add a new group at the end of `main()`, just before the closing `}`, following the exact same pattern as the last entries:
```dart
  // Group: nullValue as source in enum mapping
  final nullValueSourceReader = await initializeLibraryReaderForDirectory(
    'test/golden/src',
    'null_value_source_test_src.dart',
  );
  testAnnotatedElements<Mapper>(nullValueSourceReader, generator);
```

**docs/guides/enum-mapping.mdx** — Make three edits:

1. Fix the "Null Fallback with ValueMapping.anyUnmapped" section (lines 76-85). The current code example is WRONG — it shows `source: ValueMapping.anyRemaining, target: ValueMapping.anyUnmapped` which is two non-sentinel params. Replace the code block with the correct form:
```dart
@Mapper()
abstract class ColorMapper {
  @ValueMapping(source: ValueMapping.anyUnmapped, target: ValueMapping.nullValue)
  PrimaryColor? toPrimaryOrNull(ExtendedColor source);
}
```

2. The "Null Source Handling with ValueMapping.nullValue" section (lines 87-99) already exists in the guide and is CORRECT — do not change it.

3. Split the "Enum to Int / Int to Enum" section (lines 128-144) into two separate sections:
   - "## Enum to Int" — contains only the `priorityToInt` method example
   - "## Int to Enum" — contains only the `intToPriority` method example

Run tests after all edits:
```
cd packages/dart_mapper_generator && dart test
```
  </action>
  <verify>
    <automated>cd /home/angeloavv/FlutterProjects/dart_mapper/packages/dart_mapper_generator && dart test 2>&1</automated>
  </verify>
  <done>All tests pass including the new `null_value_source_test_src.dart` golden group. The guide's anyUnmapped section shows the correct sentinel usage and the Enum to Int / Int to Enum sections are separated.</done>
</task>

</tasks>

<verification>
1. `dart analyze packages/dart_mapper_generator/lib/` — no errors
2. `dart analyze example/lib/enums/` — no errors
3. `dart test` in `packages/dart_mapper_generator/` — all tests pass, including the new null_value_source group
4. `null_value_source_test_src.dart` generates `null => PrimaryTargetColor.red` in the switch
5. `enum-mapping.mdx` anyUnmapped section uses `source: ValueMapping.anyUnmapped, target: ValueMapping.nullValue`
</verification>

<success_criteria>
- `@ValueMapping(source: ValueMapping.nullValue, target: 'someValue')` on a nullable-source enum method emits `null => TargetEnum.someValue` in the generated switch
- Non-nullable source with nullValue sentinel throws a clear `InvalidGenerationSourceError` at generation time
- All existing enum golden tests continue to pass (no regression)
- New golden test group passes
- enum-mapping.mdx is accurate for both anyUnmapped and nullValue usage
</success_criteria>

<output>
After completion, create `.planning/quick/260331-ghe-implement-nullvalue-as-source-in-enum-ma/260331-ghe-SUMMARY.md`
</output>
