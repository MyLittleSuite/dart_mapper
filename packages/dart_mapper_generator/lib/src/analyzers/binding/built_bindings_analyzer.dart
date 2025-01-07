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

import 'package:dart_mapper_generator/src/analyzers/analyzer.dart';
import 'package:dart_mapper_generator/src/analyzers/contexts/analyzer_context.dart';
import 'package:dart_mapper_generator/src/analyzers/contexts/bindings_analyzer_context.dart';
import 'package:dart_mapper_generator/src/analyzers/contexts/fields_analyzer_context.dart';
import 'package:dart_mapper_generator/src/exceptions/too_many_constructor_parameters_error.dart';
import 'package:dart_mapper_generator/src/exceptions/unknown_target_class_error.dart';
import 'package:dart_mapper_generator/src/extensions/class_element.dart';
import 'package:dart_mapper_generator/src/extensions/dart_type.dart';
import 'package:dart_mapper_generator/src/extensions/element.dart';
import 'package:dart_mapper_generator/src/models/binding.dart';
import 'package:dart_mapper_generator/src/models/field/field.dart';
import 'package:dart_mapper_generator/src/models/instance.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/bases/mapping_method.dart';

class BuiltBindingsAnalyzer extends Analyzer<List<Binding>> {
  final Analyzer<MappingMethod?> extraMappingMethodAnalyzer;

  BuiltBindingsAnalyzer({
    required this.extraMappingMethodAnalyzer,
  });

  @override
  List<Binding> analyze(AnalyzerContext context) {
    if (context is! BindingsAnalyzerContext) {
      throw ArgumentError('context must be a BindingsAnalyzerContext');
    }

    final bindings = <Binding>[];

    final method = context.method;
    final renamingMap = context.renamingMapReversed;
    final ignoredTargets = context.ignoredTargets;

    final targetClass = method.returnType.element?.classElementOrNull;
    if (targetClass == null) {
      throw UnknownTargetClassError(
        mapperClass: context.mapperClass,
        method: method,
      );
    }

    final targetConstructor = targetClass.primaryConstructor;
    if (targetConstructor.parameters.length > 1) {
      throw TooManyConstructorParametersError(targetClass);
    }

    for (final sourceMethodParam in method.parameters) {
      final sourceClass = sourceMethodParam.type.element?.classElementOrNull;

      for (final targetGetter in targetClass.getters) {
        final sourceClassParamName =
            renamingMap[targetGetter.name] ?? targetGetter.name;
        final sourceClassParam = sourceClass?.getFieldOrGetter(
          sourceClassParamName,
        );

        if (sourceClassParam != null) {
          final sourceField = Field.from(
            name: sourceClassParamName,
            type: sourceClassParam.type,
            required: sourceClassParam.isRequired,
            nullable: sourceClassParam.type.isNullable,
            instance: Instance(name: sourceMethodParam.name),
          );
          final targetField = Field.from(
            name: targetGetter.name,
            type: targetGetter.type,
            required: targetGetter.isRequired,
            nullable: targetGetter.type.isNullable,
          );

          final extraMappingMethod = extraMappingMethodAnalyzer.analyze(
            FieldsAnalyzerContext(
              mapperAnnotation: context.mapperAnnotation,
              mapperUsages: context.mapperUsages,
              internalMapperUsages: context.internalMapperUsages,
              mapperClass: context.mapperClass,
              importAliases: context.importAliases,
              source: sourceField,
              target: targetField,
            ),
          );

          bindings.add(Binding(
            source: sourceField,
            target: targetField,
            ignored: ignoredTargets.contains(targetGetter.name),
            extraMappingMethod: extraMappingMethod,
          ));
        }
      }
    }

    return bindings;
  }
}
