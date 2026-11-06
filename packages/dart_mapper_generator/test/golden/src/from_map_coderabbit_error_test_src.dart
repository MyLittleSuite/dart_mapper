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
  "Fix: Add @Mapping(target: 'address', source: 'man.address') to specify which parameter to use.",
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
  "Fix: Declare the source map as Map<String, dynamic> (or Map<String, Object?>), declare a converter method from 'List<int>' to 'List<String>', or use callable.",
)
@Mapper()
abstract class CrElementMismatchMapper {
  CrStrings fromMap(Map<String, List<int>> map);
}
