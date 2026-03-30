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

// Golden test source for @InheritConfiguration and @InheritInverseConfiguration.
//
// Validates that a method annotated with @InheritConfiguration generates the same
// output as the base method, and that @InheritInverseConfiguration generates the
// inverse mapping (flipping source/target field renaming).

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

class ICSource {
  final String name;
  final int age;

  ICSource(this.name, this.age);
}

class ICTarget {
  final String fullName;
  final int age;

  ICTarget(this.fullName, this.age);
}

// ── Test 1: @InheritConfiguration ─────────────────────────────────────────────
// The `duplicate` method inherits all @Mapping annotations from `toTarget`.
// Both methods should produce identical generated bodies.

@ShouldGenerate(
  r'''class InheritConfigMapperImpl extends InheritConfigMapper''',
  contains: true,
)
@ShouldGenerate(
  r'''ICTarget duplicate(ICSource source)''',
  contains: true,
)
@ShouldGenerate(
  // `toTarget` body: name→fullName rename applied
  r'''return ICTarget(source.name, source.age)''',
  contains: true,
)
@Mapper()
abstract class InheritConfigMapper {
  @Mapping(target: 'fullName', source: 'name')
  ICTarget toTarget(ICSource source);

  @InheritConfiguration()
  ICTarget duplicate(ICSource source);
}

// ── Test 2: @InheritInverseConfiguration ──────────────────────────────────────
// The `fromTarget` method inherits the inverse of `toTarget`'s @Mapping.
// fullName (target field) maps back to name (source field).

@ShouldGenerate(
  r'''class InheritInverseMapperImpl extends InheritInverseMapper''',
  contains: true,
)
@ShouldGenerate(
  r'''ICSource fromTarget(ICTarget target)''',
  contains: true,
)
@ShouldGenerate(
  // Inverse: target.fullName → source name, target.age → source age
  r'''return ICSource(target.fullName, target.age)''',
  contains: true,
)
@Mapper()
abstract class InheritInverseMapper {
  @Mapping(target: 'fullName', source: 'name')
  ICTarget toTarget(ICSource source);

  @InheritInverseConfiguration()
  ICSource fromTarget(ICTarget target);
}
