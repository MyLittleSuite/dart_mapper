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

// Golden test source for auto-generated enum-to-enum private helper methods.
//
// Validates that GeneratedPrivateMappingMethod used in EnumMappingCodeProcessor
// produces a switch with all bindings (not an empty switch).

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

enum BoxColor { red, green, blue, extra }

enum ResultColor { red, green, blue, other }

class ColorBox {
  final BoxColor color;

  ColorBox(this.color);
}

class ColorResult {
  final ResultColor color;

  ColorResult(this.color);
}

// toResult must generate a private helper _mapBoxColorToResultColor.
// That helper must have switch cases for red, green, blue (auto-mapped by name).
// 'extra' has no matching name in ResultColor — it falls to the throw wildcard.

@ShouldGenerate(
  r'''_mapBoxColorToResultColor''',
  contains: true,
)
@ShouldGenerate(
  r'''BoxColor.red => ResultColor.red,''',
  contains: true,
)
@ShouldGenerate(
  r'''BoxColor.green => ResultColor.green,''',
  contains: true,
)
@ShouldGenerate(
  r'''BoxColor.blue => ResultColor.blue,''',
  contains: true,
)
@Mapper()
abstract class ColorBoxMapper {
  ColorResult toResult(ColorBox source);
}
