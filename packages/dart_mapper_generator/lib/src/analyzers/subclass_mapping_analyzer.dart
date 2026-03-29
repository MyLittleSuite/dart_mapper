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
import 'package:dart_mapper_generator/src/analyzers/contexts/analyzer_context.dart';
import 'package:dart_mapper_generator/src/exceptions/no_subclass_mapping_method_error.dart';
import 'package:dart_mapper_generator/src/extensions/annotations.dart';
import 'package:dart_mapper_generator/src/extensions/dart_type.dart';
import 'package:dart_mapper_generator/src/extensions/element.dart';
import 'package:dart_mapper_generator/src/models/field/field.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/mapping_parameter.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/subclass_mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapping_behavior.dart';

/// Reads all @SubclassMapping annotations from a mapper ClassElement and
/// produces SubclassMappingMethod instances — one per abstract method whose
/// source parameter type is a base type referenced by the annotations.
class SubclassMappingAnalyzer {
  const SubclassMappingAnalyzer();

  /// Returns a list of [SubclassMappingMethod]s to inject into the method list.
  /// Returns empty list when no @SubclassMapping annotations are on the class.
  List<SubclassMappingMethod> analyze(AnalyzerContext context) {
    final pairs = SubclassMappingAnnotation.loadAll(context.mapperClass).toList();
    if (pairs.isEmpty) return [];

    // Bucket by abstract method, not by base type set.
    // Each abstract method with exactly one parameter gets its own
    // SubclassMappingMethod — avoids collision when two abstract methods
    // share the same parameter type but have different return types.
    final result = <SubclassMappingMethod>[];
    for (final method in context.mapperClass.methods.where(
      (m) => m.isAbstract && m.formalParameters.length == 1,
    )) {
      final paramType = method.formalParameters.first.type;
      // Collect only the pairs applicable to THIS abstract method.
      final matchingPairs = pairs
          .where((p) => _isSubtypeOf(p.sourceType, paramType))
          .toList();
      if (matchingPairs.isEmpty) continue;

      final dispatchPairs = <SubclassDispatchPair>[];
      for (final pair in matchingPairs) {
        final delegateName = _resolveDelegateMethod(
          context: context,
          sourceType: pair.sourceType,
          targetType: pair.targetType,
        );
        dispatchPairs.add(SubclassDispatchPair(
          sourceType: pair.sourceType,
          targetType: pair.targetType,
          delegateMethod: delegateName,
        ));
      }

      final needsWildcard = _computeNeedsWildcard(
        baseType: paramType,
        dispatchPairs: dispatchPairs,
      );

      result.add(SubclassMappingMethod(
        name: method.name!,
        returnType: method.returnType,
        optionalReturn: method.returnType.isNullable,
        isOverride: true,
        parameters: method.formalParameters
            .map((p) => MappingParameter(
                  field: Field.from(
                    name: p.name!,
                    type: p.type,
                    nullable: p.isNullable,
                  ),
                  isNullable: p.isNullable,
                ))
            .toList(growable: false),
        bindings: const [],
        behavior: MappingBehavior.standard,
        dispatchPairs: dispatchPairs,
        needsWildcard: needsWildcard,
      ));
    }

    return result;
  }

  /// Returns true when [subtype] is a direct or indirect subtype of [base].
  bool _isSubtypeOf(DartType subtype, DartType base) {
    final subtypeElement = subtype.element?.classElementOrNull;
    if (subtypeElement == null) return false;
    final baseLibUri = base.element?.library?.firstFragment.source.uri;
    // Normalize nullability on BOTH sides so that e.g. `Pet?` matches `Pet`.
    final baseDisplayNormalized = base.displayString.replaceAll('?', '');
    return subtypeElement.allSupertypes.any(
      (supertype) =>
          supertype.element.library.firstFragment.source.uri == baseLibUri &&
          supertype.getDisplayString().replaceAll('?', '') ==
              baseDisplayNormalized,
    );
  }

  /// Resolves the delegate method name for a given @SubclassMapping pair.
  /// Throws [NoSubclassMappingMethodError] when no matching method is found (D-06).
  String _resolveDelegateMethod({
    required AnalyzerContext context,
    required DartType sourceType,
    required DartType targetType,
  }) {
    final match = context.mapperClass.methods
        .where(
          (m) =>
              m.formalParameters.length == 1 &&
              m.formalParameters.first.type
                  .same(sourceType, useNullability: false) &&
              m.returnType.same(targetType, useNullability: false),
        )
        .firstOrNull;

    if (match == null) {
      throw NoSubclassMappingMethodError(
        sourceType: sourceType,
        targetType: targetType,
        mapperClass: context.mapperClass,
      );
    }

    return match.name!;
  }

  /// Computes whether a wildcard fallthrough arm must be emitted (D-04).
  ///
  /// Returns false only when [baseType] is sealed AND every direct subtype
  /// of [baseType] within the sealed class's own library is present in
  /// [dispatchPairs]. In all other cases returns true.
  bool _computeNeedsWildcard({
    required DartType baseType,
    required List<SubclassDispatchPair> dispatchPairs,
  }) {
    final baseElement = baseType.element?.classElementOrNull;
    if (baseElement == null || !baseElement.isSealed) return true;

    // Scan the sealed class's own library for subtypes.
    // Uses allSupertypes to include classes that implement or mixin the sealed
    // base (not just direct extends), so sealed interface coverage is complete.
    final directSubtypes = baseElement.library.classes
        .where((cls) => cls.allSupertypes.any((t) => t.element == baseElement))
        .toList();

    if (directSubtypes.isEmpty) return true;

    // All direct subtypes must be in dispatchPairs.
    return !directSubtypes.every((subtype) =>
        dispatchPairs.any((p) => p.sourceType.element == subtype));
  }
}
