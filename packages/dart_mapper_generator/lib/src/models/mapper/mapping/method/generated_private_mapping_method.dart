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
import 'package:dart_mapper_generator/src/analyzers/contexts/fields_analyzer_context.dart';
import 'package:dart_mapper_generator/src/extensions/dart_type.dart';
import 'package:dart_mapper_generator/src/models/field/field.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/bases/bindable_mapping_method.dart';
import 'package:strings/strings.dart';

final class GeneratedPrivateMappingMethod extends BindableMappingMethod {
  GeneratedPrivateMappingMethod({
    required FieldsAnalyzerContext context,
    super.returnType,
    super.optionalReturn = false,
    required super.parameters,
    required super.bindings,
    required super.behavior,
  }) : super(
          name: _generateUniqueName(
            context,
            parameters.map((p) => p.field),
            optionalReturn,
            returnType,
          ),
        );

  @override
  String toString() => 'GeneratedPrivateMappingMethod{'
      'name: $name, '
      'returnType: $returnType, '
      'optionalReturn: $optionalReturn, '
      'behavior: $behavior, '
      'parameters: $parameters, '
      'bindings: $bindings'
      '}';

  static String _generateUniqueName(
    FieldsAnalyzerContext context,
    Iterable<Field> parameters,
    bool nullable,
    DartType? returnType,
  ) {
    return [
      '_map',
      parameters
          .map(
            (param) => [
              if (param.nullable) 'Nullable',
              if (context.resolvePrefix(param.type) != null)
                context.resolvePrefix(param.type)!.toCapitalised(),
              param.type.humanReadable.toCapitalised(),
            ].join(),
          )
          .join('And'),
      'To',
      if (nullable) 'Nullable',
      if (returnType != null && context.resolvePrefix(returnType) != null)
        context.resolvePrefix(returnType)!.toCapitalised(),
      returnType?.humanReadable ?? 'Void',
    ].join();
  }
}
