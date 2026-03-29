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

// Golden test source for EXPR-03 and EXPR-04:
// EXPR-03: conditionExpression: true-branch is mapped, false-branch is null/default
// EXPR-04: conditionExpression: with defaultValue uses default as false-branch

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

// ----- EXPR-03: nullable target — false branch is null -----

class AgeInput {
  final int age;
  final String? role;
  const AgeInput({required this.age, this.role});
}

class AgeOutput {
  final String? role;
  const AgeOutput({this.role});
}

@ShouldGenerate(
  r'''AgeOutput toOutput(AgeInput source) {
    return AgeOutput(role: source.age >= 18 ? source.role : null);
  }''',
  contains: true,
)
@Mapper()
abstract class ConditionExpressionNullableMapper {
  @Mapping(target: 'role', conditionExpression: 'source.age >= 18')
  AgeOutput toOutput(AgeInput source);
}

// ----- EXPR-04: nullable target with defaultValue — false branch is defaultValue -----

class StatusInput {
  final bool active;
  final String? label;
  const StatusInput({required this.active, this.label});
}

class StatusOutput {
  final String? label; // nullable — conditionExpression false-branch is 'inactive', not null
  const StatusOutput({this.label});
}

@ShouldGenerate(
  r"label: source.active ? source.label ?? 'inactive' : 'inactive',",
  contains: true,
)
@Mapper()
abstract class ConditionExpressionWithDefaultMapper {
  @Mapping(target: 'label', conditionExpression: 'source.active', defaultValue: 'inactive')
  StatusOutput toOutput(StatusInput source);
}

// ----- String interpolation auto-wrap for conditionExpression -----
// conditionExpression: with ${...} syntax is auto-wrapped in a string literal
// so the user does not need to manually add surrounding quotes.

class TagInput {
  final String? label;
  const TagInput({this.label});
}

class TagOutput {
  final String? label;
  const TagOutput({this.label});
}

@ShouldGenerate(
  r"""TagOutput toOutput(TagInput source) {
    return TagOutput(label: '${source.label}'.isNotEmpty ? source.label : null);
  }""",
  contains: true,
)
@Mapper()
abstract class ConditionExpressionInterpolationMapper {
  @Mapping(
    target: 'label',
    conditionExpression: r'${source.label}.isNotEmpty',
  )
  TagOutput toOutput(TagInput source);
}
