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

import 'package:analyzer/dart/element/type.dart';
import 'package:dart_mapper_generator/src/analyzers/analyzer.dart';
import 'package:dart_mapper_generator/src/analyzers/contexts/analyzer_context.dart';
import 'package:dart_mapper_generator/src/analyzers/contexts/method_analyzer_context.dart';
import 'package:dart_mapper_generator/src/extensions/annotations.dart';
import 'package:dart_mapper_generator/src/extensions/dart_type.dart';
import 'package:dart_mapper_generator/src/models/annotations/resolved_mapping.dart';

class InheritConfigurationAnalyzer
    extends Analyzer<Iterable<ResolvedMapping>?> {
  final bool inverse;

  const InheritConfigurationAnalyzer({
    this.inverse = false,
  });

  @override
  Iterable<ResolvedMapping>? analyze(AnalyzerContext context) {
    if (context is! MethodAnalyzerContext) {
      throw ArgumentError('context must be a MethodAnalyzerContext');
    }

    final inheritConfiguration =
        InheritConfigurationAnnotation.loadFirst(context.method);
    final inheritInverseConfiguration =
        InheritInverseConfigurationAnnotation.loadFirst(context.method);

    if (!inverse && inheritConfiguration == null) {
      return null;
    }

    if (inverse && inheritInverseConfiguration == null) {
      return null;
    }

    final returnType = context.method.returnType;
    final parameters = context.method.formalParameters;

    if (parameters.length != 1) {
      throw ArgumentError(
        'InheritConfiguration and InheritInverseConfiguration can only be used on methods with one parameter',
      );
    }

    return _loadMappings(
      context,
      returnType: inverse ? parameters.first.type : returnType,
      parameterType: inverse ? returnType : parameters.first.type,
    );
  }

  Iterable<ResolvedMapping> _loadMappings(
    MethodAnalyzerContext context, {
    required DartType returnType,
    required DartType parameterType,
  }) =>
      context.mapperClass.methods
          .where((method) => method != context.method)
          .where((method) => method.formalParameters.length == 1)
          .where(
            (method) =>
                method.returnType.same(
                  returnType,
                  useNullability: false,
                  aliases: context.importAliases,
                ) &&
                method.formalParameters.first.type.same(
                  parameterType,
                  useNullability: false,
                  aliases: context.importAliases,
                ),
          )
          .expand((method) => MappingAnnotation.load(method, inverse: inverse));
}
