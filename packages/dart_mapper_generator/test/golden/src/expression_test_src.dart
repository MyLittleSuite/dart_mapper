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

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

class PersonInput {
  final String first;
  final String last;
  const PersonInput({required this.first, required this.last});
}

class PersonOutput {
  final String fullName;
  const PersonOutput({required this.fullName});
}

@ShouldGenerate(
  r"""PersonOutput toOutput(PersonInput source) {
    return PersonOutput(fullName: source.first + ' ' + source.last);
  }""",
  contains: true,
)
@Mapper()
abstract class ExpressionMapper {
  @Mapping(target: 'fullName', expression: "source.first + ' ' + source.last")
  PersonOutput toOutput(PersonInput source);
}

class ScoreInput {
  final int score;
  const ScoreInput({required this.score});
}

class LabelOutput {
  final String label;
  const LabelOutput({required this.label});
}

@ShouldGenerate(
  r'''LabelOutput toOutput(ScoreInput source) {
    return LabelOutput(label: source.score.toString());
  }''',
  contains: true,
)
@Mapper()
abstract class ExpressionStringTargetMapper {
  @Mapping(target: 'label', expression: 'source.score.toString()')
  LabelOutput toOutput(ScoreInput source);
}

class UserInfo {
  final String name;
  const UserInfo({required this.name});
}

class CompanyInfo {
  final String name;
  const CompanyInfo({required this.name});
}

class CombinedOutput {
  final String combined;
  const CombinedOutput({required this.combined});
}

@ShouldGenerate(
  r"""CombinedOutput toOutput(UserInfo user, CompanyInfo company) {
    return CombinedOutput(combined: user.name + '/' + company.name);
  }""",
  contains: true,
)
@Mapper()
abstract class MultiSourceExpressionMapper {
  @Mapping(target: 'combined', expression: "user.name + '/' + company.name")
  CombinedOutput toOutput(UserInfo user, CompanyInfo company);
}

@ShouldGenerate(
  r"""PersonOutput toOutput(PersonInput source) {
    return PersonOutput(fullName: '${source.first} ${source.last}');
  }""",
  contains: true,
)
@Mapper()
abstract class ExpressionInterpolationMapper {
  @Mapping(target: 'fullName', expression: r'${source.first} ${source.last}')
  PersonOutput toOutput(PersonInput source);
}

class Query$typename {
  // ignore: non_constant_identifier_names
  final String $__typename;
  // ignore: non_constant_identifier_names
  const Query$typename({required this.$__typename});
}

class TypedOutput {
  final String typeName;
  const TypedOutput({required this.typeName});
}

@ShouldGenerate(
  r"""TypedOutput fromQuery(Query$typename from) {
    return TypedOutput(typeName: from.$__typename);
  }""",
  contains: true,
)
@Mapper()
abstract class DollarInPropertyExpressionMapper {
  @Mapping(target: 'typeName', expression: r'from.$__typename')
  TypedOutput fromQuery(Query$typename from);
}

class SwitchOutput {
  final String kind;
  const SwitchOutput({required this.kind});
}

@ShouldGenerate(
  """SwitchOutput fromQuery(Query\$typename from) {
    return SwitchOutput(
      kind: switch (from.\$__typename) {
        'TypeA' => 'a',
        _ => 'unknown',
      },
    );
  }""",
  contains: true,
)
@Mapper()
abstract class DollarInSwitchExpressionMapper {
  @Mapping(
    target: 'kind',
    expression: r"switch (from.$__typename) { 'TypeA' => 'a', _ => 'unknown' }",
  )
  SwitchOutput fromQuery(Query$typename from);
}
