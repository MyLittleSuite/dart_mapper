/*
 * Copyright (c) 2024 MyLittleSuite
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

import 'package:dart_mapper/src/value_mapping.dart';
import 'package:dart_mapper_generator/src/analyzers/contexts/method_analyzer_context.dart';
import 'package:dart_mapper_generator/src/exceptions/invalid_comma_separated_source_error.dart';
import 'package:dart_mapper_generator/src/exceptions/invalid_mapping_combination_error.dart';
import 'package:dart_mapper_generator/src/extensions/annotations.dart';
import 'package:dart_mapper_generator/src/models/annotations/resolved_mapping.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/callable_mapping_method.dart';

class BindingsAnalyzerContext extends MethodAnalyzerContext {
  final Iterable<ResolvedMapping>? inheritedRenaming;
  final Iterable<ResolvedMapping>? inheritedRenamingReversed;

  const BindingsAnalyzerContext({
    required super.mapperAnnotation,
    required super.mapperUsages,
    required super.internalMapperUsages,
    required super.mapperClass,
    required super.method,
    required super.importAliases,
    this.inheritedRenaming,
    this.inheritedRenamingReversed,
  });

  Map<String, List<String>> get renamingMap => _renamingMappings
      .where((annotation) => annotation.source != null)
      .fold<Map<String, List<String>>>({}, (map, element) {
    map.update(
      element.source!,
      (targets) => targets..add(element.target),
      ifAbsent: () => [element.target],
    );
    return map;
  });

  Map<String, String> get renamingMapReversed => Map.fromEntries(
        renamingMap.entries.expand(
          (entry) => entry.value.map((target) => MapEntry(target, entry.key)),
        ),
      );

  Map<String, String> get defaultValueMap => Map.fromEntries(
        _renamingMappings
            .where((annotation) => annotation.defaultValue != null)
            .map(
              (annotation) =>
                  MapEntry(annotation.target, annotation.defaultValue!),
            ),
      );

  Map<String, String> get constantMap => Map.fromEntries(
        _renamingMappings
            .where((annotation) => annotation.constant != null)
            .map(
              (annotation) =>
                  MapEntry(annotation.target, annotation.constant!),
            ),
      );

  void validateMappingCombinations() {
    for (final annotation in _renamingMappings) {
      if (annotation.constant != null) {
        if (annotation.source != null) {
          throw InvalidMappingCombinationError(
            target: annotation.target,
            conflictDescription: 'constant cannot be combined with source',
            element: method,
          );
        }
        if (annotation.defaultValue != null) {
          throw InvalidMappingCombinationError(
            target: annotation.target,
            conflictDescription:
                'constant cannot be combined with defaultValue',
            element: method,
          );
        }
        if (annotation.callable != null) {
          throw InvalidMappingCombinationError(
            target: annotation.target,
            conflictDescription: 'constant cannot be combined with callable',
            element: method,
          );
        }
        if (annotation.ignore == true) {
          throw InvalidMappingCombinationError(
            target: annotation.target,
            conflictDescription: 'constant cannot be combined with ignore',
            element: method,
          );
        }
      }
      if (annotation.defaultValue != null && annotation.callable != null) {
        throw InvalidMappingCombinationError(
          target: annotation.target,
          conflictDescription: 'defaultValue cannot be combined with callable',
          element: method,
        );
      }
    }
  }

  void validateCommaSeparatedSource() {
    for (final annotation in _renamingMappings) {
      if (annotation.source != null &&
          annotation.source!.contains(',') &&
          annotation.callable == null) {
        throw InvalidCommaSeparatedSourceError(
          target: annotation.target,
          element: method,
        );
      }
    }
  }

  Set<String> get ignoredTargets => MappingAnnotation.load(method)
      .where((annotation) => annotation.ignore)
      .map((annotation) => annotation.target)
      .toSet();

  Set<String> get forceNonNullTargets => MappingAnnotation.load(method)
      .where((annotation) => annotation.forceNonNull)
      .map((annotation) => annotation.target)
      .toSet();

  Map<String, String> get enumValues => Map.fromEntries(
        ValueMappingAnnotation.load(method).map(
          (element) => MapEntry(element.source, element.target),
        ),
      );

  Map<String, List<String>> get enumValuesReversed =>
      enumValues.entries.fold<Map<String, List<String>>>(
        {},
        (previousValue, element) => previousValue
          ..update(
            element.value,
            (value) => value..add(element.key),
            ifAbsent: () => [element.key],
          ),
      );

  String? get anyRemainingTarget => enumValues[ValueMapping.anyRemaining];

  bool get hasAnyUnmapped => enumValues.containsKey(ValueMapping.anyUnmapped);

  Map<String, CallableMappingMethod> get callableMap => Map.fromEntries(
        _renamingMappings
            .where((annotation) => annotation.callable != null)
            .map(
              (annotation) => MapEntry(
                annotation.target,
                CallableMappingMethod.from(annotation.callable!),
              ),
            ),
      );

  Iterable<ResolvedMapping> get _renamingMappings => [
        ...?inheritedRenaming,
        ...?inheritedRenamingReversed,
        ...MappingAnnotation.load(method),
      ];
}
