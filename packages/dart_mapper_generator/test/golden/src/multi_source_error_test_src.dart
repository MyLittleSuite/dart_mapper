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

// Golden test source for D-02: ambiguous source field in multi-source mapping
// should produce an InvalidGenerationSourceError at generation time.

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

class AmbigSource1 {
  final String name;

  const AmbigSource1({required this.name});
}

class AmbigSource2 {
  final String name;

  const AmbigSource2({required this.name});
}

class AmbigTarget {
  final String name;

  const AmbigTarget({required this.name});
}

// 'name' exists in both AmbigSource1 and AmbigSource2 with no @Mapping qualification.
// The generator must throw AmbiguousSourceFieldError.
@ShouldThrow(
  "Ambiguous source field 'name' found in multiple parameters: source1, source2.\n"
  "When multiple source parameters share a field name, you must qualify the source explicitly.\n"
  "Fix: Add @Mapping(target: 'name', source: 'source1.name') to specify which parameter to use.",
)
@Mapper()
abstract class AmbiguousFieldMapper {
  AmbigTarget merge(AmbigSource1 source1, AmbigSource2 source2);
}
