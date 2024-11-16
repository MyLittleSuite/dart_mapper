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
import 'package:dart_mapper_generator/src/extensions/element.dart';
import 'package:dart_mapper_generator/src/factories/expression_factory.dart';
import 'package:dart_mapper_generator/src/misc/expressions.dart';
import 'package:dart_mapper_generator/src/models/binding.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapping_behavior.dart';
import 'package:dart_mapper_generator/src/processors/component_processor.dart';
import 'package:dart_mapper_generator/src/strategies/strategy_dispatcher.dart';

class BuiltMappingCodeProcessor extends ComponentProcessor<Code> {
  final StrategyDispatcher<MappingBehavior, ExpressionFactory>
      expressionStrategyDispatcher;

  const BuiltMappingCodeProcessor({
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
    final targetClass = method.returnType!.element!.classElement;
    final targetConstructor = targetClass.primaryConstructor;

    return Block(
      (builder) {
        if (method.optionalReturn) {
          for (final parameter in method.parameters) {
            builder.addExpression(earlyReturnIfNull(parameter.field.name));
          }
        }

        Expression targetInstance;

        if (method.isOverride) {
          targetInstance = refer(targetConstructor.displayName).newInstance([
            builderClosure(
              method.bindings
                  .map(
                    (b) => (
                      b.target.name,
                      _buildExpression(method, b),
                    ),
                  )
                  .toList(growable: false),
            ),
          ]);
        } else {
          targetInstance = refer('${targetConstructor.displayName}Builder')
              .newInstance([])
              .cascade('replace')
              .call([
                refer(targetConstructor.displayName).newInstance([
                  builderClosure(
                    method.bindings
                        .map(
                          (b) => (
                            b.target.name,
                            _buildExpression(method, b),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ])
              ]);
        }

        builder.addExpression(targetInstance.returned);
      },
    );
  }

  Expression _buildExpression(MappingMethod method, Binding binding) =>
      expressionStrategyDispatcher.get(method.behavior).create(
            ExpressionContext(
              field: binding.source,
              extraMappingMethod: binding.extraMappingMethod,
            ),
          );
}
