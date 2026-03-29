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
import 'package:dart_mapper_example/expression/models.dart';

part 'mapper.g.dart';

/// Demonstrates EXPR-01: single-source expression mapping.
/// The expression is emitted verbatim in generated code.
/// Source parameter names (single-source: 'source') are available as variables.
@Mapper()
abstract class PersonMapper {
  const PersonMapper();

  @Mapping(
    target: 'fullName',
    expression: "source.firstName.substring(10)",
  )
  @Mapping(
    target: 'scoreLabel',
    expression: 'source.score.toString()',
  )
  PersonOutput toOutput(PersonInput source);
}

/// Demonstrates EXPR-01 with string interpolation syntax.
/// Using \${...} inside expression: is auto-wrapped in a string literal by the
/// generator — no need to manually add surrounding quotes.
@Mapper()
abstract class InterpolatedPersonMapper {
  const InterpolatedPersonMapper();

  @Mapping(
    target: 'fullName',
    expression: r'${source.firstName} ${source.lastName}',
  )
  @Mapping(
    target: 'scoreLabel',
    expression: r'Score: ${source.score}',
  )
  PersonOutput toOutput(PersonInput source);
}

/// Demonstrates EXPR-02: multi-source expression mapping.
/// Both source parameter names ('user', 'company') are available as variables.
@Mapper()
abstract class CombinedMapper {
  const CombinedMapper();

  @Mapping(
    target: 'combined',
    expression: r'${user.name} ${company.name}',
  )
  CombinedOutput toOutput(UserInfo user, CompanyInfo company);
}
