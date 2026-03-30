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

// Golden test source for @Mapper(implementationName: '...') custom naming.
//
// Validates that the generated implementation class uses the overridden name
// instead of the default '<ClassName>Impl' pattern.

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

class ImplNameSource {
  final String value;

  ImplNameSource(this.value);
}

class ImplNameTarget {
  final String value;

  ImplNameTarget(this.value);
}

// ── Test 1: literal custom name ────────────────────────────────────────────────
// `implementationName: 'MyCustomMapper'` → generated class is `MyCustomMapper`.

@ShouldGenerate(
  r'''class MyCustomMapper extends LiteralNameMapper''',
  contains: true,
)
@Mapper(implementationName: 'MyCustomMapper')
abstract class LiteralNameMapper {
  ImplNameTarget toTarget(ImplNameSource source);
}

// ── Test 2: template-style name using <CLASS_NAME> token ──────────────────────
// `implementationName: 'My<CLASS_NAME>Gen'` → `MyTemplateNameMapperGen`.

@ShouldGenerate(
  r'''class MyTemplateNameMapperGen extends TemplateNameMapper''',
  contains: true,
)
@Mapper(implementationName: 'My<CLASS_NAME>Gen')
abstract class TemplateNameMapper {
  ImplNameTarget toTarget(ImplNameSource source);
}
