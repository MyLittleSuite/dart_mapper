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

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';

part 'map_item.g.dart';

@BuiltValue()
abstract class BVMapSource implements Built<BVMapSource, BVMapSourceBuilder> {
  @BuiltValueField(wireName: r'scores')
  BuiltMap<String, int> get scores;

  BVMapSource._();

  // ignore: use_function_type_syntax_for_parameters
  factory BVMapSource([void updates(BVMapSourceBuilder b)]) = _$BVMapSource;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(BVMapSourceBuilder b) => b;
}

@BuiltValue()
abstract class BVMapTarget implements Built<BVMapTarget, BVMapTargetBuilder> {
  @BuiltValueField(wireName: r'scores')
  BuiltMap<String, int> get scores;

  BVMapTarget._();

  // ignore: use_function_type_syntax_for_parameters
  factory BVMapTarget([void updates(BVMapTargetBuilder b)]) = _$BVMapTarget;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(BVMapTargetBuilder b) => b;
}
