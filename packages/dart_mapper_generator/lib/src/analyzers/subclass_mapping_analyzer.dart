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

    // Group pairs by base type (the abstract method's parameter type).
    // Each unique base type becomes one dispatch method.
    // We detect which abstract methods are "base" methods by checking whether
    // any @SubclassMapping pair's source type is a subtype of the method's
    // parameter type.
    final baseTypes = <DartType>{};
    for (final pair in pairs) {
      for (final method in context.mapperClass.methods.where((m) => m.isAbstract)) {
        if (method.formalParameters.length != 1) continue;
        final paramType = method.formalParameters.first.type;
        // Check: is pair.sourceType a subtype of paramType?
        if (_isSubtypeOf(pair.sourceType, paramType)) {
          baseTypes.add(paramType);
        }
      }
    }

    final result = <SubclassMappingMethod>[];
    for (final baseType in baseTypes) {
      // Collect all pairs that are subtypes of this base type.
      final matchingPairs = pairs
          .where((p) => _isSubtypeOf(p.sourceType, baseType))
          .toList();

      // Resolve delegate methods and compute dispatch pairs.
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

      // Find the abstract dispatch method (the one with baseType as parameter).
      final abstractMethod = context.mapperClass.methods.firstWhere(
        (m) =>
            m.isAbstract &&
            m.formalParameters.length == 1 &&
            m.formalParameters.first.type.same(baseType, useNullability: false),
      );

      // Compute needsWildcard per D-04.
      final needsWildcard = _computeNeedsWildcard(
        baseType: baseType,
        dispatchPairs: dispatchPairs,
      );

      result.add(SubclassMappingMethod(
        name: abstractMethod.name!,
        returnType: abstractMethod.returnType,
        optionalReturn: abstractMethod.returnType.isNullable,
        isOverride: true,
        parameters: abstractMethod.formalParameters
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
    final baseDisplayString = base.displayString;
    return subtypeElement.allSupertypes.any(
      (supertype) =>
          supertype.element.library.firstFragment.source.uri == baseLibUri &&
          supertype.getDisplayString().replaceAll('?', '') == baseDisplayString,
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

    // Scan the sealed class's own library for direct subtypes only.
    // (Sealed classes can only be extended within the same library.)
    final directSubtypes = baseElement.library.classes
        .where((cls) => cls.supertype?.element == baseElement)
        .toList();

    if (directSubtypes.isEmpty) return true;

    // All direct subtypes must be in dispatchPairs.
    return !directSubtypes.every((subtype) =>
        dispatchPairs.any((p) => p.sourceType.element == subtype));
  }
}
