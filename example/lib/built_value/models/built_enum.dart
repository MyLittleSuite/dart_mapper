/*
 *
 *  * Copyright (c) 2024 MyLittleSuite
 *  *
 *  * Permission is hereby granted, free of charge, to any person
 *  * obtaining a copy of this software and associated documentation
 *  * files (the "Software"), to deal in the Software without
 *  * restriction, including without limitation the rights to use,
 *  * copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  * copies of the Software, and to permit persons to whom the
 *  * Software is furnished to do so, subject to the following
 *  * conditions:
 *  *
 *  * The above copyright notice and this permission notice shall be
 *  * included in all copies or substantial portions of the Software.
 *  *
 *  * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 *  * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 *  * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 *  * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 *  * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 *  * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *  * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 *  * OTHER DEALINGS IN THE SOFTWARE.
 *
 */
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'built_enum.g.dart';

class BuiltEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'WALK')
  static const BuiltEnum WALK = _$WALK;
  @BuiltValueEnumConst(wireName: r'BUS')
  static const BuiltEnum BUS = _$BUS;
  @BuiltValueEnumConst(wireName: r'UNKNOWN', fallback: true)
  static const BuiltEnum UNKNOWN = _$UNKNOWN;

  static Serializer<BuiltEnum> get serializer => _$builtEnumSerializer;

  const BuiltEnum._(String name) : super(name);

  static BuiltSet<BuiltEnum> get values => _$values;

  static BuiltEnum valueOf(String name) => _$valueOf(name);
}
