/*
 * Copyright (c) 2026 MyLittleSuite
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
import 'package:dart_mapper_generator/src/models/field/field.dart';

/// A "field" read from a map key in a Map -> class mapping.
///
/// [name] is the last key of the path, [keys] the whole path (more than one
/// key when a dot notation source walks nested maps) and [instance] the map
/// parameter the path starts from. [valueType] is the value type of a typed
/// `Map<String, V>` source, or `null` when the map is untyped
/// (raw / `dynamic` / `Object?` values).
class MapEntryField extends Field {
  final List<String> keys;
  final DartType? valueType;

  const MapEntryField({
    required super.name,
    required super.type,
    required super.instance,
    required this.keys,
    this.valueType,
    super.nullable = false,
  });

  @override
  String toString() => 'MapEntryField{'
      'keys: $keys, '
      'valueType: $valueType, '
      'nullable: $nullable, '
      'instance: $instance'
      '}';
}
