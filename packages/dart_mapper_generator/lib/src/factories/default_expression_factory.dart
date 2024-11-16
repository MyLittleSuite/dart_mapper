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
import 'package:dart_mapper_generator/src/factories/expression_factory.dart';
import 'package:dart_mapper_generator/src/models/field/field.dart';

class DefaultExpressionFactory extends ExpressionFactory {
  @override
  Expression create(ExpressionContext context) {
    final basicExpression = super.basic(context.field);

    if (context.field is MapField) {
      return basicExpression.property('map').call([
        CodeExpression(
          Code(
            context.extraMappingMethod?.name ??
                '(key, value) => MapEntry(key, value)',
          ),
        ),
      ]);
    } else if (context.field is IterableField) {
      final mapProperty = context.field.nullable
          ? basicExpression.nullSafeProperty('map')
          : basicExpression.property('map');
      final cloneExpression = mapProperty.call([
        CodeExpression(
          Code(context.extraMappingMethod?.name ?? '(item) => item'),
        ),
      ]);

      if (context.field.type.isList) {
        return cloneExpression
            .property('toList')
            .call([], {'growable': literalFalse});
      } else if (context.field.type.isSet) {
        return cloneExpression.property('toSet').call([]);
      } else if (context.field.type.isDartCoreIterable) {
        return cloneExpression;
      }
    } else if ((context.field is NestedField || context.field is EnumField) &&
        context.extraMappingMethod != null) {
      // {extraMappingMethod.name}(source)
      return CodeExpression(Code(context.extraMappingMethod!.name)).call([
        basicExpression,
      ]);
    }

    return basicExpression;
  }
}
