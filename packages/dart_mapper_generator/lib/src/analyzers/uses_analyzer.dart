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
import 'package:dart_mapper_generator/src/extensions/dart_type.dart';
import 'package:dart_mapper_generator/src/extensions/element.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/mapping_parameter.dart';
import 'package:dart_mapper_generator/src/models/mapper_usage.dart';

class UsesAnalyzer extends Analyzer<Set<MapperUsage>> {
  @override
  Set<MapperUsage> analyze(AnalyzerContext context) {
    final uses = context.mapperAnnotation.uses ?? <DartType>{};
    final results = <MapperUsage>{};

    for (final use in uses) {
      final mapperType = use as DartType?;

      if (mapperType != null) {
        final classElement = mapperType.element?.classElementOrNull;
        final methods = classElement?.methods ?? [];

        for (final method in methods) {
          results.add(
            MapperUsage(
              mapperName: mapperType.parameterName,
              mapperType: mapperType,
              returnType: method.returnType,
              functionName: method.name,
              parameters: method.parameters
                  .map(MappingParameter.from)
                  .toList(growable: false),
            ),
          );
        }
      }
    }

    return results;
  }
}
