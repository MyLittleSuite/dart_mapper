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

import 'package:code_builder/code_builder.dart' hide Field;
import 'package:dart_mapper_generator/src/models/field/field.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/mapping_method.dart';

enum FieldOrigin {
  source,
  target,
}

class ExpressionContext {
  final Field field;
  final FieldOrigin origin;
  final MappingMethod currentMethod;
  final bool ignored;
  final MappingMethod? extraMappingMethod;

  const ExpressionContext({
    required this.field,
    required this.origin,
    required this.currentMethod,
    this.ignored = false,
    this.extraMappingMethod,
  });
}

abstract class ExpressionFactory {
  const ExpressionFactory();

  Expression create(ExpressionContext context);

  Expression basic(ExpressionContext context) {
    if (!context.field.nullable && context.ignored) {
      throw ArgumentError(
        'Field ${context.field.name} is not nullable and ignored, mapping function ${context.currentMethod.name}.',
      );
    }

    if (context.field.nullable && context.ignored) {
      return literalNull;
    }

    if (context.field.instance != null) {
      return refer(context.field.instance!.name).property(context.field.name);
    }

    return refer(context.field.name);
  }
}
