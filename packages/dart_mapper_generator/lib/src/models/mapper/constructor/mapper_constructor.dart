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
import 'package:analyzer/dart/element/type.dart';
import 'package:dart_mapper_generator/src/models/mapper/constructor/mapper_constructor_parameter.dart';

class MapperConstructor {
  final String name;
  final List<MapperConstructorParameter> parameters;
  final bool isConst;

  const MapperConstructor._({
    required this.name,
    this.parameters = const [],
    this.isConst = false,
  });

  factory MapperConstructor.fromConstructor(ConstructorElement element) =>
      MapperConstructor._(
        name: element.name,
        parameters: element.parameters
            .map((param) => MapperConstructorParameter.fromDartType(param.type))
            .toList(growable: false),
        isConst: element.isConst,
      );

  factory MapperConstructor.fromUses(
    String name,
    Set<Object> types, {
    bool isConst = false,
  }) =>
      MapperConstructor._(
        name: name,
        parameters: types
            .whereType<DartType>()
            .map((type) => MapperConstructorParameter.fromDartType(type))
            .toList(growable: false),
        isConst: isConst,
      );

  @override
  String toString() => 'MapperConstructor{'
      'name: $name, '
      'parameters: $parameters'
      '}';
}
