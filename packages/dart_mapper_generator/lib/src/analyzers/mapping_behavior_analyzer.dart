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
import 'package:dart_mapper_generator/src/analyzers/contexts/field_analyzer_context.dart';
import 'package:dart_mapper_generator/src/analyzers/contexts/method_analyzer_context.dart';
import 'package:dart_mapper_generator/src/exceptions/map_to_map_mapping_not_supported_error.dart';
import 'package:dart_mapper_generator/src/extensions/dart_type.dart';
import 'package:dart_mapper_generator/src/extensions/element.dart';
import 'package:dart_mapper_generator/src/models/mapping_behavior.dart';

class MappingBehaviorAnalyzer extends Analyzer<MappingBehavior> {
  @override
  MappingBehavior analyze(AnalyzerContext context) {
    final sourceParams = switch (context) {
      MethodAnalyzerContext() => context.method.formalParameters,
      _ => null,
    };
    final targetType = switch (context) {
      FieldAnalyzerContext() => context.field.type,
      MethodAnalyzerContext() => context.method.returnType,
      _ => throw ArgumentError(
          'MappingBehaviorAnalyzer context is not handled.',
        ),
    };

    if (context is MethodAnalyzerContext && targetType.isDartCoreMap) {
      final parameters = context.method.formalParameters;

      // A Map is never converted to a Map, whatever its key type.
      if (parameters.any((param) => param.type.isDartCoreMap) ||
          (targetType.isStringKeyedMap &&
              parameters.any((param) => param.type.isMap))) {
        throw MapToMapMappingNotSupportedError(method: context.method);
      }

      // class -> Map: the method returns a Map<String, ...>.
      if (targetType.isStringKeyedMap) {
        return MappingBehavior.toMap;
      }
    }

    if (_isMapToClass(sourceParams, targetType)) {
      return MappingBehavior.fromMap;
    }

    if (targetType.isEnum ||
        sourceParams?.where((param) => param.type.isEnum).isNotEmpty == true) {
      return MappingBehavior.enums;
    }

    final targetInterface = targetType.element?.interfaceElementOrNull;
    final foundSupertype = (targetInterface?.allSupertypes ?? [])
        .where((type) => type.isLibraryBuilt)
        .firstOrNull;

    return foundSupertype != null
        ? MappingBehavior.built
        : MappingBehavior.standard;
  }

  /// A Map -> class mapping: at least one source parameter is a map accepted
  /// by [DartTypeExtension.isMapLikeSource] and the target is a plain class.
  static bool _isMapToClass(
    List<FormalParameterElement>? sourceParams,
    DartType targetType,
  ) =>
      sourceParams?.any((param) => param.type.isMapLikeSource) == true &&
      targetType.element is ClassElement &&
      !targetType.isEnum &&
      !targetType.isMap &&
      !targetType.isIterable &&
      !targetType.isPrimitive;
}
