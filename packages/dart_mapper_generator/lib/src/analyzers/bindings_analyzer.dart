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
import 'package:dart_mapper_generator/src/analyzers/contexts/bindings_analyzer_context.dart';
import 'package:dart_mapper_generator/src/analyzers/contexts/method_analyzer_context.dart';
import 'package:dart_mapper_generator/src/models/binding.dart';
import 'package:dart_mapper_generator/src/models/bindings.dart';
import 'package:dart_mapper_generator/src/models/field/field.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapper_class.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapper_constructor.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/mapping_parameter.dart';
import 'package:dart_mapper_generator/src/models/mapping_behavior.dart';
import 'package:dart_mapper_generator/src/strategies/strategy_dispatcher.dart';

class BindingsAnalyzer extends Analyzer<Bindings> {
  final Analyzer<MappingBehavior> mappingBehaviorAnalyzer;
  final StrategyDispatcher<MappingBehavior, Analyzer<List<Binding>>>
      mappingMethodDispatcher;

  BindingsAnalyzer({
    required this.mappingBehaviorAnalyzer,
    required this.mappingMethodDispatcher,
  });

  @override
  Bindings analyze(AnalyzerContext context) {
    final mappingMethods = context.mappingMethods.fold(
      <MappingMethod>[],
      (accumulator, method) {
        final mappingBehavior = mappingBehaviorAnalyzer.analyze(
          MethodAnalyzerContext(
            mapperAnnotation: context.mapperAnnotation,
            mapperClass: context.mapperClass,
            method: method,
          ),
        );

        final bindings = mappingMethodDispatcher
            .get(mappingBehavior)
            .analyze(BindingsAnalyzerContext(
              mapperAnnotation: context.mapperAnnotation,
              mapperClass: context.mapperClass,
              method: method,
            ));

        return accumulator
          ..add(MappingMethod(
            name: method.name,
            isOverride: true,
            returnType: method.returnType,
            parameters: method.parameters
                .map(
                  (param) => MappingParameter(
                    field: Field.from(
                      name: param.name,
                      type: param.type,
                    ),
                    isNullable: param.isOptional,
                  ),
                )
                .toList(growable: false),
            bindings: bindings,
            behavior: mappingBehavior,
          ));
      },
    );

    return Bindings(
      mapperClass: MapperClass(
        name: context.mapperClass.name,
        constructors: context.mapperClass.constructors
            .map((constructor) => MapperConstructor.from(constructor))
            .toList(growable: false),
        mappingMethods: mappingMethods,
      ),
    );
  }
}
