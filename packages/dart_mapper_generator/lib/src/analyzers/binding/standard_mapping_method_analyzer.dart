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
import 'package:dart_mapper_generator/src/extensions/class_element.dart';
import 'package:dart_mapper_generator/src/extensions/dart_type.dart';
import 'package:dart_mapper_generator/src/extensions/element.dart';
import 'package:dart_mapper_generator/src/extensions/mapping_method.dart';
import 'package:dart_mapper_generator/src/misc/nested_targets.dart';
import 'package:dart_mapper_generator/src/models/binding.dart';
import 'package:dart_mapper_generator/src/models/field/field.dart';
import 'package:dart_mapper_generator/src/models/instance.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/bases/mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/external_mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/internal_mapping_method.dart';
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
    final qualifiedByMap = context.qualifiedByMap;
    final defaultValueMap = context.defaultValueMap;
    final constantMap = context.constantMap;
    final expressionMap = context.expressionMap;
    final conditionExpressionMap = context.conditionExpressionMap;

    final isMultiSource = method.formalParameters.length > 1;

    // Build a map of fieldName -> [parameterNames] across ALL source parameters
    // to detect ambiguous fields in multi-source methods.
    final fieldToParams = <String, List<String>>{};
    if (isMultiSource) {
      for (final param in method.formalParameters) {
        final sourceClass = param.type.element?.classElementOrNull;
        for (final getter
            in sourceClass?.getterElements ?? <VariableElement>[]) {
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

    // Constructor parameters of the target class by name, plus the ones of the
    // classes nested in it that dotted targets (`address.street`) build.
    final targetParam = resolveTargetParams(
      method.returnType,
      context.configuredTargets,
      element: method,
      library: context.mapperClass.library,
      importAliases: context.importAliases,
    );
    final nestedRoots = nestedTargetRoots(context.configuredTargets);

    // A bare `source` naming both a parameter and a getter of a parameter is
    // ambiguous.
    for (final source in renamingMapReversed.values) {
      if (source.contains(',') || source.contains('.')) continue;
      final isParameter =
          method.formalParameters.any((param) => param.name == source);
      final params = fieldToParams[source];
      if (isParameter && (params != null && params.isNotEmpty)) {
        throw AmbiguousSourceFieldError(
          fieldName: source,
          parameterNames: [...params, source],
          element: method,
        );
      }
    }

    final lookup = MethodSignatureLookup(context);

    // --- Step 0: Process comma-separated sources ---
    // Must run before Step 1 so that targets with comma+dot sources (e.g. "a.x,b.y")
    // are bound here and skipped by Step 1's dot-check. The sources are passed
    // to the callable, or to the mapper method that accepts them.
    for (final entry in renamingMapReversed.entries) {
      final targetName = entry.key;
      final sourceExpression = entry.value;

      if (!sourceExpression.contains(',')) continue;
      if (boundTargets.contains(targetName)) continue;

      final resolvedTargetParam = targetParam[targetName];
      if (resolvedTargetParam == null) continue;

      final targetField = Field.from(
        name: targetName,
        type: resolvedTargetParam.type,
        required: resolvedTargetParam.isRequired,
        nullable: resolvedTargetParam.type.isNullable,
      );

      final callableMappingMethod = callableMap[targetName];
      if (callableMappingMethod == null &&
          ignoredTargets.contains(targetName)) {
        bindings.add(
          Binding(
            source: Field.from(
              name: targetName,
              type: resolvedTargetParam.type,
              nullable: true,
            ),
            target: targetField,
            ignored: true,
          ),
        );
        boundTargets.add(targetName);
        continue;
      }

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
            // Not a getter: the name of a method parameter.
            final parameter = method.formalParameters
                .where((p) => p.name == part)
                .firstOrNull;
            if (parameter == null) {
              throw InvalidCommaSeparatedSourcePartError(
                part: part,
                target: targetName,
                element: method,
              );
            }
            resolvedSources.add(_parameterField(parameter));
            resolvedChains.add(null);
            continue;
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

      if (resolvedSources.isEmpty) continue;

      // Without a callable, the mapper method taking the sources is looked up.
      final sourcesMappingMethod = callableMappingMethod == null
          ? lookup.find(
              target: targetName,
              arguments: [
                for (var i = 0; i < resolvedSources.length; i++)
                  _argument(resolvedSources[i], resolvedChains[i]),
              ],
              targetType: resolvedTargetParam.type,
              qualifiedBy: qualifiedByMap[targetName],
            )
          : null;

      bindings.add(
        Binding(
          source:
              resolvedSources.first, // keeps existing nullability guard working
          sources: resolvedSources,
          target: targetField,
          callableMappingMethod: callableMappingMethod,
          sourcesMappingMethod: sourcesMappingMethod,
          sourceAccessChains: resolvedChains,
          defaultValue: defaultValueMap[targetName],
          conditionExpression: conditionExpressionMap[targetName],
          // The callable / method owns nullability — suppress nullability
          // throw (same as callable+dot-path today). forceNonNull not needed.
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

      final resolvedTargetParam = targetParam[targetName];
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
        _validateValueType(
            dotConstant, resolvedTargetParam.type, targetName, method);
      }
      if (dotDefault != null) {
        _validateValueType(
            dotDefault, resolvedTargetParam.type, targetName, method);
      }

      // Per D-07: if the resolved source is nullable (due to nullable intermediates)
      // and the target is non-null, and forceNonNull is not set, throw.
      final chainHasNullable = accessChain.any((e) => e.$2);
      final resolvedIsNullable = resolvedField.nullable || chainHasNullable;
      final isIgnored = ignoredTargets.contains(targetName);
      final callableMappingMethod = callableMap[targetName];
      // Ignored targets must not synthesize a nested converter: analyzing
      // it would surface binding errors for a mapping that is never emitted.
      final (extraMappingMethod, sourcesMappingMethod) =
          callableMappingMethod == null && !isIgnored
              ? _converter(
                  context: context,
                  lookup: lookup,
                  source: resolvedField,
                  chain: accessChain,
                  target: targetField,
                )
              : (null, null);
      if (resolvedIsNullable &&
          !targetField.nullable &&
          !forceNonNullTargets.contains(targetName) &&
          defaultValueMap[targetName] == null &&
          callableMappingMethod == null &&
          sourcesMappingMethod == null) {
        throw InvalidGenerationSourceError(
          "Target field '$targetName' is non-nullable but the dot notation source "
          "'$sourceExpression' may be null (nullable intermediate in chain).\n"
          "Fix: Add forceNonNull: true or provide a defaultValue to handle the null case.",
          element: method,
        );
      }

      bindings.add(
        Binding(
          source: resolvedField,
          target: targetField,
          ignored: isIgnored,
          forceNonNull: forceNonNullTargets.contains(targetName),
          callableMappingMethod: callableMappingMethod,
          extraMappingMethod: extraMappingMethod,
          sourcesMappingMethod: sourcesMappingMethod,
          sources: sourcesMappingMethod == null ? null : [resolvedField],
          sourceAccessChains:
              sourcesMappingMethod == null ? null : [accessChain],
          defaultValue: defaultValueMap[targetName],
          accessChain: accessChain,
          conditionExpression: conditionExpressionMap[targetName],
        ),
      );
      boundTargets.add(targetName);
    }

    // --- Step 2: Process constant-only mappings (no source reference) ---
    for (final entry in constantMap.entries) {
      final targetName = entry.key;
      final constantValue = entry.value;

      if (boundTargets.contains(targetName)) continue;

      final resolvedTargetParam = targetParam[targetName];
      if (resolvedTargetParam == null) continue;

      // Create a placeholder source field — expression factory ignores it when constant != null.
      final targetField = Field.from(
        name: targetName,
        type: resolvedTargetParam.type,
        required: resolvedTargetParam.isRequired,
        nullable: resolvedTargetParam.type.isNullable,
      );

      // Validate constant type compatibility.
      _validateValueType(
          constantValue, resolvedTargetParam.type, targetName, method);

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

    // --- Step 2.5: Process expression-only mappings (no source reference) ---
    for (final entry in expressionMap.entries) {
      final targetName = entry.key;
      final expressionValue = entry.value;

      if (boundTargets.contains(targetName)) continue;

      final resolvedTargetParam = targetParam[targetName];
      if (resolvedTargetParam == null) continue;

      final targetField = Field.from(
        name: targetName,
        type: resolvedTargetParam.type,
        required: resolvedTargetParam.isRequired,
        nullable: resolvedTargetParam.type.isNullable,
      );

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
          expression: expressionValue,
        ),
      );
      boundTargets.add(targetName);
    }

    // Nested objects are built from their dotted targets only, never from a
    // source field named like them.
    boundTargets.addAll(nestedRoots);

    // A dotted target without a source reads the source property named like
    // its last segment (`address.zip` reads `zip`), as a flat target does.
    final implicitNestedSources = <String, List<String>>{};
    for (final target in context.configuredTargets) {
      if (target.contains('.') &&
          !renamingMapReversed.containsKey(target) &&
          !constantMap.containsKey(target) &&
          !expressionMap.containsKey(target)) {
        implicitNestedSources
            .putIfAbsent(target.split('.').last, () => [])
            .add(target);
      }
    }

    // --- Step 3: Auto-resolve fields from source parameters ---
    final targetSubstituted = method.returnType.substitutedGetterTypes;
    for (final sourceMethodParam in method.formalParameters) {
      final sourceClass = sourceMethodParam.type.element?.classElementOrNull;
      final sourceGetters = sourceClass?.getterElements ?? <VariableElement>[];
      final sourceSubstituted = sourceMethodParam.type.substitutedGetterTypes;

      for (final sourceClassParam in sourceGetters) {
        if (sourceClassParam.name != null) {
          final targetNames = [
            ...renamingMap[sourceClassParam.name!] ?? [sourceClassParam.name!],
            ...?implicitNestedSources[sourceClassParam.name!],
          ];

          for (final targetClassParamName in targetNames) {
            // Skip already-bound targets (dot notation, constant, etc.)
            if (boundTargets.contains(targetClassParamName)) continue;

            final resolvedTargetParam = targetParam[targetClassParamName];
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
              type: sourceSubstituted?[sourceClassParam.name!] ??
                  sourceClassParam.type,
              required: sourceClassParam.isRequired,
              nullable: (sourceSubstituted?[sourceClassParam.name!] ??
                      sourceClassParam.type)
                  .isNullable,
              instance: Instance(name: sourceMethodParam.name!),
            );
            final targetField = Field.from(
              name: targetClassParamName,
              type: targetSubstituted?[targetClassParamName] ??
                  resolvedTargetParam.type,
              required: resolvedTargetParam.isRequired,
              nullable: (targetSubstituted?[targetClassParamName] ??
                      resolvedTargetParam.type)
                  .isNullable,
            );

            final isIgnored = ignoredTargets.contains(targetClassParamName);
            final callableMappingMethod = callableMap[targetClassParamName];
            // Ignored targets must not synthesize a nested converter: analyzing
            // it would surface binding errors for a mapping that is never emitted.
            final (extraMappingMethod, sourcesMappingMethod) =
                callableMappingMethod == null && !isIgnored
                    ? _converter(
                        context: context,
                        lookup: lookup,
                        source: sourceField,
                        target: targetField,
                      )
                    : (null, null);

            bindings.add(
              Binding(
                source: sourceField,
                target: targetField,
                ignored: isIgnored,
                forceNonNull:
                    forceNonNullTargets.contains(targetClassParamName),
                callableMappingMethod: callableMappingMethod,
                extraMappingMethod: extraMappingMethod,
                sourcesMappingMethod: sourcesMappingMethod,
                sources: sourcesMappingMethod == null ? null : [sourceField],
                sourceAccessChains:
                    sourcesMappingMethod == null ? null : [null],
                defaultValue: defaultValueMap[targetClassParamName],
                conditionExpression:
                    conditionExpressionMap[targetClassParamName],
              ),
            );
            boundTargets.add(targetClassParamName);
          }
        }
      }
    }

    // --- Step 4: Bind the method parameters to the targets named like them ---
    // Last in the precedence: explicit @Mapping > getter of a source
    // parameter > parameter name.
    for (final parameter in method.formalParameters) {
      final parameterName = parameter.name;
      if (parameterName == null) continue;

      final targetNames = [
        ...renamingMap[parameterName] ?? [parameterName],
        ...?implicitNestedSources[parameterName],
      ];

      for (final targetName in targetNames) {
        if (boundTargets.contains(targetName)) continue;
        if (ignoredTargets.contains(targetName)) continue;

        final resolvedTargetParam = targetParam[targetName];
        if (resolvedTargetParam == null) continue;

        final sourceField = _parameterField(parameter);
        final targetField = Field.from(
          name: targetName,
          type: targetSubstituted?[targetName] ?? resolvedTargetParam.type,
          required: resolvedTargetParam.isRequired,
          nullable: (targetSubstituted?[targetName] ?? resolvedTargetParam.type)
              .isNullable,
        );

        final callableMappingMethod = callableMap[targetName];
        final (extraMappingMethod, sourcesMappingMethod) =
            callableMappingMethod == null
                ? _converter(
                    context: context,
                    lookup: lookup,
                    source: sourceField,
                    target: targetField,
                    acceptNullableParameter: true,
                  )
                : (null, null);

        bindings.add(
          Binding(
            source: sourceField,
            target: targetField,
            forceNonNull: forceNonNullTargets.contains(targetName),
            callableMappingMethod: callableMappingMethod,
            extraMappingMethod: extraMappingMethod,
            sourcesMappingMethod: sourcesMappingMethod,
            sources: sourcesMappingMethod == null ? null : [sourceField],
            sourceAccessChains: sourcesMappingMethod == null ? null : [null],
            defaultValue: defaultValueMap[targetName],
            conditionExpression: conditionExpressionMap[targetName],
          ),
        );
        boundTargets.add(targetName);
      }
    }

    if (nestedRoots.isEmpty) {
      return bindings;
    }

    // An ignored nested property that no source property feeds still gets a
    // binding when it can be left out (optional) or set to null (nullable).
    for (final target in ignoredTargets) {
      final param = targetParam[target];
      if (!target.contains('.') ||
          param == null ||
          boundTargets.contains(target) ||
          (param.isRequired && !param.type.isNullable)) {
        continue;
      }

      bindings.add(
        Binding(
          source: Field.from(
            name: target.split('.').last,
            type: param.type,
            nullable: true,
          ),
          target: Field.from(
            name: target,
            type: param.type,
            required: param.isRequired,
            nullable: param.type.isNullable,
          ),
          ignored: true,
        ),
      );
      boundTargets.add(target);
    }

    return groupNestedBindings(
      bindings,
      configuredTargets: context.configuredTargets,
      parentField: (path) {
        final param = targetParam[path]!;

        return Field.from(
          name: path,
          type: param.type,
          required: param.isRequired,
          nullable: param.type.isNullable,
        );
      },
    );
  }

  /// The [Field] of a method parameter used as a source: it is read by its
  /// name, not through a getter.
  Field _parameterField(FormalParameterElement parameter) => Field.from(
        name: parameter.name!,
        type: parameter.type,
        required: parameter.isRequired,
        nullable: parameter.type.isNullable,
      );

  SourceArgument _argument(Field source, List<(String, bool)>? chain) {
    final instance = source.instance?.name ?? '';
    final path = chain != null && chain.isNotEmpty
        ? chain.fold(
            instance,
            (path, link) => path.isEmpty
                ? link.$1
                : '$path${link.$2 ? '?.' : '.'}${link.$1}',
          )
        : (instance.isEmpty ? source.name : '$instance.${source.name}');

    return SourceArgument(
      type: source.type,
      description: path,
      nullableChain: chain?.any((e) => e.$2) ?? false,
    );
  }

  /// The converter of [source] into [target]: `(extraMappingMethod,
  /// sourcesMappingMethod)`.
  ///
  /// Without `qualifiedBy` it is the converter found by the extra mapping
  /// method analyzer. With it, the method it names (signature checked). A
  /// nullable [source] is null-checked before the call, unless the converter
  /// accepts null (and, for a [acceptNullableParameter] source, is found
  /// automatically): then it is called with the source as is, as a
  /// multi-source method is.
  (MappingMethod?, MappingMethod?) _converter({
    required BindingsAnalyzerContext context,
    required MethodSignatureLookup lookup,
    required Field source,
    required Field target,
    List<(String, bool)>? chain,
    bool acceptNullableParameter = false,
  }) {
    final qualifiedBy = context.qualifiedByMap[target.name];
    final sourceIsNullable =
        source.nullable || (chain?.any((e) => e.$2) ?? false);

    MappingMethod? method;
    if (qualifiedBy != null) {
      final typeSystem = context.mapperClass.library.typeSystem;
      method = lookup.find(
        target: target.name,
        arguments: [
          SourceArgument(
            // The call is null-checked when the parameter is not nullable.
            type: typeSystem.promoteToNonNull(source.type),
            description: _argument(source, chain).description,
          ),
        ],
        targetType: target.type,
        qualifiedBy: qualifiedBy,
      );
    } else {
      method = extraMappingMethodAnalyzer.analyze(
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

    final callsNullSafely = method != null &&
        sourceIsNullable &&
        (qualifiedBy != null || acceptNullableParameter) &&
        (method is ExternalMappingMethod || method is InternalMappingMethod) &&
        method.parameterTypeAt(0)?.isNullable == true;

    return callsNullSafely ? (null, method) : (method, null);
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
      // Resolve the type of the field against the type arguments of the
      // receiver (`T value` of `Box<Address>` is `Address`).
      currentType = currentType.substitutedGetterTypes?[segment] ?? field.type;
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
    final baseType =
        type.isDartCoreNull ? null : targetType.replaceAll('?', '');

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
