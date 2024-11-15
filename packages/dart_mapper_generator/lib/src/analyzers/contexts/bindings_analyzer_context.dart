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

import 'package:dart_mapper_generator/src/analyzers/contexts/method_analyzer_context.dart';
import 'package:dart_mapper_generator/src/extensions/annotations.dart';

class BindingsAnalyzerContext extends MethodAnalyzerContext {
  const BindingsAnalyzerContext({
    required super.mapperAnnotation,
    required super.mapperClass,
    required super.method,
  });

  Map<String, String> get renamingMap => MappingAnnotation.load(method)
      .where((annotation) => annotation.source != null)
      .toList(growable: false)
      .asMap()
      .map((_, element) => MapEntry(element.source!, element.target));

  Map<String, String> get renamingMapReversed =>
      renamingMap.map((key, value) => MapEntry(value, key));

  Set<String> get ignoredTargets => MappingAnnotation.load(method)
      .where((annotation) => annotation.ignore)
      .map((annotation) => annotation.target)
      .toSet();
}
