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

// Golden test source for the review findings of the class -> Map mapping
// that are reported as errors.

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

class CrDoc {
  final String name;
  final int age;

  const CrDoc({required this.name, required this.age});
}

@ShouldThrow(
    "Ambiguous inherited configuration for method 'fromRealtime': multiple methods are candidates (toFirestore, toRealtime).\n"
    "Fix: Declare the parameter and return types of 'fromRealtime' exactly like the ones of the method to inherit from, or keep a single candidate.")
@Mapper()
abstract class CrAmbiguousInheritMapper {
  @Mapping(target: 'full_name', source: 'name')
  Map<String, dynamic> toFirestore(CrDoc dto);

  @Mapping(target: 'n', source: 'name')
  Map<String, Object?> toRealtime(CrDoc dto);

  @InheritInverseConfiguration()
  CrDoc fromRealtime(Map map);
}

class CrSecret {
  final String name;

  CrSecret({required this.name, required String secret});
}

@ShouldThrow(
    "Constructor parameter 'secret' of 'CrSecret' has no readable getter, so it cannot be read to build the map.\n"
    "Fix: Expose a public getter named 'secret', or skip it with @Mapping(target: 'secret', ignore: true), or provide its value with a constant, an expression or a callable.")
@Mapper()
abstract class CrSecretMapper {
  Map<String, dynamic> toMap(CrSecret dto);
}

String crUpper(String value) => value.toUpperCase();

@ShouldThrow(
    "Invalid @Mapping combination for target 'name': conditionExpression cannot be combined with callable.\n"
    "The following combinations are not allowed: constant+source, constant+defaultValue, constant+callable, defaultValue+callable.\n"
    "Fix: Use only one of: source, defaultValue, constant, or callable per target field.")
@Mapper()
abstract class CrCallableConditionMapper {
  @Mapping(target: 'name', callable: crUpper)
  @Mapping(target: 'name', conditionExpression: 'name != null')
  Map<String, dynamic> toMap(CrDoc dto);
}

@ShouldThrow(
    "Invalid @Mapping combination for target 'name': defaultValue cannot be combined with callable.\n"
    "The following combinations are not allowed: constant+source, constant+defaultValue, constant+callable, defaultValue+callable.\n"
    "Fix: Use only one of: source, defaultValue, constant, or callable per target field.")
@Mapper()
abstract class CrCallableDefaultMapper {
  @Mapping(target: 'name', callable: crUpper)
  @Mapping(target: 'name', defaultValue: 'x')
  Map<String, dynamic> toMap(CrDoc dto);
}

class CrAddress {
  final String street;
  final String city;

  const CrAddress({required this.street, required this.city});
}

@ShouldThrow(
    "Field 'address' of type 'Map<String, dynamic>' is not compatible with the value type 'String' of 'Map<String, String>'.\n"
    "Fix: Change the map value type (for instance to Object? or dynamic), provide a converter method, use a 'callable', or ignore the field with @Mapping(target: 'address', ignore: true).")
@Mapper()
abstract class CrTypedDotMapper {
  @Mapping(target: 'address.street', source: 'street')
  @Mapping(target: 'address.city', source: 'city')
  Map<String, String> toMap(CrAddress dto);
}

@ShouldThrow("Method 'convert' maps a Map to a Map, which is not supported.\n"
    "Fix: Implement the conversion by hand and reference it with 'callable' in @Mapping, or map through a class (Map -> class -> Map).")
@Mapper()
abstract class CrIntMapToMapMapper {
  Map<int, int> convert(Map<int, int> source);
}

@ShouldThrow("Method 'convert' maps a Map to a Map, which is not supported.\n"
    "Fix: Implement the conversion by hand and reference it with 'callable' in @Mapping, or map through a class (Map -> class -> Map).")
@Mapper()
abstract class CrIntKeyedToStringMapper {
  Map<String, int> convert(Map<int, int> source);
}
