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

// Golden test source for ENUM-03: mismatched enum values without fallback
// should produce an InvalidGenerationSourceError at generation time.

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

enum SourceStatus {
  active,
  inactive,
  pending,
}

enum TargetStatus {
  active,
  inactive,
  archived,
}

// 'pending' in source has no match in target, and no @ValueMapping is provided.
// The generator must throw InvalidGenerationSourceError listing unmapped values.
@ShouldThrow('Unmapped source enum values: pending. Provide @ValueMapping for each value or use <ANY_REMAINING>/<ANY_UNMAPPED> as a default fallback.')
@Mapper()
abstract class MismatchedEnumMapper {
  TargetStatus toTarget(SourceStatus source);
}
