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
import 'package:dart_mapper_generator/src/models/mapper/mapping/mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/mapping_parameter.dart';
import 'package:dart_mapper_generator/src/processors/component_processor.dart';

class MappingProcessor extends ComponentProcessor<Method> {
  final ComponentProcessor<Code> methodCodeProcessor;

  const MappingProcessor({
    required this.methodCodeProcessor,
  });

  @override
  Method process(ProcessorContext context) {
    if (context is! ProcessorMethodContext) {
      throw ArgumentError(
        'Invalid context type. Expected ProcessorMethodContext.',
      );
    }

    final method = context.currentMethod;
    final requiredParameters = method.parameters.where((p) => !p.isOptional);
    final optionalParameters = method.parameters.where((p) => p.isOptional);

    return Method(
      (builder) {
        if (method.isOverride) {
          builder.annotations.add(refer('override'));
        }

        builder
          ..name = method.name
          ..requiredParameters.addAll(_processParameters(requiredParameters))
          ..optionalParameters.addAll(_processParameters(optionalParameters))
          ..returns = _processReturns(method)
          ..body = methodCodeProcessor.process(context);
      },
    );
  }

  Iterable<Parameter> _processParameters(
    Iterable<MappingParameter> parameters,
  ) =>
      parameters.map(
        (p) => Parameter(
          (b) => b
            ..name = p.field.name
            ..type = refer(p.field.type.element!.name!),
        ),
      );

  Reference _processReturns(MappingMethod method) =>
      refer(method.returnType!.element!.name!);
}
