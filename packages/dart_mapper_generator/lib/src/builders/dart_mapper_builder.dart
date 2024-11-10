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

import 'package:build/build.dart';
import 'package:dart_mapper_generator/src/analyzers/binding/built_bindings_analyzer.dart';
import 'package:dart_mapper_generator/src/analyzers/binding/standard_mapping_method_analyzer.dart';
import 'package:dart_mapper_generator/src/analyzers/bindings_analyzer.dart';
import 'package:dart_mapper_generator/src/analyzers/mapping_behavior_analyzer.dart';
import 'package:dart_mapper_generator/src/analyzers/mapping_method/extra_mapping_method_analyzer.dart';
import 'package:dart_mapper_generator/src/dart_mapper_generator.dart';
import 'package:dart_mapper_generator/src/models/mapping_behavior.dart';
import 'package:dart_mapper_generator/src/processors/mapper_processor.dart';
import 'package:dart_mapper_generator/src/processors/mapping_code/built_mapping_code_processor.dart';
import 'package:dart_mapper_generator/src/processors/mapping_code/default_mapping_code_processor.dart';
import 'package:dart_mapper_generator/src/processors/mapping_processor.dart';
import 'package:dart_mapper_generator/src/strategies/strategy_dispatcher.dart';
import 'package:source_gen/source_gen.dart';

Builder dartMapperBuilder([BuilderOptions options = BuilderOptions.empty]) =>
    SharedPartBuilder(
      [
        DartMapperGenerator(
          mapperProcessor: MapperProcessor(
            methodProcessor: MappingProcessor(
              methodCodeDispatcher: StrategyDispatcher({
                MappingBehavior.built: BuiltMappingCodeProcessor(),
                MappingBehavior.standard: DefaultMappingCodeProcessor(),
              }),
            ),
          ),
          analyzer: BindingsAnalyzer(
            mappingBehaviorAnalyzer: MappingBehaviorAnalyzer(),
            mappingMethodDispatcher: StrategyDispatcher({
              MappingBehavior.built: BuiltBindingsAnalyzer(
                extraMappingMethodAnalyzer: ExtraMappingMethodAnalyzer(
                  mappingBehaviorAnalyzer: MappingBehaviorAnalyzer(),
                ),
              ),
              MappingBehavior.standard: StandardBindingsAnalyzer(
                extraMappingMethodAnalyzer: ExtraMappingMethodAnalyzer(
                  mappingBehaviorAnalyzer: MappingBehaviorAnalyzer(),
                ),
              ),
            }),
          ),
        ),
      ],
      'dart_mapper',
    );
