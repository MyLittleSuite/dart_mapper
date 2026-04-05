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

// Golden test source for sentinel handling in String→Enum and $ escaping.
//
// Tests:
// - SENTINEL-01: anyUnmapped with specific target → _ => Enum.target (not literal '<ANY_UNMAPPED>')
// - SENTINEL-02: anyRemaining with specific target → _ => Enum.target (not literal '<ANY_REMAINING>')
// - SENTINEL-03: source string containing $ → '\$...' escaped in switch case
// - SENTINEL-04: target string containing $ → '\$...' escaped in switch result (Enum→String)

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

enum GqlField {
  id,
  name,
  $unknown,
}

enum Status {
  active,
  inactive,
  fallback,
}

enum DollarEnum {
  value,
}

// SENTINEL-01: anyUnmapped with specific enum target.
// The otherwise arm must be: _ => GqlField.$unknown
@ShouldGenerate(
  r"_ => GqlField.$unknown,",
  contains: true,
)
@Mapper()
abstract class AnyUnmappedToSpecificTargetMapper {
  @ValueMapping(source: 'id', target: 'id')
  @ValueMapping(source: 'name', target: 'name')
  @ValueMapping(source: ValueMapping.anyUnmapped, target: r'$unknown')
  GqlField? fromString(String value);
}

// SENTINEL-02: anyRemaining with specific enum target in String→Enum.
// The otherwise arm must be: _ => Status.fallback
@ShouldGenerate(
  r"_ => Status.fallback,",
  contains: true,
)
@Mapper()
abstract class AnyRemainingStringToEnumMapper {
  @ValueMapping(source: 'active', target: 'active')
  @ValueMapping(source: ValueMapping.anyRemaining, target: 'fallback')
  Status fromString(String value);
}

// SENTINEL-03: source string value containing '$' must be escaped as '\$'.
// The switch case must be '\$active' not '$active'.
@ShouldGenerate(
  r"'\$active' => DollarEnum.value,",
  contains: true,
)
@Mapper()
abstract class DollarSourceStringMapper {
  @ValueMapping(source: r'$active', target: 'value')
  DollarEnum? fromString(String value);
}

// SENTINEL-04: target string value containing '$' must be escaped as '\$'.
// The switch result must be '\$active' not '$active'.
@ShouldGenerate(
  r"DollarEnum.value => '\$active',",
  contains: true,
)
@Mapper()
abstract class DollarTargetStringMapper {
  @ValueMapping(source: 'value', target: r'$active')
  String? toGqlString(DollarEnum value);
}
