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
import 'package:dart_mapper_generator/src/models/field/field.dart';
import 'package:dart_mapper_generator/src/models/instance.dart';

class MapField extends Field {
  const MapField({
    required super.name,
    required super.type,
    super.instance,
    super.required = false,
    super.nullable = false,
  });

  Field? get key {
    final genericOfKey =
        (type as ParameterizedType?)?.typeArguments.firstOrNull;

    if (genericOfKey != null) {
      return Field.from(
        name: genericOfKey.parameterName,
        type: genericOfKey,
        instance: Instance(name: genericOfKey.parameterName),
        required: true,
        nullable: genericOfKey.isNullable,
      );
    }

    return null;
  }

  Field? get value {
    final genericOfValue =
        (type as ParameterizedType?)?.typeArguments.elementAtOrNull(1);

    if (genericOfValue != null) {
      return Field.from(
        name: genericOfValue.parameterName,
        type: genericOfValue,
        instance: Instance(name: genericOfValue.parameterName),
        required: true,
        nullable: genericOfValue.isNullable,
      );
    }

    return null;
  }

  @override
  String toString() => 'MapField{'
      'name: $name, '
      'type: $type, '
      'required: $required, '
      'nullable: $nullable, '
      'instance: $instance'
      '}';
}
