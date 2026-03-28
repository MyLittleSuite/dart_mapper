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
  @Mapping(target: "name", source: "fullName", constant: "test")
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
  @Mapping(target: "name", constant: "test", defaultValue: "fallback")
  ErrorOutput toOutput(ErrorInput source);
}

// Fix 3: constant + ignore combination throws
@ShouldThrow(
  "Invalid @Mapping combination for target 'name': constant cannot be combined with ignore.\n"
  "The following combinations are not allowed: constant+source, constant+defaultValue, constant+callable, defaultValue+callable.\n"
  "Fix: Use only one of: source, defaultValue, constant, or callable per target field.",
)
@Mapper()
abstract class ConstantWithIgnoreMapper {
  @Mapping(target: 'name', constant: "test", ignore: true)
  ErrorOutput toOutput(ErrorInput source);
}

// Fix 6: int target with String constant → type mismatch
class CountInput {
  final String label;

  const CountInput({required this.label});
}

class CountOutput {
  final String label;
  final int count;

  const CountOutput({required this.label, required this.count});
}

@ShouldThrow(
  "@Mapping constant/defaultValue 'hello' is not compatible with target field 'count' "
  "of type 'int'. Expected a int literal.",
)
@Mapper()
abstract class IntConstantTypeMismatchMapper {
  @Mapping(target: 'count', constant: 'hello')
  CountOutput toOutput(CountInput source);
}

// Fix 6: bool target with invalid constant → type mismatch
class FlagInput2 {
  final String name;

  const FlagInput2({required this.name});
}

class FlagOutput2 {
  final String name;
  final bool active;

  const FlagOutput2({required this.name, required this.active});
}

@ShouldThrow(
  "@Mapping constant/defaultValue 'maybe' is not compatible with target field 'active' "
  "of type 'bool'. Expected a bool literal.",
)
@Mapper()
abstract class BoolConstantTypeMismatchMapper {
  @Mapping(target: 'active', constant: 'maybe')
  FlagOutput2 toOutput(FlagInput2 source);
}

// Fix 6: double target with invalid constant → type mismatch
class ScoreInput {
  final String name;

  const ScoreInput({required this.name});
}

class ScoreOutput {
  final String name;
  final double score;

  const ScoreOutput({required this.name, required this.score});
}

@ShouldThrow(
  "@Mapping constant/defaultValue 'abc' is not compatible with target field 'score' "
  "of type 'double'. Expected a double literal.",
)
@Mapper()
abstract class DoubleConstantTypeMismatchMapper {
  @Mapping(target: 'score', constant: 'abc')
  ScoreOutput toOutput(ScoreInput source);
}

// Fix 6: num target with invalid constant → type mismatch
class AmountInput {
  final String name;

  const AmountInput({required this.name});
}

class AmountOutput {
  final String name;
  final num amount;

  const AmountOutput({required this.name, required this.amount});
}

@ShouldThrow(
  "@Mapping constant/defaultValue 'abc' is not compatible with target field 'amount' "
  "of type 'num'. Expected a num literal.",
)
@Mapper()
abstract class NumConstantTypeMismatchMapper {
  @Mapping(target: 'amount', constant: 'abc')
  AmountOutput toOutput(AmountInput source);
}
