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
import 'package:dart_mapper_generator/src/exceptions/ambiguous_source_field_error.dart';
import 'package:dart_mapper_generator/src/extensions/class_element.dart';
import 'package:dart_mapper_generator/src/extensions/dart_type.dart';
import 'package:dart_mapper_generator/src/extensions/element.dart';
import 'package:dart_mapper_generator/src/models/binding.dart';
import 'package:dart_mapper_generator/src/models/field/field.dart';
import 'package:dart_mapper_generator/src/models/instance.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/bases/mapping_method.dart';
import 'package:dart_mapper_generator/src/exceptions/invalid_comma_separated_source_part_error.dart';
import 'package:source_gen/source_gen.dart';

class StandardBindingsAnalyzer extends Analyzer<List<Binding>> {
  final Analyzer<MappingMethod?> extraMappingMethodAnalyzer;

  const StandardBindingsAnalyzer({
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
    final renamingMap = context.renamingMap;
    final renamingMapReversed = context.renamingMapReversed;
    final ignoredTargets = context.ignoredTargets;
    final forceNonNullTargets = context.forceNonNullTargets;
    final callableMap = context.callableMap;
    final defaultValueMap = context.defaultValueMap;
    final constantMap = context.constantMap;

    final isMultiSource = method.formalParameters.length > 1;

    // Build a map of fieldName -> [parameterNames] across ALL source parameters
    // to detect ambiguous fields in multi-source methods.
    final fieldToParams = <String, List<String>>{};
    if (isMultiSource) {
      for (final param in method.formalParameters) {
        final sourceClass = param.type.element?.classElementOrNull;
        for (final getter in sourceClass?.getterElements ?? <VariableElement>[]) {
          if (getter.name != null && param.name != null) {
            fieldToParams.update(
              getter.name!,
              (list) => list..add(param.name!),
              ifAbsent: () => [param.name!],
            );
          }
        }
      }
    }

    final targetClass = method.returnType.element?.classElementOrNull;
    final targetParam = targetClass?.constructorParameters
        .where((parameter) => parameter.name != null)
        .toList(growable: false)
        .asMap()
        .map((_, value) => MapEntry(value.name!, value));

    // --- Step 0: Process comma-source callable targets ---
    // Must run before Step 1 so that targets with comma+dot sources (e.g. "a.x,b.y")
    // are bound here and skipped by Step 1's dot-check.
    for (final entry in renamingMapReversed.entries) {
      final targetName = entry.key;
      final sourceExpression = entry.value;

      if (!sourceExpression.contains(',')) continue;
      if (boundTargets.contains(targetName)) continue;

      // validateCommaSeparatedSource() already guarantees callable is present when ',' appears.
      // Be defensive: skip if callableMap has no entry (should never happen post-validation).
      final callableMappingMethod = callableMap[targetName];
      if (callableMappingMethod == null) continue;

      final resolvedTargetParam = targetParam?[targetName];
      if (resolvedTargetParam == null) continue;

      final parts = sourceExpression.split(',').map((p) => p.trim()).toList();
      final resolvedSources = <Field>[];
      final resolvedChains = <List<(String, bool)>?>[];

      for (final part in parts) {
        if (part.contains('.')) {
          // Dot-path part — resolve using same param-detection logic as Step 1.
          final segments = part.split('.');
          FormalParameterElement? sourceMethodParam;
          List<String> traversalSegments;

          if (isMultiSource) {
            final paramName = segments.first;
            sourceMethodParam = method.formalParameters
                .where((p) => p.name == paramName)
                .firstOrNull;
            if (sourceMethodParam == null) {
              throw InvalidCommaSeparatedSourcePartError(
                part: part,
                target: targetName,
                element: method,
              );
            }
            traversalSegments = segments.sublist(1);
          } else {
            sourceMethodParam = method.formalParameters.firstOrNull;
            if (sourceMethodParam == null) continue;
            traversalSegments = segments;
          }

          if (traversalSegments.isEmpty) continue;

          final (resolvedField, accessChain) = _resolveDotNotation(
            segments: traversalSegments,
            startType: sourceMethodParam.type,
            instanceName: sourceMethodParam.name!,
            errorElement: method,
          );
          resolvedSources.add(resolvedField);
          resolvedChains.add(accessChain);
        } else {
          // Bare name — find which source param has this getter.
          // Ambiguity rules same as Step 3.
          FormalParameterElement? matchedParam;
          VariableElement? matchedGetter;

          for (final param in method.formalParameters) {
            final sourceClass = param.type.element?.classElementOrNull;
            final getter = sourceClass?.getterElements
                .where((g) => g.name == part)
                .firstOrNull;
            if (getter != null) {
              if (matchedParam != null) {
                // Ambiguous — found in multiple params.
                final params = fieldToParams[part] ?? [param.name ?? ''];
                throw AmbiguousSourceFieldError(
                  fieldName: part,
                  parameterNames: params,
                  element: method,
                );
              }
              matchedParam = param;
              matchedGetter = getter;
            }
          }

          if (matchedParam == null || matchedGetter == null) {
            throw InvalidCommaSeparatedSourcePartError(
              part: part,
              target: targetName,
              element: method,
            );
          }

          resolvedSources.add(
            Field.from(
              name: matchedGetter.name!,
              type: matchedGetter.type,
              required: matchedGetter.isRequired,
              nullable: matchedGetter.type.isNullable,
              instance: Instance(name: matchedParam.name!),
            ),
          );
          resolvedChains.add(null); // No access chain for bare field access.
        }
      }

      final targetField = Field.from(
        name: targetName,
        type: resolvedTargetParam.type,
        required: resolvedTargetParam.isRequired,
        nullable: resolvedTargetParam.type.isNullable,
      );

      bindings.add(
        Binding(
          source: resolvedSources.first, // keeps existing nullability guard working
          sources: resolvedSources,
          target: targetField,
          callableMappingMethod: callableMappingMethod,
          sourceAccessChains: resolvedChains,
          // Multi-arg callable owns nullability — suppress nullability throw (same as
          // callable+dot-path today). forceNonNull not needed.
        ),
      );
      boundTargets.add(targetName);
    }

    // --- Step 1: Process explicit dot-notation and qualified source mappings ---
    // For each target in renamingMapReversed, if the source contains a dot, resolve it.
    for (final entry in renamingMapReversed.entries) {
      final targetName = entry.key;
      final sourceExpression = entry.value;

      if (boundTargets.contains(targetName)) continue;
      if (!sourceExpression.contains('.')) {
        // Not dot notation — handled by the auto-resolution loop below (via renamingMap).
        continue;
      }

      final resolvedTargetParam = targetParam?[targetName];
      if (resolvedTargetParam == null) {
        continue;
      }

      final segments = sourceExpression.split('.');

      // Determine which source param to start from.
      FormalParameterElement? sourceMethodParam;
      List<String> traversalSegments;

      if (isMultiSource) {
        // In multi-source, the first segment is the parameter name.
        final paramName = segments.first;
        sourceMethodParam = method.formalParameters
            .where((p) => p.name == paramName)
            .firstOrNull;
        if (sourceMethodParam == null) {
          throw InvalidGenerationSourceError(
            "Source parameter '$paramName' not found in method '${method.name}'.\n"
            "Available parameters: ${method.formalParameters.map((p) => p.name).join(', ')}.\n"
            "Fix: Check dot notation source prefix matches a method parameter name.",
            element: method,
          );
        }
        traversalSegments = segments.sublist(1);
      } else {
        // In single-source, all segments are field traversal.
        sourceMethodParam = method.formalParameters.firstOrNull;
        if (sourceMethodParam == null) continue;
        traversalSegments = segments;
      }

      if (traversalSegments.isEmpty) continue;

      final (resolvedField, accessChain) = _resolveDotNotation(
        segments: traversalSegments,
        startType: sourceMethodParam.type,
        instanceName: sourceMethodParam.name!,
        errorElement: method,
      );

      final targetField = Field.from(
        name: targetName,
        type: resolvedTargetParam.type,
        required: resolvedTargetParam.isRequired,
        nullable: resolvedTargetParam.type.isNullable,
      );

      // Validate constant/defaultValue type compatibility for dot-notation targets.
      final dotConstant = constantMap[targetName];
      final dotDefault = defaultValueMap[targetName];
      if (dotConstant != null) {
        _validateValueType(dotConstant, resolvedTargetParam.type, targetName, method);
      }
      if (dotDefault != null) {
        _validateValueType(dotDefault, resolvedTargetParam.type, targetName, method);
      }

      // Per D-07: if the resolved source is nullable (due to nullable intermediates)
      // and the target is non-null, and forceNonNull is not set, throw.
      final chainHasNullable = accessChain.any((e) => e.$2);
      final resolvedIsNullable = resolvedField.nullable || chainHasNullable;
      final callableMappingMethod = callableMap[targetName];
      if (resolvedIsNullable &&
          !targetField.nullable &&
          !forceNonNullTargets.contains(targetName) &&
          defaultValueMap[targetName] == null &&
          callableMappingMethod == null) {
        throw InvalidGenerationSourceError(
          "Target field '$targetName' is non-nullable but the dot notation source "
          "'$sourceExpression' may be null (nullable intermediate in chain).\n"
          "Fix: Add forceNonNull: true or provide a defaultValue to handle the null case.",
          element: method,
        );
      }
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

      final resolvedTargetParam = targetParam?[targetName];
      if (resolvedTargetParam == null) continue;

      // Create a placeholder source field — expression factory ignores it when constant != null.
      final targetField = Field.from(
        name: targetName,
        type: resolvedTargetParam.type,
        required: resolvedTargetParam.isRequired,
        nullable: resolvedTargetParam.type.isNullable,
      );

      // Validate constant type compatibility.
      _validateValueType(constantValue, resolvedTargetParam.type, targetName, method);

      final placeholderSource = Field.from(
        name: targetName,
        type: resolvedTargetParam.type,
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

    // --- Step 3: Auto-resolve fields from source parameters ---
    for (final sourceMethodParam in method.formalParameters) {
      final sourceClass = sourceMethodParam.type.element?.classElementOrNull;
      final sourceGetters = sourceClass?.getterElements ?? <VariableElement>[];

      for (final sourceClassParam in sourceGetters) {
        if (sourceClassParam.name != null) {
          final targetNames =
              renamingMap[sourceClassParam.name!] ?? [sourceClassParam.name!];

          for (final targetClassParamName in targetNames) {
            // Skip already-bound targets (dot notation, constant, etc.)
            if (boundTargets.contains(targetClassParamName)) continue;

            final resolvedTargetParam = targetParam?[targetClassParamName];
            if (resolvedTargetParam == null || sourceMethodParam.name == null) {
              continue;
            }

            // D-02: Detect ambiguous fields in multi-source methods.
            // If this field name exists in multiple source params and no explicit
            // @Mapping source qualification was provided, throw.
            if (isMultiSource) {
              final params = fieldToParams[sourceClassParam.name!];
              if (params != null && params.length > 1) {
                // Only throw if there's no explicit @Mapping that resolves this target
                // from the current source parameter (prefix check prevents false suppression).
                final mappedSource = renamingMapReversed[targetClassParamName];
                final hasExplicitMapping = mappedSource != null &&
                    mappedSource.startsWith('${sourceClassParam.name}.');
                if (!hasExplicitMapping) {
                  throw AmbiguousSourceFieldError(
                    fieldName: sourceClassParam.name!,
                    parameterNames: params,
                    element: method,
                  );
                }
                // If there's an explicit mapping, skip auto-resolution for this field.
                continue;
              }
            }

            final sourceField = Field.from(
              name: sourceClassParam.name!,
              type: sourceClassParam.type,
              required: sourceClassParam.isRequired,
              nullable: sourceClassParam.type.isNullable,
              instance: Instance(name: sourceMethodParam.name!),
            );
            final targetField = Field.from(
              name: targetClassParamName,
              type: resolvedTargetParam.type,
              required: resolvedTargetParam.isRequired,
              nullable: resolvedTargetParam.type.isNullable,
            );

            final callableMappingMethod = callableMap[targetClassParamName];
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
                ignored: ignoredTargets.contains(targetClassParamName),
                forceNonNull:
                    forceNonNullTargets.contains(targetClassParamName),
                callableMappingMethod: callableMappingMethod,
                extraMappingMethod: extraMappingMethod,
                defaultValue: defaultValueMap[targetClassParamName],
              ),
            );
            boundTargets.add(targetClassParamName);
          }
        }
      }
    }

    return bindings;
  }

  /// Resolves a dot-notation source path like 'address.street' or (in single-source)
  /// traverses segments starting from [startType].
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

      // The nullability of the access is whether the CURRENT type (parent) is nullable.
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

  void _validateValueType(
    String value,
    DartType type,
    String targetName,
    Element method,
  ) {
    final targetType = type.getDisplayString();
    final baseType = type.isDartCoreNull ? null : targetType.replaceAll('?', '');

    if (baseType == 'bool') {
      if (value != 'true' && value != 'false') {
        throw InvalidGenerationSourceError(
          "@Mapping constant/defaultValue '$value' is not compatible with target field '$targetName' "
          "of type '$targetType'. Expected a $targetType literal.",
          element: method,
        );
      }
    } else if (baseType == 'int') {
      if (int.tryParse(value) == null) {
        throw InvalidGenerationSourceError(
          "@Mapping constant/defaultValue '$value' is not compatible with target field '$targetName' "
          "of type '$targetType'. Expected a $targetType literal.",
          element: method,
        );
      }
    } else if (baseType == 'double') {
      if (double.tryParse(value) == null) {
        throw InvalidGenerationSourceError(
          "@Mapping constant/defaultValue '$value' is not compatible with target field '$targetName' "
          "of type '$targetType'. Expected a $targetType literal.",
          element: method,
        );
      }
    } else if (baseType == 'num') {
      if (int.tryParse(value) == null && double.tryParse(value) == null) {
        throw InvalidGenerationSourceError(
          "@Mapping constant/defaultValue '$value' is not compatible with target field '$targetName' "
          "of type '$targetType'. Expected a $targetType literal.",
          element: method,
        );
      }
    }
    // String and other types: skip validation
  }
}
