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
import 'package:dart_mapper_generator/src/models/binding.dart';
import 'package:dart_mapper_generator/src/processors/component_processor.dart';
import 'package:source_gen/source_gen.dart';

class MappingCodeProcessor extends ComponentProcessor<Code> {
  const MappingCodeProcessor();

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
    final targetVariableName = 'result';
    final targetVariableRef = refer(targetVariableName);

    final positionalArguments = <Expression>[];
    final namedArguments = <String, Expression>{};

    for (final parameter in targetConstructor.parameters) {
      final binding = context.currentMethod.fromTarget(parameter.name);
      if (binding == null) {
        throw InvalidGenerationSourceError(
          'No relation found for ${parameter.name} in method ${method.name}.',
          element: targetClass,
        );
      }

      final sourceExpression = binding.expression(BindingExpressionType.source);
      if (parameter.isNamed) {
        namedArguments[parameter.name] = sourceExpression;
      } else {
        positionalArguments.add(sourceExpression);
      }
    }

    return Block(
      (builder) {
        builder.addExpression(
          declareFinal(targetVariableName).assign(
            refer(targetConstructor.displayName).newInstance(
              positionalArguments,
              namedArguments,
            ),
          ),
        );

        builder.addExpression(targetVariableRef.returned);
      },
    );
  }
}
