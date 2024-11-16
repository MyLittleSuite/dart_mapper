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
import 'package:dart_mapper_generator/src/analyzers/contexts/method_analyzer_context.dart';
import 'package:dart_mapper_generator/src/extensions/dart_type.dart';
import 'package:dart_mapper_generator/src/extensions/element.dart';
import 'package:dart_mapper_generator/src/models/mapping_behavior.dart';

class MappingBehaviorAnalyzer extends Analyzer<MappingBehavior> {
  static const _builtImports = {
    'package:built_value/built_value.dart',
  };

  @override
  MappingBehavior analyze(AnalyzerContext context) {
    final sourceParams = switch (context) {
      MethodAnalyzerContext() => context.method.parameters,
      _ => null,
    };
    final targetType = switch (context) {
      FieldAnalyzerContext() => context.field.type,
      MethodAnalyzerContext() => context.method.returnType,
      _ => throw ArgumentError(
          'MappingBehaviorAnalyzer context is not handled.',
        ),
    };

    if (targetType.isEnum ||
        sourceParams?.where((param) => param.type.isEnum).isNotEmpty == true) {
      return MappingBehavior.enums;
    }

    final targetInterface = targetType.element!.interfaceElementOrNull;
    final foundSupertype = (targetInterface?.allSupertypes ?? [])
        .where((type) =>
            _builtImports.contains(type.element.source.uri.toString()))
        .firstOrNull;

    return foundSupertype != null
        ? MappingBehavior.built
        : MappingBehavior.standard;
  }
}
