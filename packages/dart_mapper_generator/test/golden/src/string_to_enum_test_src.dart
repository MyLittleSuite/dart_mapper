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

// Golden test source for COLL-05: String→Enum auto-population by .name.
//
// Tests: no @ValueMapping → all cases auto-populated; partial @ValueMapping →
// user-provided entry + auto for remaining values.

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

enum Fruit {
  apple,
  banana,
  cherry,
}

enum Color {
  red,
  green,
  blue,
}

// Mapper 1: no @ValueMapping — all switch cases auto-populated from enum .name.
@ShouldGenerate(
  r"'apple' => Fruit.apple,",
  contains: true,
)
@ShouldGenerate(
  r"'banana' => Fruit.banana,",
  contains: true,
)
@ShouldGenerate(
  r"'cherry' => Fruit.cherry,",
  contains: true,
)
@Mapper()
abstract class StringToFruitMapper {
  Fruit toFruit(String source);
}

// Mapper 2: one @ValueMapping override ('RED' => Color.red), remaining values
// auto-populated from .name ('green' => Color.green, 'blue' => Color.blue).
@ShouldGenerate(
  r"'RED' => Color.red,",
  contains: true,
)
@ShouldGenerate(
  r"'green' => Color.green,",
  contains: true,
)
@ShouldGenerate(
  r"'blue' => Color.blue,",
  contains: true,
)
@Mapper()
abstract class StringToColorWithOverrideMapper {
  @ValueMapping(source: 'RED', target: 'red')
  Color toColor(String source);
}

// Mapper 3: int→Enum with explicit @ValueMapping only — no auto-population.
// Only user-provided cases appear; no .name-based string cases injected.
enum Priority { low, medium, high }

@ShouldGenerate(
  r"1 => Priority.low,",
  contains: true,
)
@ShouldGenerate(
  r"2 => Priority.medium,",
  contains: true,
)
@ShouldGenerate(
  r"3 => Priority.high,",
  contains: true,
)
@Mapper()
abstract class IntToPriorityMapper {
  @ValueMapping(source: '1', target: 'low')
  @ValueMapping(source: '2', target: 'medium')
  @ValueMapping(source: '3', target: 'high')
  Priority? toPriority(int? source);
}
