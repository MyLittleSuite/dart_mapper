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
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_mapper/dart_mapper.dart';
import 'package:dart_mapper_generator/src/analyzers/analyzer.dart';
import 'package:dart_mapper_generator/src/analyzers/contexts/analyzer_context.dart';
import 'package:dart_mapper_generator/src/exceptions/wrong_mapper_annotation_usage_error.dart';
import 'package:dart_mapper_generator/src/extensions/annotations.dart';
import 'package:dart_mapper_generator/src/models/bindings.dart';
import 'package:dart_mapper_generator/src/processors/component_processor.dart';
import 'package:dart_style/dart_style.dart';
import 'package:source_gen/source_gen.dart';

class DartMapperGenerator extends GeneratorForAnnotation<Mapper> {
  final Analyzer<Map<Uri, String>> importAliasesAnalyzer;
  final ComponentProcessor<Class> mapperProcessor;
  final Analyzer<Bindings> analyzer;

  const DartMapperGenerator({
    required this.importAliasesAnalyzer,
    required this.mapperProcessor,
    required this.analyzer,
  });

  @override
  generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw WrongMapperAnnotationUsageError(element);
    }

    final mapperAnnotation = MapperAnnotation.load(annotation);
    final importAliases = importAliasesAnalyzer.analyze(
      AnalyzerContext(
        mapperAnnotation: mapperAnnotation,
        mapperClass: element,
      ),
    );

    final analyzingContext = AnalyzerContext(
      mapperAnnotation: mapperAnnotation,
      mapperClass: element,
      importAliases: importAliases,
    );

    final bindings = analyzer.analyze(analyzingContext);

    final library = Library(
      (b) => b.body.add(
        mapperProcessor.process(
          ProcessorContext(
            mapperAnnotation: analyzingContext.mapperAnnotation,
            mapperClass: bindings.mapperClass,
            importAliases: importAliases,
          ),
        ),
      ),
    );

    final emitter = DartEmitter(useNullSafetySyntax: true);
    return DartFormatter().format(library.accept(emitter).toString());
  }
}
