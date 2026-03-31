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

// Golden test source for nullValue-as-source in enum mapping.
//
// Tests: null input maps to a specific target enum value when
// @ValueMapping(source: ValueMapping.nullValue, target: '...') is declared.

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

enum ExtendedSourceColor {
  red,
  green,
  blue,
  yellow,
}

enum PrimaryTargetColor {
  red,
  green,
  blue,
}

@ShouldGenerate(
  r'''null => PrimaryTargetColor.red,''',
  contains: true,
)
@ShouldGenerate(
  r'''ExtendedSourceColor.red => PrimaryTargetColor.red,''',
  contains: true,
)
@ShouldGenerate(
  r'''_ => PrimaryTargetColor.blue,''',
  contains: true,
)
@Mapper()
abstract class NullValueSourceEnumMapper {
  @ValueMapping(source: ValueMapping.anyRemaining, target: 'blue')
  @ValueMapping(source: ValueMapping.nullValue, target: 'red')
  PrimaryTargetColor convertNullable(ExtendedSourceColor? source);
}
