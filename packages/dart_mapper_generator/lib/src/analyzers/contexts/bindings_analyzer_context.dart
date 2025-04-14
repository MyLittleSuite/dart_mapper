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

import 'package:dart_mapper_generator/src/analyzers/contexts/method_analyzer_context.dart';
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

  Map<String, String> get renamingMap => Map.fromEntries(
        _renamingMappings
            .where((annotation) => annotation.source != null)
            .map((element) => MapEntry(element.source!, element.target)),
      );

  Map<String, String> get renamingMapReversed =>
      renamingMap.map((key, value) => MapEntry(value, key));

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

  Map<String, String> get enumValuesReversed =>
      enumValues.map((key, value) => MapEntry(value, key));

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
