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

// Golden test source for EXPR-01 error cases (D-04 mutual exclusion).
// IMPORTANT: @ShouldThrow strings are placeholders — update after Plan 02 runs the generator.

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

class MixedInput {
  final String field;
  const MixedInput({required this.field});
}

class MixedOutput {
  final String result;
  const MixedOutput({required this.result});
}

@ShouldThrow(
  "Invalid @Mapping combination for target 'result': expression cannot be combined with source.\n"
  "The following combinations are not allowed: constant+source, constant+defaultValue, constant+callable, defaultValue+callable.\n"
  "Fix: Use only one of: source, defaultValue, constant, or callable per target field.",
)
@Mapper()
abstract class ExpressionWithSourceMapper {
  @Mapping(target: 'result', expression: 'source.field', source: 'field')
  MixedOutput method(MixedInput source);
}

@ShouldThrow(
  "Invalid @Mapping combination for target 'result': expression cannot be combined with defaultValue.\n"
  "The following combinations are not allowed: constant+source, constant+defaultValue, constant+callable, defaultValue+callable.\n"
  "Fix: Use only one of: source, defaultValue, constant, or callable per target field.",
)
@Mapper()
abstract class ExpressionWithDefaultValueMapper {
  @Mapping(target: 'result', expression: 'source.field', defaultValue: 'fallback')
  MixedOutput method(MixedInput source);
}

@ShouldThrow(
  "Invalid @Mapping combination for target 'result': expression cannot be combined with constant.\n"
  "The following combinations are not allowed: constant+source, constant+defaultValue, constant+callable, defaultValue+callable.\n"
  "Fix: Use only one of: source, defaultValue, constant, or callable per target field.",
)
@Mapper()
abstract class ExpressionWithConstantMapper {
  @Mapping(target: 'result', expression: 'source.field', constant: 'x')
  MixedOutput method(MixedInput source);
}
