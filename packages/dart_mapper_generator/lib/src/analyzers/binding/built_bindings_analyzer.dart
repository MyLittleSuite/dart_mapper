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

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dart_mapper_generator/src/analyzers/analyzer.dart';
import 'package:dart_mapper_generator/src/analyzers/contexts/analyzer_context.dart';
import 'package:dart_mapper_generator/src/analyzers/contexts/bindings_analyzer_context.dart';
import 'package:dart_mapper_generator/src/analyzers/contexts/fields_analyzer_context.dart';
import 'package:dart_mapper_generator/src/exceptions/too_many_constructor_parameters_error.dart';
import 'package:dart_mapper_generator/src/exceptions/unknown_target_class_error.dart';
import 'package:dart_mapper_generator/src/extensions/class_element.dart';
import 'package:dart_mapper_generator/src/extensions/dart_type.dart';
import 'package:dart_mapper_generator/src/extensions/element.dart';
import 'package:dart_mapper_generator/src/models/binding.dart';
import 'package:dart_mapper_generator/src/models/field/field.dart';
import 'package:dart_mapper_generator/src/models/instance.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/bases/mapping_method.dart';
import 'package:source_gen/source_gen.dart';

class BuiltBindingsAnalyzer extends Analyzer<List<Binding>> {
  final Analyzer<MappingMethod?> extraMappingMethodAnalyzer;

  BuiltBindingsAnalyzer({
    required this.extraMappingMethodAnalyzer,
  });

  @override
  List<Binding> analyze(AnalyzerContext context) {
    if (context is! BindingsAnalyzerContext) {
      throw ArgumentError('context must be a BindingsAnalyzerContext');
    }

    context.validateMappingCombinations();
    context.validateCommaSeparatedSource();

    final bindings = <Binding>[];
    // Track which target names already have a binding to avoid duplicates.
    final boundTargets = <String>{};

    final method = context.method;
    final renamingMapReversed = context.renamingMapReversed;
    final ignoredTargets = context.ignoredTargets;
    final forceNonNullTargets = context.forceNonNullTargets;
    final callableMap = context.callableMap;
    final defaultValueMap = context.defaultValueMap;
    final constantMap = context.constantMap;

    final targetClass = method.returnType.element?.classElementOrNull;
    if (targetClass == null) {
      throw UnknownTargetClassError(
        mapperClass: context.mapperClass,
        method: method,
      );
    }

    final targetConstructor = targetClass.primaryConstructor;
    if (targetConstructor.formalParameters.length > 1) {
      throw TooManyConstructorParametersError(targetClass);
    }

    // --- Step 1: Process explicit dot-notation source mappings ---
    for (final entry in renamingMapReversed.entries) {
      final targetName = entry.key;
      final sourceExpression = entry.value;

      if (!sourceExpression.contains('.')) {
        // Not dot notation — handled by the main target-getter loop below.
        continue;
      }

      final targetGetter = targetClass.getFieldOrGetter(targetName);
      if (targetGetter == null) continue;

      final segments = sourceExpression.split('.');

      // Determine which source param to start from.
      // BuiltBindingsAnalyzer iterates source method parameters.
      final isMultiSource = method.formalParameters.length > 1;
      final sourceMethodParam = isMultiSource
          ? method.formalParameters
              .where((p) => p.name == segments.first)
              .firstOrNull
          : method.formalParameters.firstOrNull;

      if (sourceMethodParam == null) {
        if (isMultiSource) {
          throw InvalidGenerationSourceError(
            "Source parameter '${segments.first}' not found in method '${method.name}'.\n"
            "Available parameters: ${method.formalParameters.map((p) => p.name).join(', ')}.\n"
            "Fix: Check dot notation source prefix matches a method parameter name.",
            element: method,
          );
        }
        continue;
      }

      final traversalSegments =
          isMultiSource ? segments.sublist(1) : segments;
      if (traversalSegments.isEmpty) continue;

      final (resolvedField, accessChain) = _resolveDotNotation(
        segments: traversalSegments,
        startType: sourceMethodParam.type,
        instanceName: sourceMethodParam.name!,
        errorElement: method,
      );

      final targetField = Field.from(
        name: targetName,
        type: targetGetter.type,
        required: targetGetter.isRequired,
        nullable: targetGetter.type.isNullable,
      );

      // Per D-07: nullable chain to non-null target validation.
      final chainHasNullable = accessChain.any((e) => e.$2);
      final resolvedIsNullable = resolvedField.nullable || chainHasNullable;
      if (resolvedIsNullable &&
          !targetField.nullable &&
          !forceNonNullTargets.contains(targetName) &&
          defaultValueMap[targetName] == null) {
        throw InvalidGenerationSourceError(
          "Target field '$targetName' is non-nullable but the dot notation source "
          "'$sourceExpression' may be null (nullable intermediate in chain).\n"
          "Fix: Add forceNonNull: true or provide a defaultValue to handle the null case.",
          element: method,
        );
      }

      final callableMappingMethod = callableMap[targetName];
      final extraMappingMethod = callableMappingMethod == null
          ? extraMappingMethodAnalyzer.analyze(
              FieldsAnalyzerContext(
                mapperAnnotation: context.mapperAnnotation,
                mapperUsages: context.mapperUsages,
                internalMapperUsages: context.internalMapperUsages,
                mapperClass: context.mapperClass,
                importAliases: context.importAliases,
                source: resolvedField,
                target: targetField,
              ),
            )
          : null;

      bindings.add(
        Binding(
          source: resolvedField,
          target: targetField,
          ignored: ignoredTargets.contains(targetName),
          forceNonNull: forceNonNullTargets.contains(targetName),
          callableMappingMethod: callableMappingMethod,
          extraMappingMethod: extraMappingMethod,
          defaultValue: defaultValueMap[targetName],
          accessChain: accessChain,
        ),
      );
      boundTargets.add(targetName);
    }

    // --- Step 2: Process constant-only mappings (no source reference) ---
    for (final entry in constantMap.entries) {
      final targetName = entry.key;
      final constantValue = entry.value;

      if (boundTargets.contains(targetName)) continue;

      final targetGetter = targetClass.getFieldOrGetter(targetName);
      if (targetGetter == null) continue;

      final targetField = Field.from(
        name: targetName,
        type: targetGetter.type,
        required: targetGetter.isRequired,
        nullable: targetGetter.type.isNullable,
      );
      final placeholderSource = Field.from(
        name: targetName,
        type: targetGetter.type,
        required: false,
        nullable: true,
      );

      bindings.add(
        Binding(
          source: placeholderSource,
          target: targetField,
          ignored: false,
          forceNonNull: false,
          constant: constantValue,
        ),
      );
      boundTargets.add(targetName);
    }

    // --- Step 3: Auto-resolve fields from target getters ---
    for (final sourceMethodParam in method.formalParameters) {
      final sourceClass = sourceMethodParam.type.element?.classElementOrNull;

      for (final targetGetter in targetClass.getterElements) {
        if (targetGetter.name != null) {
          final targetName = targetGetter.name!;

          // Skip already-bound targets.
          if (boundTargets.contains(targetName)) continue;

          final sourceFieldName =
              renamingMapReversed[targetName] ?? targetName;

          // Skip dot notation sources — handled above.
          if (sourceFieldName.contains('.')) continue;

          final sourceClassParam = sourceClass?.getFieldOrGetter(
            sourceFieldName,
          );

          if (sourceClassParam != null && sourceMethodParam.name != null) {
            final sourceField = Field.from(
              name: sourceFieldName,
              type: sourceClassParam.type,
              required: sourceClassParam.isRequired,
              nullable: sourceClassParam.type.isNullable,
              instance: Instance(name: sourceMethodParam.name!),
            );
            final targetField = Field.from(
              name: targetName,
              type: targetGetter.type,
              required: targetGetter.isRequired,
              nullable: targetGetter.type.isNullable,
            );

            final callableMappingMethod = callableMap[targetName];
            final extraMappingMethod = callableMappingMethod == null
                ? extraMappingMethodAnalyzer.analyze(
                    FieldsAnalyzerContext(
                      mapperAnnotation: context.mapperAnnotation,
                      mapperUsages: context.mapperUsages,
                      internalMapperUsages: context.internalMapperUsages,
                      mapperClass: context.mapperClass,
                      importAliases: context.importAliases,
                      source: sourceField,
                      target: targetField,
                    ),
                  )
                : null;

            bindings.add(
              Binding(
                source: sourceField,
                target: targetField,
                ignored: ignoredTargets.contains(targetName),
                forceNonNull: forceNonNullTargets.contains(targetName),
                callableMappingMethod: callableMappingMethod,
                extraMappingMethod: extraMappingMethod,
                defaultValue: defaultValueMap[targetName],
              ),
            );
            boundTargets.add(targetName);
          }
        }
      }
    }

    return bindings;
  }

  /// Resolves a dot-notation source path by traversing field segments.
  /// Returns (resolvedField, accessChain) where each accessChain entry is
  /// (segmentName, isParentNullable) — tracking whether the parent was nullable
  /// at that point (to generate ?. vs .).
  (Field, List<(String, bool)>) _resolveDotNotation({
    required List<String> segments,
    required DartType startType,
    required String instanceName,
    required Element errorElement,
  }) {
    DartType currentType = startType;
    final accessChain = <(String, bool)>[];

    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final classElement = currentType.element?.classElementOrNull;
      if (classElement == null) {
        throw InvalidGenerationSourceError(
          "Cannot traverse '$segment' on type '${currentType.getDisplayString()}' "
          "— type is not a class.\n"
          "Check that each segment in the dot notation path refers to a valid class property.",
          element: errorElement,
        );
      }

      final field = classElement.getFieldOrGetter(segment);
      if (field == null) {
        throw InvalidGenerationSourceError(
          "Property '$segment' not found on type '${currentType.getDisplayString()}' "
          "while resolving dot notation path.\n"
          "Available properties: ${classElement.getterElements.map((e) => e.name).join(', ')}.\n"
          "Fix: Check the dot notation path for typos.",
          element: errorElement,
        );
      }

      final parentIsNullable = currentType.isNullable;
      accessChain.add((segment, parentIsNullable));
      currentType = field.type;
    }

    final lastSegment = segments.last;
    final resolvedField = Field.from(
      name: lastSegment,
      type: currentType,
      required: false,
      nullable: currentType.isNullable,
      instance: Instance(name: instanceName),
    );

    return (resolvedField, accessChain);
  }
}
