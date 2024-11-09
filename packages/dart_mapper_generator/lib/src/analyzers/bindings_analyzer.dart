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

import 'package:analyzer/dart/element/type.dart';
import 'package:dart_mapper_generator/src/analyzers/analyzer.dart';
import 'package:dart_mapper_generator/src/extensions/annotations.dart';
import 'package:dart_mapper_generator/src/extensions/class_element.dart';
import 'package:dart_mapper_generator/src/extensions/dart_type.dart';
import 'package:dart_mapper_generator/src/extensions/element.dart';
import 'package:dart_mapper_generator/src/models/binding.dart';
import 'package:dart_mapper_generator/src/models/bindings.dart';
import 'package:dart_mapper_generator/src/models/field/field.dart';
import 'package:dart_mapper_generator/src/models/instance.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapper_class.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapper_constructor.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/mapping_parameter.dart';
import 'package:strings/strings.dart';

class BindingsAnalyzer extends Analyzer {
  @override
  Bindings analyze(AnalyzerContext context) {
    final mappingMethods = <MappingMethod>[];

    for (final method in context.mappingMethods) {
      final mappingAnnotations = MappingAnnotation.load(method);
      final bindings = <Binding>[];

      final renamingMap = mappingAnnotations
          .where((annotation) => annotation.source != null)
          .toList(growable: false)
          .asMap()
          .map((_, element) => MapEntry(element.source!, element.target));
      final ignoredTargets = mappingAnnotations
          .where((annotation) => annotation.ignore)
          .map((annotation) => annotation.target)
          .toSet();

      final targetClass = method.returnType.element!.classElement;
      final targetParam = targetClass.fieldElements
          .asMap()
          .map((_, value) => MapEntry(value.name, value));

      for (final sourceMethodParam in method.parameters) {
        final sourceClass = sourceMethodParam.type.element!.classElement;

        for (final sourceClassParam in sourceClass.fieldElements) {
          final targetClassParamName =
              renamingMap[sourceClassParam.name] ?? sourceClassParam.name;
          final targetParamType = targetParam[targetClassParamName]?.type;

          if (targetParamType != null) {
            final sourceField = Field.from(
              name: sourceClassParam.name,
              type: sourceClassParam.type,
              instance: Instance(name: sourceMethodParam.name),
              required: sourceMethodParam.isRequired,
            );
            final targetField = Field.from(
              name: targetClassParamName,
              type: targetParamType,
            );

            bindings.add(Binding(
              source: sourceField,
              target: targetField,
              ignored: ignoredTargets.contains(targetClassParamName),
              extraMappingMethod: _extraMappingMethod(sourceField, targetField),
            ));
          }
        }
      }

      mappingMethods.add(
        MappingMethod(
          name: method.name,
          isOverride: true,
          returnType: method.returnType,
          parameters: method.parameters
              .map((param) => MappingParameter(
                    field: Field.from(
                      name: param.name,
                      type: param.type,
                    ),
                    isOptional: param.isOptional,
                  ))
              .toList(growable: false),
          bindings: bindings,
        ),
      );
    }

    return Bindings(
      mapperClass: MapperClass(
        name: context.classElement.name,
        constructors: context.classElement.constructors
            .map((constructor) => MapperConstructor.from(constructor))
            .toList(growable: false),
        mappingMethods: mappingMethods,
      ),
    );
  }

  MappingMethod? _extraMappingMethod(Field source, Field target) {
    final sourceField = switch (source) {
      NestedField() => source,
      IterableField(:final item) when item is NestedField => item,
      MapField() => throw UnimplementedError("Map is not currently supported"),
      _ => null,
    };
    final targetField = switch (target) {
      NestedField() => target,
      IterableField(:final item) when item is NestedField => item,
      MapField() => throw UnimplementedError("Map is not currently supported"),
      _ => null,
    };

    if (targetField == null || sourceField == null) {
      return null;
    }

    final bindings = <Binding>[];
    for (final targetField in targetField.fields) {
      final field = sourceField.fields.firstWhere(
        (sourceField) => sourceField.name == targetField.name,
      );

      bindings.add(
        Binding(
          source: field,
          target: targetField,
          extraMappingMethod: _extraMappingMethod(
            field,
            targetField,
          ),
        ),
      );
    }

    return MappingMethod(
      name: _generateUniqueName(
        [sourceField],
        targetField.type,
      ),
      returnType: targetField.type,
      parameters: [
        MappingParameter(
          field: sourceField,
          isOptional: false,
        ),
      ],
      bindings: bindings,
    );
  }

  static String _generateUniqueName(
    List<Field> parameters,
    DartType? returnType,
  ) {
    return [
      '_map',
      parameters.map((param) => param.name.toCapitalised()).join('And'),
      'To',
      returnType?.humanReadable ?? 'Void',
    ].join();
  }
}
