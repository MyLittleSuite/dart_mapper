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
import 'package:dart_mapper_generator/src/extensions/dart_type.dart';
import 'package:dart_mapper_generator/src/models/field/enum_field.dart';
import 'package:dart_mapper_generator/src/models/field/iterable_field.dart';
import 'package:dart_mapper_generator/src/models/field/map_field.dart';
import 'package:dart_mapper_generator/src/models/field/nested_field.dart';
import 'package:dart_mapper_generator/src/models/field/primitive_field.dart';
import 'package:dart_mapper_generator/src/models/instance.dart';

export 'enum_field.dart';
export 'iterable_field.dart';
export 'map_field.dart';
export 'nested_field.dart';
export 'primitive_field.dart';

abstract class Field {
  final String name;
  final DartType type;
  final Instance? instance;
  final bool required;
  final bool nullable;

  const Field({
    required this.name,
    required this.type,
    this.instance,
    this.required = false,
    this.nullable = false,
  });

  factory Field.from({
    required String name,
    required DartType type,
    Instance? instance,
    bool required = false,
    bool nullable = false,
  }) {
    if (type.isPrimitive) {
      return PrimitiveField(
        name: name,
        type: type,
        instance: instance,
        required: required,
        nullable: nullable,
      );
    } else if (type.isIterable) {
      return IterableField(
        name: name,
        type: type,
        instance: instance,
        required: required,
        nullable: nullable,
      );
    } else if (type.isMap) {
      return MapField(
        name: name,
        type: type,
        instance: instance,
        required: required,
        nullable: nullable,
      );
    } else if (type.isEnum) {
      return EnumField(
        name: name,
        type: type,
        instance: instance,
        required: required,
        nullable: nullable,
      );
    }

    return NestedField(
      name: name,
      type: type,
      instance: instance,
      required: required,
      nullable: nullable,
    );
  }
}
