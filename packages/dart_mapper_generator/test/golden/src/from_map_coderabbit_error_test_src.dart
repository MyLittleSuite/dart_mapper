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

// Golden test source for the CodeRabbit review findings of the Map -> class
// side that end in a build error.

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

// ----- 2. ambiguous dotted source -----

class CrAddress {
  final String city;

  const CrAddress({required this.city});
}

class CrMan {
  final CrAddress address;

  const CrMan({required this.address});
}

class CrWoman {
  final CrAddress address;

  const CrWoman({required this.address});
}

class CrCity {
  final String city;

  const CrCity({required this.city});
}

@ShouldThrow(
  "Ambiguous source field 'address' found in multiple parameters: man, woman.\n"
  "When multiple source parameters share a field name, you must qualify the source explicitly.\n"
  "Fix: Add @Mapping(target: 'city', source: 'man.address.city') to specify which parameter to use.",
)
@Mapper()
abstract class CrAmbiguousDottedMapper {
  @Mapping(target: 'city', source: 'address.city')
  CrCity fromTwo(Map<String, dynamic> map, CrMan man, CrWoman woman);
}

// ----- 4. iterable element validation -----

class CrStrings {
  final List<String> values;

  const CrStrings({required this.values});
}

@ShouldThrow(
  "Field 'values' of type 'List<String>' is not compatible with the map value type 'List<int>'.\n"
  "Fix: Declare the source map as Map<String, dynamic> (or Map<String, Object?>) or use callable.",
)
@Mapper()
abstract class CrElementMismatchMapper {
  CrStrings fromMap(Map<String, List<int>> map);
}

// ----- 9. collection kind and map key validation -----

class CrInts {
  final List<int> values;

  const CrInts({required this.values});
}

@ShouldThrow(
  "Field 'values' of type 'List<int>' is not compatible with the map value type 'Map<String, int>'.\n"
  "Fix: Declare the source map as Map<String, dynamic> (or Map<String, Object?>) or use callable.",
)
@Mapper()
abstract class CrMapToListMismatchMapper {
  CrInts fromMap(Map<String, Map<String, int>> map);
}

class CrIntMap {
  final Map<String, int> values;

  const CrIntMap({required this.values});
}

@ShouldThrow(
  "Field 'values' of type 'Map<String, int>' is not compatible with the map value type 'List<int>'.\n"
  "Fix: Declare the source map as Map<String, dynamic> (or Map<String, Object?>) or use callable.",
)
@Mapper()
abstract class CrListToMapMismatchMapper {
  CrIntMap fromMap(Map<String, List<int>> map);
}

@ShouldThrow(
  "Field 'values' of type 'Map<String, int>' is not compatible with the map value type 'Map<int, int>'.\n"
  "Fix: Declare the source map as Map<String, dynamic> (or Map<String, Object?>) or use callable.",
)
@Mapper()
abstract class CrMapKeyMismatchMapper {
  CrIntMap fromMap(Map<String, Map<int, int>> map);
}

// ----- 10. collection kind mismatch through a generated element mapper -----

class CrLeaf {
  final int value;

  const CrLeaf({required this.value});
}

class CrLeaves {
  final List<CrLeaf> leaves;

  const CrLeaves({required this.leaves});
}

@ShouldThrow(
  "Field 'leaves' of type 'List<CrLeaf>' is not compatible with the map value type 'Map<String, int>'.\n"
  "Fix: Declare the source map as Map<String, dynamic> (or Map<String, Object?>) or use callable.",
)
@Mapper()
abstract class CrMapToLeafListMismatchMapper {
  CrLeaves fromMap(Map<String, Map<String, int>> map);
}

// ----- 11. conflicting settings split across annotations -----

int crParse(String value) => int.parse(value);

class CrParsed {
  final int id;

  const CrParsed({required this.id});
}

@ShouldThrow(
  "Invalid @Mapping combination for target 'id': defaultValue cannot be combined with callable.\n"
  "The following combinations are not allowed: constant+source, constant+defaultValue, constant+callable, defaultValue+callable.\n"
  "Fix: Use only one of: source, defaultValue, constant, or callable per target field.",
)
@Mapper()
abstract class CrSplitCallableDefaultMapper {
  @Mapping(target: 'id', callable: crParse)
  @Mapping(target: 'id', defaultValue: '0')
  CrParsed fromMap(Map<String, dynamic> map);
}

@ShouldThrow(
  "Invalid @Mapping combination for target 'id': constant cannot be combined with source.\n"
  "The following combinations are not allowed: constant+source, constant+defaultValue, constant+callable, defaultValue+callable.\n"
  "Fix: Use only one of: source, defaultValue, constant, or callable per target field.",
)
@Mapper()
abstract class CrSplitSourceConstantMapper {
  @Mapping(target: 'id', source: 'key')
  @Mapping(target: 'id', constant: '1')
  CrParsed fromMap(Map<String, dynamic> map);
}

@ShouldThrow(
  "Invalid @Mapping combination for target 'id': expression cannot be combined with source.\n"
  "The following combinations are not allowed: constant+source, constant+defaultValue, constant+callable, defaultValue+callable.\n"
  "Fix: Use only one of: source, defaultValue, constant, or callable per target field.",
)
@Mapper()
abstract class CrSplitSourceExpressionMapper {
  @Mapping(target: 'id', source: 'key')
  @Mapping(target: 'id', expression: '1')
  CrParsed fromMap(Map<String, dynamic> map);
}

// ----- 12. converter advice only where a converter can be used -----

class CrStamp {
  final DateTime at;

  const CrStamp({required this.at});
}

@ShouldThrow(
  "Field 'at' of type 'DateTime' is not compatible with the map value type 'int'.\n"
  "Fix: Declare the source map as Map<String, dynamic> (or Map<String, Object?>), declare a converter method from 'int' to 'DateTime', or use callable.",
)
@Mapper()
abstract class CrStampAdviceMapper {
  CrStamp fromMap(Map<String, int> map);
}

class CrStamps {
  final List<DateTime> at;

  const CrStamps({required this.at});
}

@ShouldThrow(
  "Field 'at' of type 'List<DateTime>' is not compatible with the map value type 'List<int>'.\n"
  "Fix: Declare the source map as Map<String, dynamic> (or Map<String, Object?>), declare a converter method from 'int' to 'DateTime', or use callable.",
)
@Mapper()
abstract class CrStampsAdviceMapper {
  CrStamps fromMap(Map<String, List<int>> map);
}
