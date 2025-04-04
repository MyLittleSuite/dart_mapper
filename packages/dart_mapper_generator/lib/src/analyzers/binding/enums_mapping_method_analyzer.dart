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
import 'package:dart_mapper_generator/src/exceptions/too_many_enum_mapping_method_parameters_error.dart';
import 'package:dart_mapper_generator/src/exceptions/unknown_source_class_error.dart';
import 'package:dart_mapper_generator/src/exceptions/unknown_target_class_error.dart';
import 'package:dart_mapper_generator/src/extensions/dart_type.dart';
import 'package:dart_mapper_generator/src/extensions/element.dart';
import 'package:dart_mapper_generator/src/extensions/interface_element.dart';
import 'package:dart_mapper_generator/src/models/binding.dart';
import 'package:dart_mapper_generator/src/models/field/field.dart';
import 'package:dart_mapper_generator/src/models/instance.dart';

class EnumsMappingMethodAnalyzer extends Analyzer<List<Binding>> {
  @override
  List<Binding> analyze(AnalyzerContext context) {
    if (context is! BindingsAnalyzerContext) {
      throw ArgumentError('context must be a BindingsAnalyzerContext');
    }

    if (context.method.parameters.length != 1) {
      throw TooManyEnumMappingMethodParametersError(
        mapperClass: context.mapperClass,
        method: context.method,
      );
    }

    final sourceType = context.method.parameters.first.type;
    final targetType = context.method.returnType;

    if (targetType.isEnum && sourceType.isEnum) {
      return _bindTwoEnums(context);
    } else if (targetType.isEnum) {
      return _transformToEnum(context);
    } else if (sourceType.isEnum) {
      return _transformToRaw(context);
    }

    throw UnsupportedError(
      'Unknown enum mapping method between target: $targetType and source: $sourceType',
    );
  }

  List<Binding> _bindTwoEnums(BindingsAnalyzerContext context) {
    final bindings = <Binding>[];
    final enumValuesMap = context.enumValuesReversed;

    final sourceType = context.method.parameters.first.type;
    final sourceElement = sourceType.element?.interfaceElementOrNull;
    if (sourceElement == null) {
      throw UnknownSourceClassError(
        mapperClass: context.mapperClass,
        method: context.method,
      );
    }

    final targetReturnType = context.method.returnType;
    final targetEnum = targetReturnType.element?.interfaceElementOrNull;
    if (targetEnum == null) {
      throw UnknownTargetClassError(
        mapperClass: context.mapperClass,
        method: context.method,
      );
    }

    for (final targetValue in targetEnum.enumValues) {
      final sourceClassParam = sourceElement.getEnumValue(
        enumValuesMap[targetValue.name] ?? targetValue.name,
      );

      if (sourceClassParam != null) {
        final sourceField = Field.from(
          name: sourceClassParam.name,
          type: sourceType,
          instance: Instance(name: sourceElement.name),
        );
        final targetField = Field.from(
          name: targetValue.name,
          type: targetReturnType,
          instance: Instance(name: targetEnum.name),
        );

        bindings.add(Binding(
          source: sourceField,
          target: targetField,
        ));
      }
    }

    return bindings;
  }

  List<Binding> _transformToEnum(BindingsAnalyzerContext context) {
    final bindings = <Binding>[];
    final enumValuesMap = context.enumValuesReversed;

    final sourceType = context.method.parameters.first.type;
    final sourceElement = sourceType.element?.classElementOrNull;
    if (sourceElement == null) {
      throw UnknownSourceClassError(
        mapperClass: context.mapperClass,
        method: context.method,
      );
    }

    final targetReturnType = context.method.returnType;
    final targetEnum = targetReturnType.element?.interfaceElementOrNull;
    if (targetEnum == null) {
      throw UnknownTargetClassError(
        mapperClass: context.mapperClass,
        method: context.method,
      );
    }

    for (final targetValue in targetEnum.enumValues) {
      final sourceClassValue = switch (enumValuesMap[targetValue.name]) {
        null => targetReturnType.isDartCoreString ? targetValue.name : null,
        String() => enumValuesMap[targetValue.name],
      };

      if (sourceClassValue != null) {
        final sourceField = Field.from(
          name: sourceClassValue.toString(),
          type: sourceType,
          instance: Instance(name: sourceElement.name),
        );
        final targetField = Field.from(
          name: targetValue.name,
          type: targetReturnType,
          instance: Instance(name: targetEnum.name),
        );

        bindings.add(Binding(
          source: sourceField,
          target: targetField,
        ));
      }
    }

    return bindings;
  }

  List<Binding> _transformToRaw(BindingsAnalyzerContext context) {
    final bindings = <Binding>[];
    final enumValuesMap = context.enumValues;

    final sourceType = context.method.parameters.first.type;
    final sourceEnum = sourceType.element?.interfaceElementOrNull;
    if (sourceEnum == null) {
      throw UnknownSourceClassError(
        mapperClass: context.mapperClass,
        method: context.method,
      );
    }

    final targetReturnType = context.method.returnType;
    final targetElement = targetReturnType.element?.classElementOrNull;
    if (targetElement == null) {
      throw UnknownTargetClassError(
        mapperClass: context.mapperClass,
        method: context.method,
      );
    }

    for (final sourceValue in sourceEnum.enumValues) {
      final targetClassValue = switch (enumValuesMap[sourceValue.name]) {
        null => targetReturnType.isDartCoreString ? sourceValue.name : null,
        String() => enumValuesMap[sourceValue.name],
      };

      if (targetClassValue != null) {
        final sourceField = Field.from(
          name: sourceValue.name,
          type: sourceType,
          instance: Instance(name: sourceEnum.name),
        );
        final targetField = Field.from(
          name: targetClassValue.toString(),
          type: targetReturnType,
          instance: Instance(name: targetElement.name),
        );

        bindings.add(Binding(
          source: sourceField,
          target: targetField,
        ));
      }
    }

    return bindings;
  }
}
