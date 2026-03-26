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

// Golden test source for enum-to-enum mapping.
//
// Tests: enum-to-enum with matching values, @ValueMapping renaming,
// enum-to-String conversion. Establishes baseline before ENUM-03 fix.

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

enum SourceColor {
  red,
  green,
  blue,
}

enum TargetColor {
  red,
  green,
  blue,
}

enum TargetColorRenamed {
  crimson,
  green,
  blue,
}

@ShouldGenerate(
  r'''SourceColor.red => TargetColor.red,''',
  contains: true,
)
@ShouldGenerate(
  r'''SourceColor.green => TargetColor.green,''',
  contains: true,
)
@ShouldGenerate(
  r'''SourceColor.blue => TargetColor.blue,''',
  contains: true,
)
@ShouldGenerate(
  r'''SourceColor.red => TargetColorRenamed.crimson,''',
  contains: true,
)
@ShouldGenerate(
  r'''SourceColor.red => 'red',''',
  contains: true,
)
@ShouldGenerate(
  r'''SourceColor.green => 'green',''',
  contains: true,
)
@ShouldGenerate(
  r'''SourceColor.blue => 'blue',''',
  contains: true,
)
@Mapper()
abstract class EnumMapper {
  TargetColor toTarget(SourceColor source);

  @ValueMapping(target: 'crimson', source: 'red')
  TargetColorRenamed toTargetRenamed(SourceColor source);

  String toStringFromEnum(SourceColor source);
}
