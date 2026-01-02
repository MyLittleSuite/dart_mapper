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
import 'package:dart_mapper_generator/src/extensions/element.dart';
import 'package:dart_mapper_generator/src/factories/expression_factory.dart';
import 'package:dart_mapper_generator/src/misc/expressions.dart';
import 'package:dart_mapper_generator/src/misc/strings.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/defined_mapping_method.dart';
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
    final methodBindings = switch (method) {
      DefinedMappingMethod() => method.bindings,
      _ => [],
    };

    final targetEnum = method.returnType?.element?.interfaceElementOrNull;
    if (targetEnum == null) {
      throw UnknownReturnTypeError(
        mapperClass: context.mapperClass,
        method: method,
      );
    }

    final safeEnumDisplayName =
        targetEnum.displayName.replaceAll('\\', '\\\\').replaceAll(r'$', r'\$');
    final sourceField = method.parameters.first.field;
    final expressionFactory = expressionStrategyDispatcher.get(method.behavior);

    return Block(
      (b) => b
        ..addExpression(
          returnSwitch(
            refer(sourceField.name),
            cases: [
              if (sourceField.nullable)
                (
                  literal(null),
                  method.optionalReturn
                      ? literal(null)
                      : throwArgumentErrorNotNull(sourceField.name),
                ),
              ...methodBindings.map((binding) {
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

                return (sourceValue, targetValue);
              }),
            ],
            ignoreUnreachableCode: true,
            otherwise: method.optionalReturn
                ? literal(null)
                : throwArgumentError(
                    'Unknown value for enum $safeEnumDisplayName: {${interpolate(sourceField.name)}}',
                  ),
          ).returned,
        ),
    );
  }
}
