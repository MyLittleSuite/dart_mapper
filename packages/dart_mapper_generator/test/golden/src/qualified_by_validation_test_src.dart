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

// Golden test source for the validation of `qualifiedBy` and of
// comma-separated sources resolved through mapper methods.

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

class QualifiedSource {
  final String firstName;
  final String lastName;

  const QualifiedSource({required this.firstName, required this.lastName});
}

class QualifiedTarget {
  final String fullName;

  const QualifiedTarget({required this.fullName});
}

String _join(String first, String last) => '$first $last';

@ShouldThrow(
  "Invalid @Mapping combination for target 'fullName': qualifiedBy cannot be combined with callable.\n"
  "The following combinations are not allowed: constant+source, constant+defaultValue, constant+callable, defaultValue+callable.\n"
  "Fix: Use only one of: source, defaultValue, constant, or callable per target field.",
)
@Mapper()
abstract class QualifiedByWithCallableMapper {
  @Mapping(
    target: 'fullName',
    source: 'firstName,lastName',
    callable: _join,
    qualifiedBy: 'join',
  )
  QualifiedTarget toTarget(QualifiedSource source);
}

@ShouldThrow(
  "Invalid @Mapping combination for target 'fullName': qualifiedBy cannot be combined with expression.\n"
  "The following combinations are not allowed: constant+source, constant+defaultValue, constant+callable, defaultValue+callable.\n"
  "Fix: Use only one of: source, defaultValue, constant, or callable per target field.",
)
@Mapper()
abstract class QualifiedByWithExpressionMapper {
  @Mapping(
    target: 'fullName',
    expression: "'x'",
    qualifiedBy: 'join',
  )
  QualifiedTarget toTarget(QualifiedSource source);
}

@ShouldThrow(
  "Invalid @Mapping combination for target 'fullName': qualifiedBy cannot be combined with constant.\n"
  "The following combinations are not allowed: constant+source, constant+defaultValue, constant+callable, defaultValue+callable.\n"
  "Fix: Use only one of: source, defaultValue, constant, or callable per target field.",
)
@Mapper()
abstract class QualifiedByWithConstantMapper {
  @Mapping(
    target: 'fullName',
    constant: "'x'",
    qualifiedBy: 'join',
  )
  QualifiedTarget toTarget(QualifiedSource source);
}

@ShouldThrow(
  "Invalid @Mapping combination for target 'fullName': qualifiedBy cannot be combined with ignore.\n"
  "The following combinations are not allowed: constant+source, constant+defaultValue, constant+callable, defaultValue+callable.\n"
  "Fix: Use only one of: source, defaultValue, constant, or callable per target field.",
)
@Mapper()
abstract class QualifiedByWithIgnoreMapper {
  @Mapping(
    target: 'fullName',
    ignore: true,
    qualifiedBy: 'join',
  )
  QualifiedTarget toTarget(QualifiedSource source);
}

@ShouldThrow(
  "forceNonNull cannot be used with a comma-separated source in @Mapping(target: 'fullName') when no callable is set.\n"
  "The sources are combined by a mapper method, whose result is returned as is.\n"
  "Fix: Remove forceNonNull, or set a callable.",
)
@Mapper()
abstract class ForceNonNullCommaSourceMapper {
  @Mapping(
    target: 'fullName',
    source: 'firstName,lastName',
    forceNonNull: true,
  )
  QualifiedTarget toTarget(QualifiedSource source);
}
