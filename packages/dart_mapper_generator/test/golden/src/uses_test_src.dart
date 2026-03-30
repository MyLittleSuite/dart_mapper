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

// Golden test source for @Mapper(uses: {...}) external mapper injection.
//
// Validates that when a mapper declares `uses: {OtherMapper}`, the generated
// implementation receives the external mapper as a constructor parameter and
// delegates nested object conversion to it.

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

class UsesInnerSource {
  final String value;

  UsesInnerSource(this.value);
}

class UsesInnerTarget {
  final String value;

  UsesInnerTarget(this.value);
}

class UsesOuterSource {
  final String label;
  final UsesInnerSource item;

  UsesOuterSource(this.label, this.item);
}

class UsesOuterTarget {
  final String label;
  final UsesInnerTarget item;

  UsesOuterTarget(this.label, this.item);
}

// The inner mapper has no `uses` — standard standalone implementation.
@ShouldGenerate(
  r'''class UsesInnerMapperImpl extends UsesInnerMapper''',
  contains: true,
)
@Mapper()
abstract class UsesInnerMapper {
  UsesInnerTarget convert(UsesInnerSource source);
}

// The outer mapper uses UsesInnerMapper for nested field conversion.
// The generated class must accept UsesInnerMapper as a required constructor param
// and delegate inner object conversion to it.
@ShouldGenerate(
  r'''class UsesOuterMapperImpl extends UsesOuterMapper''',
  contains: true,
)
@ShouldGenerate(
  // External mapper injected as a constructor parameter
  r'''UsesOuterMapperImpl({required this.usesInnerMapper})''',
  contains: true,
)
@ShouldGenerate(
  // Field declaration for the injected mapper
  r'''final UsesInnerMapper usesInnerMapper''',
  contains: true,
)
@ShouldGenerate(
  // Delegation to the injected mapper for nested object
  r'''usesInnerMapper.convert(source.item)''',
  contains: true,
)
@Mapper(uses: {UsesInnerMapper})
abstract class UsesOuterMapper {
  UsesOuterTarget convert(UsesOuterSource source);
}
