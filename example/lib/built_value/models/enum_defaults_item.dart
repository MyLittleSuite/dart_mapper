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

import 'package:built_value/built_value.dart';

part 'enum_defaults_item.g.dart';

enum BVSourceStatus { active, inactive, pending, archived }

enum BVTargetStatus { active, inactive, pending }

@BuiltValue()
abstract class BVStatusItem
    implements Built<BVStatusItem, BVStatusItemBuilder> {
  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'status')
  BVSourceStatus get status;

  BVStatusItem._();

  // ignore: use_function_type_syntax_for_parameters
  factory BVStatusItem([void updates(BVStatusItemBuilder b)]) = _$BVStatusItem;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(BVStatusItemBuilder b) => b;
}

@BuiltValue()
abstract class BVMappedStatus
    implements Built<BVMappedStatus, BVMappedStatusBuilder> {
  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'status')
  BVTargetStatus get status;

  BVMappedStatus._();

  // ignore: use_function_type_syntax_for_parameters
  factory BVMappedStatus([void updates(BVMappedStatusBuilder b)]) =
      _$BVMappedStatus;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(BVMappedStatusBuilder b) => b;
}
