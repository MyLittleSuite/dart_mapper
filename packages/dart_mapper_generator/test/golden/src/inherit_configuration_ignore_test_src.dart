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

// Golden test source for @InheritConfiguration propagating ignore: true.
//
// Validates that a method annotated with @InheritConfiguration does NOT
// copy the ignored field from source — it passes null for that field.

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

class IgnoreSource {
  final String name;
  final int age;
  final String? secret;

  IgnoreSource(this.name, this.age, this.secret);
}

class IgnoreTarget {
  final String name;
  final int age;
  final String? secret;

  IgnoreTarget(this.name, this.age, this.secret);
}

// toTarget ignores 'secret' — must produce: return IgnoreTarget(source.name, source.age, null)
// toTargetDirect inherits that ignore via @InheritConfiguration — must produce the same body.

@ShouldGenerate(
  r'''IgnoreTarget toTarget(IgnoreSource source)''',
  contains: true,
)
@ShouldGenerate(
  r'''return IgnoreTarget(source.name, source.age, null)''',
  contains: true,
)
@ShouldGenerate(
  r'''IgnoreTarget toTargetDirect(IgnoreSource source)''',
  contains: true,
)
@Mapper()
abstract class InheritIgnoreMapper {
  @Mapping(target: 'secret', ignore: true)
  IgnoreTarget toTarget(IgnoreSource source);

  @InheritConfiguration()
  IgnoreTarget toTargetDirect(IgnoreSource source);
}
