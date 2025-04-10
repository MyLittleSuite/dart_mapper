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

import 'package:built_value/built_value.dart';
import 'package:dart_mapper/dart_mapper.dart';

part 'built_value_force_non_null.g.dart';

@BuiltValue()
abstract class BuiltValueForceNonNull
    implements Built<BuiltValueForceNonNull, BuiltValueForceNonNullBuilder> {
  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'age')
  int get age;

  BuiltValueForceNonNull._();

  factory BuiltValueForceNonNull([
    // ignore: use_function_type_syntax_for_parameters
    void updates(BuiltValueForceNonNullBuilder b),
  ]) = _$BuiltValueForceNonNull;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(BuiltValueForceNonNullBuilder b) => b;
}

class AnotherForceNonNull {
  final String? name;
  final int? age;

  AnotherForceNonNull(
    this.name,
    this.age,
  );
}

@Mapper()
abstract class BuiltValueForceNonNullMapper {
  AnotherForceNonNull toAnotherForceNonNull(BuiltValueForceNonNull object);

  @Mapping(target: 'name', forceNonNull: true)
  @Mapping(target: 'age', forceNonNull: true)
  BuiltValueForceNonNull toBuiltValueForceNonNull(AnotherForceNonNull object);
}
