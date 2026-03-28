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

// Golden test source for SRC-03 and SRC-04:
// SRC-03: dot notation @Mapping(source: 'address.street') traverses nested properties
// SRC-04: nullable intermediate generates ?. access

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

// ----- Shared models -----

class Street {
  final String name;
  final String zip;

  const Street({required this.name, required this.zip});
}

class Address {
  final String city;
  final Street street;

  const Address({required this.city, required this.street});
}

class NullableAddress {
  final String city;
  final Street? street;

  const NullableAddress({required this.city, this.street});
}

class Person {
  final String fullName;
  final Address address;

  const Person({required this.fullName, required this.address});
}

class NullablePerson {
  final String fullName;
  final NullableAddress? address;

  const NullablePerson({required this.fullName, this.address});
}

class FlatPerson {
  final String fullName;
  final String city;

  const FlatPerson({required this.fullName, required this.city});
}

class FlatPersonStreet {
  final String fullName;
  final String? streetName;

  const FlatPersonStreet({required this.fullName, this.streetName});
}

class FlatPersonDeep {
  final String fullName;
  final String? streetZip;

  const FlatPersonDeep({required this.fullName, this.streetZip});
}

// ----- SRC-03: Basic dot notation (non-nullable intermediate) -----

@ShouldGenerate(
  r'''FlatPerson flatten(Person source) {
    return FlatPerson(fullName: source.fullName, city: source.address.city);
  }''',
  contains: true,
)
@Mapper()
abstract class DotNotationMapper {
  @Mapping(target: 'city', source: 'address.city')
  FlatPerson flatten(Person source);
}

// ----- SRC-04: Nullable intermediate generates ?. access -----

@ShouldGenerate(
  r'''FlatPersonStreet flattenNullable(NullablePerson source) {
    return FlatPersonStreet(
      fullName: source.fullName,
      streetName: source.address?.street?.name,
    );
  }''',
  contains: true,
)
@Mapper()
abstract class NullableDotNotationMapper {
  @Mapping(target: 'streetName', source: 'address.street.name')
  FlatPersonStreet flattenNullable(NullablePerson source);
}

// ----- Deep nesting: three levels (a.b.c) -----

@ShouldGenerate(
  r'''FlatPersonDeep flattenDeep(NullablePerson source) {
    return FlatPersonDeep(
      fullName: source.fullName,
      streetZip: source.address?.street?.zip,
    );
  }''',
  contains: true,
)
@Mapper()
abstract class DeepDotNotationMapper {
  @Mapping(target: 'streetZip', source: 'address.street.zip')
  FlatPersonDeep flattenDeep(NullablePerson source);
}

// ----- Fix 1: callable on nullable dot-path does not throw -----

String _upperCase(String? value) => value?.toUpperCase() ?? '';

class NullableStreetPerson {
  final String fullName;
  final NullableAddress? address;

  const NullableStreetPerson({required this.fullName, this.address});
}

class FlatCallableTarget {
  final String fullName;
  final String streetName;

  const FlatCallableTarget({required this.fullName, required this.streetName});
}

@ShouldGenerate(
  r'''FlatCallableTarget flattenCallable(NullableStreetPerson source) {
    return FlatCallableTarget(
      fullName: source.fullName,
      streetName: _upperCase(source.address?.street?.name),
    );
  }''',
  contains: true,
)
@Mapper()
abstract class CallableNullableDotNotationMapper {
  @Mapping(target: 'streetName', source: 'address.street.name', callable: _upperCase)
  FlatCallableTarget flattenCallable(NullableStreetPerson source);
}
