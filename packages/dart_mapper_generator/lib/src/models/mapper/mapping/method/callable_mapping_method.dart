/*
 * Copyright (c) 2025 MyLittleSuite
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
import 'package:dart_mapper_generator/src/extensions/dart_type.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/mapping_parameter.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/bases/mapping_method.dart';

final class CallableMappingMethod extends MappingMethod {
  final MappingParameter parameter;

  CallableMappingMethod({
    required super.name,
    required super.returnType,
    required super.optionalReturn,
    required this.parameter,
  });

  factory CallableMappingMethod.from(ExecutableElement element) {
    assert(
      element.parameters.length == 1,
      'ExpressionMappingMethod can only be created from a method with one parameter',
    );

    return CallableMappingMethod(
      name: element.name,
      optionalReturn: element.returnType.isNullable,
      returnType: element.returnType,
      parameter: MappingParameter.from(element.parameters.first),
    );
  }

  @override
  String toString() => 'CallableMappingMethod{'
      'name: $name, '
      'returnType: $returnType, '
      'optionalReturn: $optionalReturn, '
      'parameter: $parameter'
      '}';
}
