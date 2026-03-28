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

import 'package:dart_mapper/dart_mapper.dart';
import 'package:dart_mapper_example/condition_expression/models.dart';

part 'mapper.g.dart';

/// Demonstrates EXPR-03 and EXPR-04: conditional field mapping.
/// conditionExpression: evaluates a boolean expression; maps the field only when true.
/// false-branch: null for nullable targets, or defaultValue if provided.
@Mapper()
abstract class MemberMapper {
  const MemberMapper();

  /// EXPR-03: nullable target — false branch is null
  @Mapping(
    target: 'accessLevel',
    conditionExpression: 'source.age >= 18',
  )

  /// EXPR-04: with defaultValue — false branch is the default
  @Mapping(
    target: 'premiumLabel',
    conditionExpression: 'source.premium',
    defaultValue: 'standard',
  )
  MemberOutput toOutput(MemberInput source);
}

/// Demonstrates conditionExpression: with string interpolation syntax.
/// Using \${...} inside conditionExpression: wraps each interpolation token
/// individually — the generator produces valid Dart without manual quoting.
@Mapper()
abstract class TagMapper {
  const TagMapper();

  /// The condition r'${source.label}.isNotEmpty' becomes
  /// '${source.label}'.isNotEmpty in generated code.
  @Mapping(
    target: 'label',
    conditionExpression: r'${source.label}.isNotEmpty',
  )
  TagOutput toOutput(TagInput source);
}
