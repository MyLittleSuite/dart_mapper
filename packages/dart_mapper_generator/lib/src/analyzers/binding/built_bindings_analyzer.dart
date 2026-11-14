/*
 * Copyright (c) 2026 MyLittleSuite
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
import 'package:dart_mapper_generator/src/analyzers/mapping_method/method_signature_lookup.dart';
import 'package:dart_mapper_generator/src/exceptions/ambiguous_source_field_error.dart';
import 'package:dart_mapper_generator/src/exceptions/invalid_comma_separated_source_part_error.dart';
import 'package:dart_mapper_generator/src/exceptions/invalid_nested_target_error.dart';
import 'package:dart_mapper_generator/src/exceptions/too_many_constructor_parameters_error.dart';
import 'package:dart_mapper_generator/src/exceptions/unknown_target_class_error.dart';
import 'package:dart_mapper_generator/src/extensions/class_element.dart';
import 'package:dart_mapper_generator/src/extensions/dart_type.dart';
import 'package:dart_mapper_generator/src/extensions/element.dart';
import 'package:dart_mapper_generator/src/models/binding.dart';
import 'package:dart_mapper_generator/src/models/field/field.dart';
import 'package:dart_mapper_generator/src/models/instance.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/bases/mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/callable_mapping_method.dart';
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
    final qualifiedByMap = context.qualifiedByMap;
    final lookup = MethodSignatureLookup(context);

    final targetClass = method.returnType.element?.classElementOrNull;
    if (targetClass == null) {
      throw UnknownTargetClassError(
        mapperClass: context.mapperClass,
        method: method,
      );
    }

    final nestedTarget = context.configuredTargets
        .where((target) => target.contains('.'))
        .firstOrNull;
    if (nestedTarget != null) {
      throw InvalidNestedTargetError(
        target: nestedTarget,
        description: 'nested targets cannot build a built_value class',
        element: method,
      );
    }

    final targetConstructor = targetClass.mainConstructor;
    if (targetConstructor.formalParameters.length > 1) {
      throw TooManyConstructorParametersError(targetClass);
    }

    // The converter of a single source: the method picked by `qualifiedBy`
    // when set, otherwise the one the extra mapping method analyzer finds.
    MappingMethod? extraMethodFor({
      required String targetName,
      required Field source,
      required Field target,
      required bool nullableChain,
      required String description,
    }) {
      if (callableMap[targetName] != null ||
          ignoredTargets.contains(targetName)) {
        return null;
      }
      final qualifiedBy = qualifiedByMap[targetName];
      if (qualifiedBy != null) {
        return lookup.find(
          target: targetName,
          arguments: [
            SourceArgument(
              type: source.type,
              description: description,
              nullableChain: nullableChain,
            ),
          ],
          targetType: target.type,
          qualifiedBy: qualifiedBy,
        );
      }
      return extraMappingMethodAnalyzer.analyze(
        FieldsAnalyzerContext(
          mapperAnnotation: context.mapperAnnotation,
          mapperUsages: context.mapperUsages,
          internalMapperUsages: context.internalMapperUsages,
          mapperClass: context.mapperClass,
          importAliases: context.importAliases,
          source: source,
          target: target,
        ),
      );
    }

    // --- Step 0: comma-separated sources (`source: 'a,b'`) ---
    // The value is computed by the callable or, without one, by the mapper
    // method whose parameters accept the sources in order. Runs before Step 1
    // so that comma + dot sources (`a.x,b.y`) are bound here.
    final isMultiSource = method.formalParameters.length > 1;
    for (final entry in renamingMapReversed.entries) {
      final targetName = entry.key;
      final sourceExpression = entry.value;

      if (!sourceExpression.contains(',')) continue;
      if (boundTargets.contains(targetName)) continue;

      final targetGetter = targetClass.getFieldOrGetter(targetName);
      if (targetGetter == null) continue;

      final parts = sourceExpression.split(',').map((p) => p.trim()).toList();
      final resolvedSources = <Field>[];
      final resolvedChains = <List<(String, bool)>?>[];
      final descriptions = <String>[];

      for (final part in parts) {
        if (part.contains('.')) {
          final segments = part.split('.');
          FormalParameterElement? sourceMethodParam;
          List<String> traversalSegments;

          if (isMultiSource) {
            sourceMethodParam = method.formalParameters
                .where((p) => p.name == segments.first)
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

          if (traversalSegments.isEmpty) {
            // A bare parameter name (`param.`) is not a path.
            throw InvalidCommaSeparatedSourcePartError(
              part: part,
              target: targetName,
              element: method,
            );
          }

          final (resolvedField, accessChain) = _resolveDotNotation(
            segments: traversalSegments,
            startType: sourceMethodParam.type,
            instanceName: sourceMethodParam.name!,
            errorElement: method,
          );
          resolvedSources.add(resolvedField);
          resolvedChains.add(accessChain);
          descriptions.add(
            '${sourceMethodParam.name}.${traversalSegments.join('.')}',
          );
        } else {
          final (matchedParam, matchedGetter) = _resolveBareSource(
            part: part,
            method: method,
            target: targetName,
          );
          if (matchedGetter != null) {
            resolvedSources.add(
              Field.from(
                name: matchedGetter.name!,
                type: matchedGetter.type,
                required: matchedGetter.isRequired,
                nullable: matchedGetter.type.isNullable,
                instance: Instance(name: matchedParam.name!),
              ),
            );
            descriptions.add('${matchedParam.name}.${matchedGetter.name}');
          } else {
            // A method parameter used as a source.
            resolvedSources.add(
              Field.from(
                name: matchedParam.name!,
                type: matchedParam.type,
                nullable: matchedParam.type.isNullable,
              ),
            );
            descriptions.add(matchedParam.name!);
          }
          resolvedChains.add(null);
        }
      }

      if (resolvedSources.isEmpty) continue;

      final targetField = Field.from(
        name: targetName,
        type: targetGetter.type,
        required: targetGetter.isRequired,
        nullable: targetGetter.type.isNullable,
      );

      final callableMappingMethod = callableMap[targetName];
      MappingMethod? sourcesMappingMethod;
      if (callableMappingMethod == null) {
        sourcesMappingMethod = lookup.find(
          target: targetName,
          arguments: [
            for (var i = 0; i < resolvedSources.length; i++)
              SourceArgument(
                type: resolvedSources[i].type,
                description: descriptions[i],
                nullableChain: resolvedChains[i]?.any((e) => e.$2) ?? false,
              ),
          ],
          targetType: targetField.type,
          qualifiedBy: qualifiedByMap[targetName],
        );
      }

      bindings.add(
        Binding(
          source: resolvedSources.first,
          sources: resolvedSources,
          target: targetField,
          ignored: ignoredTargets.contains(targetName),
          callableMappingMethod: callableMappingMethod,
          sourcesMappingMethod: sourcesMappingMethod,
          sourceAccessChains: resolvedChains,
          defaultValue: defaultValueMap[targetName],
        ),
      );
      boundTargets.add(targetName);
    }

    // --- Step 1: Process explicit dot-notation source mappings ---
    for (final entry in renamingMapReversed.entries) {
      final targetName = entry.key;
      final sourceExpression = entry.value;

      if (boundTargets.contains(targetName)) continue;
      if (!sourceExpression.contains('.')) {
        // Not dot notation — handled by the main target-getter loop below.
        continue;
      }

      final targetGetter = targetClass.getFieldOrGetter(targetName);
      if (targetGetter == null) continue;

      final segments = sourceExpression.split('.');

      // Determine which source param to start from.
      // BuiltBindingsAnalyzer iterates source method parameters.
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

      final traversalSegments = isMultiSource ? segments.sublist(1) : segments;
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

      final isIgnored = ignoredTargets.contains(targetName);
      final callableMappingMethod = callableMap[targetName];
      // Ignored targets must not synthesize a nested converter: analyzing
      // it would surface binding errors for a mapping that is never emitted.
      final extraMappingMethod = extraMethodFor(
        targetName: targetName,
        source: resolvedField,
        target: targetField,
        nullableChain: chainHasNullable,
        description: '${sourceMethodParam.name}.${traversalSegments.join('.')}',
      );

      bindings.add(
        Binding(
          source: resolvedField,
          target: targetField,
          ignored: isIgnored,
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

    // --- Step 2.5: method parameters named as the source of a target ---
    // `@Mapping(source: 'id', target: 'key')` where `id` is a parameter. A name
    // that is also a getter of a source parameter is ambiguous.
    for (final entry in renamingMapReversed.entries) {
      final targetName = entry.key;
      final sourceName = entry.value.trim();

      if (boundTargets.contains(targetName)) continue;
      if (sourceName.contains('.') || sourceName.contains(',')) continue;

      final targetGetter = targetClass.getFieldOrGetter(targetName);
      if (targetGetter == null) continue;

      final parameter = method.formalParameters
          .where((p) => p.name == sourceName)
          .firstOrNull;
      if (parameter == null) continue;

      final (_, getter) = _resolveBareSource(
        part: sourceName,
        method: method,
        target: targetName,
      );
      if (getter != null) continue; // unreachable: ambiguity throws.

      final sourceField = Field.from(
        name: parameter.name!,
        type: parameter.type,
        nullable: parameter.type.isNullable,
      );
      final targetField = Field.from(
        name: targetName,
        type: targetGetter.type,
        required: targetGetter.isRequired,
        nullable: targetGetter.type.isNullable,
      );
      bindings.add(
        _parameterBinding(
          source: sourceField,
          target: targetField,
          isIgnored: ignoredTargets.contains(targetName),
          forceNonNull: forceNonNullTargets.contains(targetName),
          callable: callableMap[targetName],
          extra: extraMethodFor(
            targetName: targetName,
            source: sourceField,
            target: targetField,
            nullableChain: false,
            description: sourceName,
          ),
          defaultValue: defaultValueMap[targetName],
        ),
      );
      boundTargets.add(targetName);
    }

    // --- Step 3: Auto-resolve fields from target getters ---
    final targetSubstituted = method.returnType.substitutedGetterTypes;
    for (final sourceMethodParam in method.formalParameters) {
      final sourceClass = sourceMethodParam.type.element?.classElementOrNull;
      final sourceSubstituted = sourceMethodParam.type.substitutedGetterTypes;

      for (final targetGetter in targetClass.getterElements) {
        if (targetGetter.name != null) {
          final targetName = targetGetter.name!;

          // Skip already-bound targets.
          if (boundTargets.contains(targetName)) continue;

          final sourceFieldName = renamingMapReversed[targetName] ?? targetName;

          // Skip dot notation sources — handled above.
          if (sourceFieldName.contains('.')) continue;

          final sourceClassParam = sourceClass?.getFieldOrGetter(
            sourceFieldName,
          );

          if (sourceClassParam != null && sourceMethodParam.name != null) {
            final sourceField = Field.from(
              name: sourceFieldName,
              type:
                  sourceSubstituted?[sourceFieldName] ?? sourceClassParam.type,
              required: sourceClassParam.isRequired,
              nullable:
                  (sourceSubstituted?[sourceFieldName] ?? sourceClassParam.type)
                      .isNullable,
              instance: Instance(name: sourceMethodParam.name!),
            );
            final targetField = Field.from(
              name: targetName,
              type: targetSubstituted?[targetName] ?? targetGetter.type,
              required: targetGetter.isRequired,
              nullable: (targetSubstituted?[targetName] ?? targetGetter.type)
                  .isNullable,
            );

            final isIgnored = ignoredTargets.contains(targetName);
            final callableMappingMethod = callableMap[targetName];
            // Ignored targets must not synthesize a nested converter: analyzing
            // it would surface binding errors for a mapping that is never emitted.
            final extraMappingMethod = extraMethodFor(
              targetName: targetName,
              source: sourceField,
              target: targetField,
              nullableChain: false,
              description: '${sourceMethodParam.name}.$sourceFieldName',
            );

            bindings.add(
              Binding(
                source: sourceField,
                target: targetField,
                ignored: isIgnored,
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

    // --- Step 4: method parameters bound to the target of the same name ---
    // The lowest precedence: an explicit @Mapping and the getters of the
    // source parameters have already bound their targets.
    for (final targetGetter in targetClass.getterElements) {
      final targetName = targetGetter.name;
      if (targetName == null || boundTargets.contains(targetName)) continue;
      if (renamingMapReversed.containsKey(targetName)) continue;

      final parameter = method.formalParameters
          .where((p) => p.name == targetName)
          .firstOrNull;
      if (parameter == null) continue;

      final sourceField = Field.from(
        name: parameter.name!,
        type: parameter.type,
        nullable: parameter.type.isNullable,
      );
      final targetField = Field.from(
        name: targetName,
        type: targetSubstituted?[targetName] ?? targetGetter.type,
        required: targetGetter.isRequired,
        nullable:
            (targetSubstituted?[targetName] ?? targetGetter.type).isNullable,
      );
      bindings.add(
        _parameterBinding(
          source: sourceField,
          target: targetField,
          isIgnored: ignoredTargets.contains(targetName),
          forceNonNull: forceNonNullTargets.contains(targetName),
          callable: callableMap[targetName],
          extra: extraMethodFor(
            targetName: targetName,
            source: sourceField,
            target: targetField,
            nullableChain: false,
            description: parameter.name!,
          ),
          defaultValue: defaultValueMap[targetName],
        ),
      );
      boundTargets.add(targetName);
    }

    return bindings;
  }

  Binding _parameterBinding({
    required Field source,
    required Field target,
    required bool isIgnored,
    required bool forceNonNull,
    required CallableMappingMethod? callable,
    required MappingMethod? extra,
    required String? defaultValue,
  }) =>
      Binding(
        source: source,
        target: target,
        ignored: isIgnored,
        forceNonNull: forceNonNull,
        callableMappingMethod: callable,
        extraMappingMethod: extra,
        defaultValue: defaultValue,
      );

  /// Resolves the bare source [part] to the source parameter that has a getter
  /// named [part], or, when there is none, to the parameter named [part].
  /// The getter is null in the second case.
  (FormalParameterElement, VariableElement?) _resolveBareSource({
    required String part,
    required MethodElement method,
    required String target,
  }) {
    final getterParams = <FormalParameterElement>[];
    VariableElement? matchedGetter;
    for (final param in method.formalParameters) {
      final getter = param.type.element?.classElementOrNull?.getterElements
          .where((g) => g.name == part)
          .firstOrNull;
      if (getter != null && param.name != null) {
        getterParams.add(param);
        matchedGetter = getter;
      }
    }
    final namedParam =
        method.formalParameters.where((p) => p.name == part).firstOrNull;

    if (getterParams.length + (namedParam == null ? 0 : 1) > 1) {
      throw AmbiguousSourceFieldError(
        fieldName: part,
        parameterNames: [
          ...getterParams.map((p) => p.name!),
          if (namedParam != null) namedParam.name!,
        ],
        targetName: target,
        element: method,
      );
    }
    if (getterParams.length == 1) return (getterParams.single, matchedGetter);
    if (namedParam != null) return (namedParam, null);
    throw InvalidCommaSeparatedSourcePartError(
      part: part,
      target: target,
      element: method,
    );
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
