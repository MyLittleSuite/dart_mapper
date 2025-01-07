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
import 'package:dart_mapper_generator/src/models/mapper/mapping/mapping_parameter.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/bases/bindable_mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapping_behavior.dart';
import 'package:dart_mapper_generator/src/processors/component_processor.dart';
import 'package:dart_mapper_generator/src/strategies/strategy_dispatcher.dart';

class MappingProcessor extends ComponentProcessor<Method> {
  final StrategyDispatcher<MappingBehavior, ComponentProcessor<Code>>
      methodCodeDispatcher;

  const MappingProcessor({
    required this.methodCodeDispatcher,
  });

  @override
  Method process(ProcessorContext context) {
    if (context is! ProcessorMethodContext) {
      throw ArgumentError(
        'Invalid context type. Expected ProcessorMethodContext.',
      );
    }

    final method = context.currentMethod;
    final requiredParameters = method.parameters.where((p) => !p.isNullable);
    final optionalParameters = method.parameters.where((p) => p.isNullable);

    return Method(
      (builder) {
        if (method.isOverride) {
          builder.annotations.add(refer('override'));
        }

        builder
          ..name = method.name
          ..requiredParameters.addAll(
            _processParameters(context, requiredParameters),
          )
          ..optionalParameters.addAll(
            _processParameters(context, optionalParameters),
          )
          ..returns = _processReturns(context, method)
          ..body = methodCodeDispatcher.get(method.behavior).process(context);
      },
    );
  }

  Iterable<Parameter> _processParameters(
    ProcessorMethodContext context,
    Iterable<MappingParameter> parameters,
  ) =>
      parameters.map(
        (p) => Parameter(
          (b) => b
            ..name = p.field.name
            ..type = refer(context.resolveType(
              p.field.type,
              withNullability: p.field.nullable,
            )),
        ),
      );

  Reference _processReturns(
    ProcessorMethodContext context,
    BindableMappingMethod method,
  ) {
    final returnType = method.returnType;
    if (returnType == null) {
      return refer('void');
    }

    if (!method.isOverride && method.behavior == MappingBehavior.built) {
      return refer(returnType.builtBuilderClass);
    }

    return refer(context.resolveType(
      returnType,
      withNullability: method.optionalReturn,
    ));
  }
}
