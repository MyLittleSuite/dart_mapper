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

// Golden test source for ENUM-01 and ENUM-02: enum sentinel defaults
// via <ANY_REMAINING> and <ANY_UNMAPPED> in @ValueMapping.

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

enum SourceColor {
  red,
  green,
  blue,
  yellow,
}

enum TargetColor {
  red,
  green,
  blue,
}

enum TargetColorNullable {
  red,
  green,
  blue,
}

// Mapper 1: <ANY_REMAINING> maps unmapped values to a default target value.
@ShouldGenerate(
  r'''_ => TargetColor.blue''',
  contains: true,
)
@Mapper()
abstract class AnyRemainingEnumMapper {
  @ValueMapping(source: '<ANY_REMAINING>', target: 'blue')
  TargetColor convert(SourceColor source);
}

// Mapper 2: <ANY_UNMAPPED> maps unmapped values to null (nullable return).
@ShouldGenerate(
  r'''_ => null''',
  contains: true,
)
@Mapper()
abstract class AnyUnmappedEnumMapper {
  @ValueMapping(source: '<ANY_UNMAPPED>', target: '<NULL>')
  TargetColorNullable? convert(SourceColor source);
}

// Mapper 3: <ANY_UNMAPPED> with non-nullable return type should throw error.
@ShouldThrow(
  '<ANY_UNMAPPED> requires a nullable return type. '
  'Change the return type to a nullable enum type (e.g., TargetColor?).',
)
@Mapper()
abstract class AnyUnmappedNonNullableEnumMapper {
  @ValueMapping(source: '<ANY_UNMAPPED>', target: '<NULL>')
  TargetColor convert(SourceColor source);
}

// Mapper 4: Using both <ANY_REMAINING> and <ANY_UNMAPPED> is not allowed.
@ShouldThrow(
  '<ANY_REMAINING> and <ANY_UNMAPPED> cannot be used on the same method. '
  'Use <ANY_REMAINING> to map to a default value, or <ANY_UNMAPPED> to map to null.',
)
@Mapper()
abstract class MutualExclusionEnumMapper {
  @ValueMapping(source: '<ANY_REMAINING>', target: 'blue')
  @ValueMapping(source: '<ANY_UNMAPPED>', target: '<NULL>')
  TargetColor convert(SourceColor source);
}
