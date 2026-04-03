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

// Golden test source for ValueMapping.nullValue as target in enum-to-raw mapping.
//
// Tests: @ValueMapping(target: ValueMapping.nullValue, source: 'unknown')
// must emit `null` (literalNull) in the switch arm, not the '<NULL>' sentinel
// string literal.

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

enum ReceiptStatus {
  paid,
  pending,
  unknown,
}

// Verify that the 'unknown' enum value maps to null, not '<NULL>'.
@ShouldGenerate(
  r'''ReceiptStatus.unknown => null,''',
  contains: true,
)
@ShouldGenerate(
  r'''ReceiptStatus.paid => 'paid',''',
  contains: true,
)
@ShouldGenerate(
  r'''ReceiptStatus.pending => 'pending',''',
  contains: true,
)
@Mapper()
abstract class ReceiptStatusMapper {
  @ValueMapping(target: ValueMapping.nullValue, source: 'unknown')
  String? toGqlString(ReceiptStatus value);
}
