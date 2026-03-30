/*
 * Copyright (c) 2025 MyLittleSuite
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

import 'package:analyzer/dart/element/type.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/bases/bindable_mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapping_behavior.dart';

/// One (sourceSubtype, targetType, delegateMethodName) triple produced by
/// a single @SubclassMapping annotation on the mapper class.
final class SubclassDispatchPair {
  /// The concrete source subtype matched in the switch arm (e.g., Dog).
  final DartType sourceType;

  /// The target type produced for this source subtype (e.g., DogDto).
  final DartType targetType;

  /// The name of the existing mapping method to delegate to (e.g., 'toDogDto').
  final String delegateMethod;

  const SubclassDispatchPair({
    required this.sourceType,
    required this.targetType,
    required this.delegateMethod,
  });
}

/// Represents a mapping method whose body is a Dart 3 switch-expression
/// dispatching on source runtime type rather than field mapping.
///
/// Generated body example (needsWildcard: true):
/// ```dart
/// @override
/// AnimalDto toDto(Animal source) => switch (source) {
///   Dog dog => toDogDto(dog),
///   Cat cat => toCatDto(cat),
///   _ => throw ArgumentError('Unexpected subtype: ${source.runtimeType}'),
/// };
/// ```
final class SubclassMappingMethod extends BindableMappingMethod {
  /// Ordered list of type-dispatch pairs; order matches @SubclassMapping
  /// annotation declaration order on the mapper class.
  final List<SubclassDispatchPair> dispatchPairs;

  /// True when a wildcard fallthrough must be emitted.
  ///
  /// Per D-04: false only when the source class is sealed AND every direct
  /// subtype of the sealed class is covered by a dispatchPair entry.
  /// In all other cases (non-sealed source, or sealed with partial coverage),
  /// this is true and a `_ => throw ArgumentError(...)` arm is emitted.
  final bool needsWildcard;

  const SubclassMappingMethod({
    required super.name,
    super.returnType,
    super.optionalReturn = false,
    super.isOverride = true,
    super.parameters = const [],
    super.bindings = const [],
    super.behavior = MappingBehavior.standard,
    required this.dispatchPairs,
    required this.needsWildcard,
  });
}
