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
import 'package:dart_mapper_generator/src/models/field/field.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/mapping_method.dart';

class DefaultExpressionFactory extends ExpressionFactory {
  @override
  Expression create(ExpressionContext context) {
    final basicExpression = super.basic(context);

    if (context.field is MapField) {
      return _createMap(context, context.field as MapField);
    } else if (context.field is IterableField) {
      return _createIterable(context, context.field as IterableField);
    } else if ((context.field is NestedField ||
            context.field is EnumField ||
            context.field is PrimitiveField) &&
        context.extraMappingMethod != null) {
      return _mapFieldWithMethod(context, context.extraMappingMethod!);
    }

    return basicExpression;
  }

  Expression _createMap(
    ExpressionContext context,
    MapField field,
  ) {
    return super.basic(context).property('map').call([
      CodeExpression(
        Code(
          context.extraMappingMethod?.name ??
              '(key, value) => MapEntry(key, value)',
        ),
      ),
    ]);
  }

  Expression _createIterable(ExpressionContext context, IterableField field) {
    final basicExpression = super.basic(context);
    final mapProperty = field.nullable
        ? basicExpression.nullSafeProperty('map')
        : basicExpression.property('map');

    final cloneExpression = mapProperty.call([
      Method(
        (b) {
          final itemName = 'item';
          final itemRefer = refer(itemName);

          b.requiredParameters.add(
            Parameter(
              (b) => b..name = itemName,
            ),
          );
          b.body = context.extraMappingMethod != null
              ? refer(context.extraMappingMethod!.name).call([itemRefer]).code
              : itemRefer.code;
        },
      ).closure,
    ]);

    if (field.type.isList) {
      return cloneExpression.propertyToList();
    } else if (field.type.isSet) {
      return cloneExpression.propertyToSet();
    } else if (field.type.isDartCoreIterable) {
      return cloneExpression;
    }

    return basicExpression;
  }

  Expression _mapFieldWithMethod(
    ExpressionContext context,
    MappingMethod extraMethod,
  ) {
    final basicExpression = super.basic(context);

    if (context.field.nullable) {
      // source != null ? {extraMappingMethod.name}(source) : null
      return basicExpression.conditionalNull(
        refer(extraMethod.name).call([basicExpression.nullChecked]),
      );
    }

    // {extraMappingMethod.name}(source)
    return refer(extraMethod.name).call([basicExpression]);
  }
}
