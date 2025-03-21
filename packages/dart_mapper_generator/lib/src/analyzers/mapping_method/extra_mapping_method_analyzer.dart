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

import 'package:dart_mapper_generator/src/analyzers/analyzer.dart';
import 'package:dart_mapper_generator/src/analyzers/contexts/analyzer_context.dart';
import 'package:dart_mapper_generator/src/analyzers/contexts/field_analyzer_context.dart';
import 'package:dart_mapper_generator/src/analyzers/contexts/fields_analyzer_context.dart';
import 'package:dart_mapper_generator/src/models/binding.dart';
import 'package:dart_mapper_generator/src/models/field/field.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/mapping_parameter.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/external_mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/generated_private_mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/internal_mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/bases/mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper_usage.dart';
import 'package:dart_mapper_generator/src/models/mapping_behavior.dart';

class ExtraMappingMethodAnalyzer extends Analyzer<MappingMethod?> {
  final Analyzer<MappingBehavior> mappingBehaviorAnalyzer;

  const ExtraMappingMethodAnalyzer({
    required this.mappingBehaviorAnalyzer,
  });

  @override
  MappingMethod? analyze(AnalyzerContext context) {
    if (context is! FieldsAnalyzerContext) {
      throw ArgumentError('context must be a FieldsAnalyzerContext');
    }

    final source = context.source;
    final target = context.target;

    final sourceField = _extractGeneric(source);
    final targetField = _extractGeneric(target);

    final sourceFields = _getNestedFields(sourceField);
    final targetFields = _getNestedFields(targetField);

    final mapperUsage = _findCorrectMethodUsage(
      context: context,
      source: source,
      target: target,
      internally: false,
      sourceField: sourceField,
      targetField: targetField,
      sourceFields: sourceFields,
      targetFields: targetFields,
    );
    if (mapperUsage != null) {
      return ExternalMappingMethod(mapperUsage: mapperUsage);
    }

    final internalMapperUsage = _findCorrectMethodUsage(
      context: context,
      source: source,
      target: target,
      internally: true,
      sourceField: sourceField,
      targetField: targetField,
      sourceFields: sourceFields,
      targetFields: targetFields,
    );
    if (internalMapperUsage != null) {
      return InternalMappingMethod(mapperUsage: internalMapperUsage);
    }

    if (targetField == null || sourceField == null) {
      return null;
    }

    final bindings = <Binding>[];
    for (final targetField in targetFields) {
      final field = sourceFields
          .where((sourceField) => sourceField.name == targetField.name)
          .firstOrNull;

      if (field != null) {
        final extraMappingMethod = analyze(
          FieldsAnalyzerContext(
            mapperAnnotation: context.mapperAnnotation,
            mapperUsages: context.mapperUsages,
            internalMapperUsages: context.internalMapperUsages,
            mapperClass: context.mapperClass,
            importAliases: context.importAliases,
            source: field,
            target: targetField,
          ),
        );

        bindings.add(
          Binding(
            source: field,
            target: targetField,
            extraMappingMethod: extraMappingMethod,
          ),
        );
      }
    }

    final behavior = mappingBehaviorAnalyzer.analyze(
      FieldAnalyzerContext(
        mapperAnnotation: context.mapperAnnotation,
        mapperUsages: context.mapperUsages,
        internalMapperUsages: context.internalMapperUsages,
        mapperClass: context.mapperClass,
        importAliases: context.importAliases,
        field: targetField,
      ),
    );

    return GeneratedPrivateMappingMethod(
      context: context,
      returnType: targetField.type,
      parameters: [
        MappingParameter(
          field: sourceField,
          isNullable: sourceField.nullable,
        ),
      ],
      optionalReturn: targetField.nullable,
      bindings: bindings,
      behavior: behavior,
    );
  }

  static MapperUsage? _findCorrectMethodUsage({
    required AnalyzerContext context,
    required Field source,
    required Field target,
    required bool internally,
    Field? sourceField,
    Field? targetField,
    List<Field>? sourceFields,
    List<Field>? targetFields,
  }) {
    var mapperUsage = context.findUsage(
      target.type,
      [source.type],
      internally: internally,
      useNullabilityForParams: false,
      useNullabilityForReturn: false,
    );
    if (mapperUsage != null) {
      return mapperUsage;
    }

    mapperUsage = sourceField != null
        ? context.findUsage(
            target.type,
            [sourceField.type],
            internally: internally,
            useNullabilityForReturn: false,
          )
        : null;
    if (mapperUsage != null) {
      return mapperUsage;
    }

    mapperUsage = sourceFields != null
        ? context.findUsage(
            target.type,
            sourceFields.map((field) => field.type).toList(growable: false),
            internally: internally,
            useNullabilityForReturn: false,
          )
        : null;
    if (mapperUsage != null) {
      return mapperUsage;
    }

    mapperUsage = targetField != null
        ? context.findUsage(
            targetField.type,
            [source.type],
            internally: internally,
            useNullabilityForParams: false,
          )
        : null;
    if (mapperUsage != null) {
      return mapperUsage;
    }

    mapperUsage = targetField != null && sourceField != null
        ? context.findUsage(
            targetField.type,
            [sourceField.type],
            internally: internally,
          )
        : null;
    if (mapperUsage != null) {
      return mapperUsage;
    }

    mapperUsage = targetField != null && sourceFields != null
        ? context.findUsage(
            targetField.type,
            sourceFields.map((field) => field.type).toList(growable: false),
            internally: internally,
          )
        : null;
    if (mapperUsage != null) {
      return mapperUsage;
    }

    return null;
  }

  static Field? _extractGeneric(Field? field) => switch (field) {
        NestedField() => field,
        EnumField() => field,
        IterableField(:final item) when item is NestedField => item,
        IterableField(:final item) when item is EnumField => item,
        MapField() =>
          throw UnimplementedError("Map is not currently supported"),
        _ => null,
      };

  static List<Field> _getNestedFields(Field? field) => switch (field) {
        NestedField(:final fields) => fields,
        EnumField(:final values) => values,
        _ => [],
      };
}
