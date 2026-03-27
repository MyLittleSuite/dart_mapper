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

// Golden test source for D-13: mutual exclusion validation
// constant+source, constant+defaultValue combinations must produce errors.

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

class ErrorInput {
  final String fullName;

  const ErrorInput({required this.fullName});
}

class ErrorOutput {
  final String name;

  const ErrorOutput({required this.name});
}

// constant + source: not allowed
@ShouldThrow(
  "Invalid @Mapping combination for target 'name': constant cannot be combined with source.\n"
  "The following combinations are not allowed: constant+source, constant+defaultValue, constant+callable, defaultValue+callable.\n"
  "Fix: Use only one of: source, defaultValue, constant, or callable per target field.",
)
@Mapper()
abstract class ConstantWithSourceMapper {
  @Mapping(target: 'name', source: 'fullName', constant: "'test'")
  ErrorOutput toOutput(ErrorInput source);
}

// constant + defaultValue: not allowed
@ShouldThrow(
  "Invalid @Mapping combination for target 'name': constant cannot be combined with defaultValue.\n"
  "The following combinations are not allowed: constant+source, constant+defaultValue, constant+callable, defaultValue+callable.\n"
  "Fix: Use only one of: source, defaultValue, constant, or callable per target field.",
)
@Mapper()
abstract class ConstantWithDefaultValueMapper {
  @Mapping(target: 'name', constant: "'test'", defaultValue: "'fallback'")
  ErrorOutput toOutput(ErrorInput source);
}
