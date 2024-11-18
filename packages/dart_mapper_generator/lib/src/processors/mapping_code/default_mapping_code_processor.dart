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
import 'package:dart_mapper_generator/src/models/mapping_behavior.dart';
import 'package:dart_mapper_generator/src/processors/component_processor.dart';
import 'package:dart_mapper_generator/src/strategies/strategy_dispatcher.dart';
import 'package:source_gen/source_gen.dart';

class DefaultMappingCodeProcessor extends ComponentProcessor<Code> {
  final StrategyDispatcher<MappingBehavior, ExpressionFactory>
      expressionStrategyDispatcher;

  const DefaultMappingCodeProcessor({
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

    final positionalArguments = <Expression>[];
    final namedArguments = <String, Expression>{};

    for (final parameter in targetConstructor.parameters) {
      final binding = context.currentMethod.fromTarget(parameter.name);
      if (parameter.isRequired && binding == null) {
        throw InvalidGenerationSourceError(
          'No relation found for required \'${parameter.name}\' '
          'in method \'${context.mapperClass.name}.${method.name}\'.',
          element: targetClass,
        );
      }

      if (!parameter.isOptional &&
          binding?.source.nullable == true &&
          binding?.target.nullable == false) {
        throw InvalidGenerationSourceError(
          'Target field \'${parameter.name}\' '
          'in class \'${targetClass.name}\', '
          'method \'${method.name}\' in class \'${context.mapperClass.name}\', '
          'requires a non-optional source field.',
          element: targetClass,
        );
      }

      final sourceExpression = binding != null
          ? expressionStrategyDispatcher.get(method.behavior).create(
                ExpressionContext(
                  field: binding.source,
                  origin: FieldOrigin.source,
                  currentMethod: method,
                  extraMappingMethod: binding.extraMappingMethod,
                ),
              )
          : null;
      if (sourceExpression != null) {
        if (parameter.isNamed) {
          namedArguments[parameter.name] = sourceExpression;
        } else {
          positionalArguments.add(sourceExpression);
        }
      }
    }

    return Block(
      (builder) {
        if (method.optionalReturn) {
          for (final parameter in method.parameters) {
            builder.addExpression(earlyReturnIfNull(parameter.field.name));
          }
        }

        builder.addExpression(
          refer(targetConstructor.displayName)
              .newInstance(
                positionalArguments,
                namedArguments,
              )
              .returned,
        );
      },
    );
  }
}
