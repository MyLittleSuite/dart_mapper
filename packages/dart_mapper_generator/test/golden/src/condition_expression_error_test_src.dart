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

// Golden test source for EXPR-04 error case (D-07):
// conditionExpression: on non-nullable target without defaultValue throws.

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

// Source has a field with the same name as the target so auto-resolution
// creates the binding, then conditionExpression applies the ternary.
class NonNullInput {
  final bool flag;
  final String value; // same name as target — auto-resolves
  const NonNullInput({required this.flag, required this.value});
}

class NonNullOutput {
  final String value; // non-nullable — conditionExpression without defaultValue should throw
  const NonNullOutput({required this.value});
}

@ShouldThrow(
  "conditionExpression on non-nullable target 'value': requires a defaultValue or a nullable target type.\nFix: Add defaultValue: '...' to the @Mapping annotation, or make the target field nullable.",
  element: 'NonNullOutput',
)
@Mapper()
abstract class ConditionExpressionNonNullableMapper {
  @Mapping(target: 'value', conditionExpression: 'source.flag')
  NonNullOutput method(NonNullInput source);
}
