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

import 'package:analyzer/dart/element/element.dart';
import 'package:dart_mapper_generator/src/analyzers/analyzer.dart';
import 'package:dart_mapper_generator/src/analyzers/contexts/analyzer_context.dart';
import 'package:dart_mapper_generator/src/analyzers/contexts/bindings_analyzer_context.dart';
import 'package:dart_mapper_generator/src/analyzers/contexts/fields_analyzer_context.dart';
import 'package:dart_mapper_generator/src/extensions/class_element.dart';
import 'package:dart_mapper_generator/src/extensions/dart_type.dart';
import 'package:dart_mapper_generator/src/extensions/element.dart';
import 'package:dart_mapper_generator/src/models/binding.dart';
import 'package:dart_mapper_generator/src/models/field/field.dart';
import 'package:dart_mapper_generator/src/models/instance.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/bases/mapping_method.dart';

class StandardBindingsAnalyzer extends Analyzer<List<Binding>> {
  final Analyzer<MappingMethod?> extraMappingMethodAnalyzer;

  const StandardBindingsAnalyzer({
    required this.extraMappingMethodAnalyzer,
  });

  @override
  List<Binding> analyze(AnalyzerContext context) {
    if (context is! BindingsAnalyzerContext) {
      throw ArgumentError('context must be a BindingsAnalyzerContext');
    }

    final bindings = <Binding>[];

    final method = context.method;
    final renamingMap = context.renamingMap;
    final ignoredTargets = context.ignoredTargets;
    final forceNonNullTargets = context.forceNonNullTargets;
    final callableMap = context.callableMap;

    final targetClass = method.returnType.element?.classElementOrNull;
    final targetParam = targetClass?.constructorParameters
        .asMap()
        .map((_, value) => MapEntry(value.name, value));

    for (final sourceMethodParam in method.parameters) {
      final sourceClass = sourceMethodParam.type.element?.classElementOrNull;
      final sourceGetters = sourceClass?.getters ?? <VariableElement>[];

      for (final sourceClassParam in sourceGetters) {
        final targetClassParamName =
            renamingMap[sourceClassParam.name] ?? sourceClassParam.name;
        final resolvedTargetParam = targetParam?[targetClassParamName];

        if (resolvedTargetParam != null) {
          final sourceField = Field.from(
            name: sourceClassParam.name,
            type: sourceClassParam.type,
            required: sourceClassParam.isRequired,
            nullable: sourceClassParam.type.isNullable,
            instance: Instance(name: sourceMethodParam.name),
          );
          final targetField = Field.from(
            name: targetClassParamName,
            type: resolvedTargetParam.type,
            required: resolvedTargetParam.isRequired,
            nullable: resolvedTargetParam.type.isNullable,
          );

          final callableMappingMethod = callableMap[targetClassParamName];
          final extraMappingMethod = callableMappingMethod == null
              ? extraMappingMethodAnalyzer.analyze(
                  FieldsAnalyzerContext(
                    mapperAnnotation: context.mapperAnnotation,
                    mapperUsages: context.mapperUsages,
                    internalMapperUsages: context.internalMapperUsages,
                    mapperClass: context.mapperClass,
                    importAliases: context.importAliases,
                    source: sourceField,
                    target: targetField,
                  ),
                )
              : null;

          bindings.add(Binding(
            source: sourceField,
            target: targetField,
            ignored: ignoredTargets.contains(targetClassParamName),
            forceNonNull: forceNonNullTargets.contains(targetClassParamName),
            callableMappingMethod: callableMappingMethod,
            extraMappingMethod: extraMappingMethod,
          ));
        }
      }
    }

    return bindings;
  }
}
