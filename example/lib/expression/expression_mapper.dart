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

part 'expression_mapper.g.dart';

class SourceObject {
  final String name;
  final int price;

  const SourceObject(
    this.name,
    this.price,
  );
}

class TargetObject {
  final String name;
  final int price;

  const TargetObject(
    this.name,
    this.price,
  );
}

@BuiltValue()
abstract class BuiltObject implements Built<BuiltObject, BuiltObjectBuilder> {
  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'price')
  int get price;

  BuiltObject._();

  factory BuiltObject(
      // ignore: use_function_type_syntax_for_parameters
      [void updates(BuiltObjectBuilder b)]) = _$BuiltObject;
}

int _convertPrice(dynamic price) {
  return price * 2;
}

@Mapper()
abstract class ExpressionMapper {
  const ExpressionMapper();

  @Mapping(target: 'price', callable: _convertPrice)
  TargetObject toTargetObject(SourceObject source);

  @Mapping(target: 'price', callable: _convertPrice)
  BuiltObject toBuiltObject(SourceObject source);

  @Mapping(target: 'price', callable: _convertPrice)
  SourceObject toSourceObjectFromBuiltObject(BuiltObject source);

  @Mapping(target: 'price', callable: _convertPrice)
  SourceObject toSourceObject(BuiltObject source);

  @Mapping(target: 'price', callable: _convertPrice)
  TargetObject toTargetObjectFromBuiltObject(BuiltObject source);
}
