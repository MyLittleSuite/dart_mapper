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
import 'package:dart_mapper_generator/src/extensions/class_element.dart';
import 'package:dart_mapper_generator/src/extensions/dart_type.dart';
import 'package:dart_mapper_generator/src/extensions/element.dart';
import 'package:dart_mapper_generator/src/extensions/expression.dart';
import 'package:dart_mapper_generator/src/factories/expression_factory.dart';
import 'package:dart_mapper_generator/src/models/field/field.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/external_mapping_method.dart';

class BuiltExpressionFactory extends ExpressionFactory {
  final ExpressionFactory defaultFactory;

  const BuiltExpressionFactory({
    required this.defaultFactory,
  });

  @override
  Expression create(ExpressionContext context) {
    if (context.expressionMappingMethod == null) {
      if (context.field is IterableField) {
        final basicExpression = super.basic(context);
        final isSet = context.field.type.isSet;

        if (context.field.type.isList ||
            context.field.type.isDartCoreIterable ||
            isSet) {
          final cloneExpression = refer(
            isSet ? 'SetBuilder' : 'ListBuilder',
          ).call(
            [defaultFactory.create(context).ifNullThen(literal(isSet ? {} : []))],
          );

          return (context.field.nullable)
              ? basicExpression.isNotNull.conditional(
            cloneExpression,
            literalNull,
          )
              : cloneExpression;
        }
      } else if (context.field is NestedField &&
          context.extraMappingMethod is ExternalMappingMethod) {
        final basicExpression = super.basic(context);

        final method = context.extraMappingMethod!;
        final returnType = method.returnType;
        if (returnType?.element == null) {
          return defaultFactory.create(context);
        }

        final targetClass = returnType!.element!.classElement;
        final targetConstructor = targetClass.primaryConstructor;

        final replaceExpression = refer([
          context.resolveConstructor(targetConstructor),
          'Builder',
        ].join())
            .newInstance([])
            .cascade('replace')
            .call([
          refer(method.name).call([basicExpression.nullChecked])
        ])
            .parenthesized;

        return (context.field.nullable)
            ? basicExpression.isNotNull.conditional(
          replaceExpression,
          literalNull,
        )
            : replaceExpression;
      }
    }

    return defaultFactory.create(context);
  }
}
