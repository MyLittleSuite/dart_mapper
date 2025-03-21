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

import 'package:code_builder/code_builder.dart';
import 'package:dart_mapper_generator/src/extensions/dart_type.dart';
import 'package:dart_mapper_generator/src/extensions/expression.dart';
import 'package:dart_mapper_generator/src/factories/expression_factory.dart';

class EnumExpressionFactory extends ExpressionFactory {
  final ExpressionFactory defaultFactory;

  EnumExpressionFactory({
    required this.defaultFactory,
  });

  @override
  Expression create(ExpressionContext context) {
    if (context.field.type.isPrimitive) {
      if (context.origin == FieldOrigin.target) {
        if (context.field.type.isDartCoreInt) {
          return literal(context.field.name).stringToInt(
            nullable: context.currentMethod.optionalReturn,
          );
        } else if (context.field.type.isDartCoreDouble) {
          return literal(context.field.name).stringToDouble(
            nullable: context.currentMethod.optionalReturn,
          );
        } else if (context.field.type.isDartCoreNum) {
          return literal(context.field.name).stringToNum(
            nullable: context.currentMethod.optionalReturn,
          );
        }
      }

      final name = context.field.name;
      return literal(num.tryParse(name) ?? name);
    }

    if (context.field.type.isEnum) {
      return refer(context.resolveType(context.field.type))
          .property(context.field.name);
    }

    return defaultFactory.create(context);
  }
}
