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
import 'package:dart_mapper_generator/src/exceptions/unknown_return_type_error.dart';
import 'package:dart_mapper_generator/src/factories/expression_factory.dart';
import 'package:dart_mapper_generator/src/misc/expressions.dart';
import 'package:dart_mapper_generator/src/models/mapping_behavior.dart';
import 'package:dart_mapper_generator/src/processors/component_processor.dart';
import 'package:dart_mapper_generator/src/strategies/strategy_dispatcher.dart';

class EnumMappingCodeProcessor extends ComponentProcessor<Code> {
  final StrategyDispatcher<MappingBehavior, ExpressionFactory>
      expressionStrategyDispatcher;

  EnumMappingCodeProcessor({
    required this.expressionStrategyDispatcher,
  });

  @override
  Code process(ProcessorContext context) {
    if (context is! ProcessorMethodContext) {
      throw ArgumentError(
        'Invalid context type. Expected ProcessorMethodContext.',
      );
    }

    final method = context.currentMethod;
    final targetEnum = method.returnType;
    if (targetEnum == null) {
      throw UnknownReturnTypeError(
        mapperClass: context.mapperClass,
        method: method,
      );
    }

    final sourceField = method.parameters.first.field;
    final expressionFactory = expressionStrategyDispatcher.get(method.behavior);

    return Block(
      (builder) {
        if (sourceField.nullable) {
          if (method.optionalReturn) {
            builder.addExpression(earlyReturnIfNull(sourceField.name));
          } else {
            builder.addExpression(throwArgumentErrorIfNull(sourceField.name));
          }
        }

        for (final binding in method.bindings) {
          final sourceValue = expressionFactory.create(
            ExpressionContext(
              field: binding.source,
              origin: FieldOrigin.source,
              counterpartField: binding.target,
              currentMethod: method,
              importAliases: context.importAliases,
            ),
          );
          final targetValue = expressionFactory.create(
            ExpressionContext(
              field: binding.target,
              origin: FieldOrigin.target,
              counterpartField: binding.source,
              currentMethod: method,
              importAliases: context.importAliases,
            ),
          );

          builder.addExpression(
            ifValueReturns(
              sourceField.name,
              sourceValue,
              targetValue,
            ),
          );
        }

        if (method.optionalReturn) {
          builder.addExpression(literalNull.returned);
        } else {
          builder.addExpression(
            throwArgumentError(
              'Unknown value for enum ${targetEnum.getDisplayString(withNullability: false)}: \${${sourceField.name}}',
            ),
          );
        }
      },
    );
  }
}
