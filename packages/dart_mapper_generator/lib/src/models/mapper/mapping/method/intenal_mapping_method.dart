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

import 'package:dart_mapper_generator/src/models/binding.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/mapping_parameter.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapping_behavior.dart';

class InternalMappingMethod extends MappingMethod {
  final bool isOverride;
  final List<MappingParameter> parameters;
  final List<Binding> bindings;
  final MappingBehavior behavior;

  const InternalMappingMethod({
    required super.name,
    this.isOverride = false,
    super.returnType,
    super.optionalReturn = false,
    this.behavior = MappingBehavior.standard,
    this.parameters = const [],
    this.bindings = const [],
  });

  Binding? fromTarget(String target) =>
      bindings.where((b) => b.target.name == target).firstOrNull;

  @override
  String toString() => 'MappingMethod{'
      'name: $name, '
      'isOverride: $isOverride, '
      'returnType: $returnType, '
      'optionalReturn: $optionalReturn, '
      'behavior: $behavior, '
      'parameters: $parameters, '
      'bindings: $bindings'
      '}';
}
