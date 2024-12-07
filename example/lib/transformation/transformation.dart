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

part 'transformation.g.dart';

class TransformationSource {
  final String date;
  final String? nullableDate;
  final String integerValue;
  final String? nullableIntegerValue;
  final String doubleValue;
  final String? nullableDoubleValue;
  final String numValue;
  final String? nullableNumValue;
  final int numFromIntValue;
  final int? nullableNumFromIntValue;
  final double numFromDoubleValue;
  final double? nullableNumFromDoubleValue;

  const TransformationSource({
    required this.date,
    this.nullableDate,
    required this.integerValue,
    this.nullableIntegerValue,
    required this.doubleValue,
    this.nullableDoubleValue,
    required this.numValue,
    this.nullableNumValue,
    required this.numFromIntValue,
    this.nullableNumFromIntValue,
    required this.numFromDoubleValue,
    this.nullableNumFromDoubleValue,
  });
}

class TransformationTarget {
  final DateTime date;
  final DateTime? nullableDate;
  final int integerValue;
  final int? nullableIntegerValue;
  final double doubleValue;
  final double? nullableDoubleValue;
  final num numValue;
  final num? nullableNumValue;
  final num numFromIntValue;
  final num? nullableNumFromIntValue;
  final num numFromDoubleValue;
  final num? nullableNumFromDoubleValue;

  const TransformationTarget({
    required this.date,
    this.nullableDate,
    required this.integerValue,
    this.nullableIntegerValue,
    required this.doubleValue,
    this.nullableDoubleValue,
    required this.numValue,
    this.nullableNumValue,
    required this.numFromIntValue,
    this.nullableNumFromIntValue,
    required this.numFromDoubleValue,
    this.nullableNumFromDoubleValue,
  });
}

@Mapper()
abstract class TransformationMapper {
  TransformationTarget toTransformationTarget(TransformationSource source);

  TransformationSource toTransformationSource(TransformationTarget target);
}
