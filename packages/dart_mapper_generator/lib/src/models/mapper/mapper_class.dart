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

import 'package:dart_mapper_generator/src/models/mapper/constructor/mapper_constructor.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapper_instance_field.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/intenal_mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/mapping_method.dart';

class MapperClass {
  final String name;
  final List<MapperInstanceField> instanceFields;
  final List<MapperConstructor> constructors;
  final List<MappingMethod> _mappingMethods;

  const MapperClass({
    required this.name,
    this.instanceFields = const [],
    this.constructors = const [],
    List<MappingMethod> mappingMethods = const [],
  }) : _mappingMethods = mappingMethods;

  Iterable<MappingMethod> get mappingMethods sync* {
    final internalMappingMethods =
        _mappingMethods.whereType<InternalMappingMethod>();

    yield* internalMappingMethods;

    for (final method in internalMappingMethods) {
      yield* method.bindings.expand((binding) => binding.mappingMethods);
    }
  }

  @override
  String toString() => 'MapperClass{'
      'name: $name, '
      'constructors: $constructors, '
      'mappingMethods: $_mappingMethods'
      '}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapperClass &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}
