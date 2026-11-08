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

// Golden test source for target dot notation (issue #118): a dotted
// @Mapping(target: 'address.street') builds a nested target object, in
// class -> class and Map -> class mappings.

// ignore_for_file: depend_on_referenced_packages

import 'package:built_value/built_value.dart';
import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

// ----- Shared models -----

class NtFlatContact {
  final String name;
  final String street;
  final String city;
  final String? zip;

  const NtFlatContact({
    required this.name,
    required this.street,
    required this.city,
    this.zip,
  });
}

class NtAddress {
  final String street;
  final String city;

  const NtAddress({required this.street, required this.city});
}

class NtContact {
  final String name;
  final NtAddress address;

  const NtContact({required this.name, required this.address});
}

class NtOptionalAddress {
  final String street;
  final String? zip;

  const NtOptionalAddress({required this.street, this.zip});
}

class NtOptionalContact {
  final String name;
  final NtOptionalAddress? address;

  const NtOptionalContact({required this.name, this.address});
}

class NtGeo {
  final double lat;
  final double lng;

  const NtGeo({required this.lat, required this.lng});
}

class NtLocation {
  final String street;
  final NtGeo geo;

  const NtLocation({required this.street, required this.geo});
}

class NtPlace {
  final String name;
  final NtLocation location;

  const NtPlace({required this.name, required this.location});
}

class NtFlatPlace {
  final String name;
  final String street;
  final double lat;
  final double lng;

  const NtFlatPlace({
    required this.name,
    required this.street,
    required this.lat,
    required this.lng,
  });
}

class NtPositionalAddress {
  final String street;
  final String city;

  const NtPositionalAddress(this.street, this.city);
}

class NtPositionalContact {
  final String name;
  final NtPositionalAddress address;

  const NtPositionalContact(this.name, this.address);
}

class NtPerson {
  final String firstName;
  final String lastName;
  final String? zip;

  const NtPerson({required this.firstName, required this.lastName, this.zip});
}

// ----- class -> class -----

@ShouldGenerate(
  r'''
  @override
  NtContact toContact(NtFlatContact flat) {
    return NtContact(
      name: flat.name,
      address: NtAddress(street: flat.street, city: flat.city),
    );
  }
''',
  contains: true,
)
@Mapper()
abstract class NtClassMapper {
  @Mapping(source: 'street', target: 'address.street')
  @Mapping(source: 'city', target: 'address.city')
  NtContact toContact(NtFlatContact flat);
}

// Nested properties can come from dotted sources, constants and expressions.
@ShouldGenerate(
  r'''
  @override
  NtContact toContact(NtFlatContact flat) {
    return NtContact(
      name: flat.name,
      address: NtAddress(street: flat.street, city: 'Rome'),
    );
  }
''',
  contains: true,
)
@Mapper()
abstract class NtClassConstantMapper {
  @Mapping(source: 'street', target: 'address.street')
  @Mapping(constant: 'Rome', target: 'address.city')
  NtContact toContact(NtFlatContact flat);
}

@ShouldGenerate(
  r'''
  @override
  NtContact toContact(NtFlatContact flat) {
    return NtContact(
      name: flat.name,
      address: NtAddress(
        street: flat.street.toUpperCase(),
        city: '${flat.city}!',
      ),
    );
  }
''',
  contains: true,
)
@Mapper()
abstract class NtClassExpressionMapper {
  @Mapping(expression: 'flat.street.toUpperCase()', target: 'address.street')
  @Mapping(expression: r'${flat.city}!', target: 'address.city')
  NtContact toContact(NtFlatContact flat);
}

// Two levels of nesting, with a dotted source feeding a nested target.
@ShouldGenerate(
  r'''
  @override
  NtPlace toPlace(NtFlatPlace flat) {
    return NtPlace(
      name: flat.name,
      location: NtLocation(
        street: flat.street,
        geo: NtGeo(lat: flat.lat, lng: flat.lng),
      ),
    );
  }
''',
  contains: true,
)
@Mapper()
abstract class NtClassDeepMapper {
  @Mapping(source: 'street', target: 'location.street')
  @Mapping(source: 'lat', target: 'location.geo.lat')
  @Mapping(source: 'lng', target: 'location.geo.lng')
  NtPlace toPlace(NtFlatPlace flat);
}

// Optional properties of the nested object that are not mapped are left out,
// and a nullable nested object is built as well.
@ShouldGenerate(
  r'''
  @override
  NtOptionalContact toContact(NtFlatContact flat) {
    return NtOptionalContact(
      name: flat.name,
      address: NtOptionalAddress(street: flat.street),
    );
  }
''',
  contains: true,
)
@Mapper()
abstract class NtClassOptionalMapper {
  @Mapping(source: 'street', target: 'address.street')
  NtOptionalContact toContact(NtFlatContact flat);
}

@ShouldGenerate(
  r'''
  @override
  NtOptionalContact toContact(NtFlatContact flat) {
    return NtOptionalContact(
      name: flat.name,
      address: NtOptionalAddress(street: flat.street, zip: flat.zip),
    );
  }
''',
  contains: true,
)
@Mapper()
abstract class NtClassOptionalZipMapper {
  @Mapping(source: 'street', target: 'address.street')
  @Mapping(source: 'zip', target: 'address.zip')
  NtOptionalContact toContact(NtFlatContact flat);
}

@ShouldGenerate(
  r'''
  @override
  NtPositionalContact toContact(NtFlatContact flat) {
    return NtPositionalContact(
      flat.name,
      NtPositionalAddress(flat.street, flat.city),
    );
  }
''',
  contains: true,
)
@Mapper()
abstract class NtClassPositionalMapper {
  @Mapping(source: 'street', target: 'address.street')
  @Mapping(source: 'city', target: 'address.city')
  NtPositionalContact toContact(NtFlatContact flat);
}

// The inverse of a flattening mapping builds the nested object.
@ShouldGenerate(
  r'''
  @override
  NtFlatContact flatten(NtContact contact) {
    return NtFlatContact(
      name: contact.name,
      street: contact.address.street,
      city: contact.address.city,
    );
  }

  @override
  NtContact unflatten(NtFlatContact flat) {
    return NtContact(
      name: flat.name,
      address: NtAddress(street: flat.street, city: flat.city),
    );
  }
''',
  contains: true,
)
@Mapper()
abstract class NtClassInverseMapper {
  @Mapping(source: 'address.street', target: 'street')
  @Mapping(source: 'address.city', target: 'city')
  NtFlatContact flatten(NtContact contact);

  @InheritInverseConfiguration()
  NtContact unflatten(NtFlatContact flat);
}

// ----- Map -> class -----

@ShouldGenerate(
  r'''
  @override
  NtContact fromMap(Map<String, dynamic> map) {
    return NtContact(
      name: map['name'] as String,
      address: NtAddress(
        street: map['street'] as String,
        city: map['city'] as String,
      ),
    );
  }
''',
  contains: true,
)
@Mapper()
abstract class NtMapMapper {
  @Mapping(source: 'street', target: 'address.street')
  @Mapping(source: 'city', target: 'address.city')
  NtContact fromMap(Map<String, dynamic> map);
}

// Nested values keep every Map -> class feature: dot notation sources,
// defaults and constants.
@ShouldGenerate(
  r'''
  @override
  NtPlace fromMap(Map<String, dynamic> map) {
    return NtPlace(
      name: map['name'] as String,
      location: NtLocation(
        street: (map['address'] as Map?)?['street'] as String,
        geo: NtGeo(lat: (map['lat'] as num).toDouble(), lng: 0.0),
      ),
    );
  }
''',
  contains: true,
)
@Mapper()
abstract class NtMapDeepMapper {
  @Mapping(source: 'address.street', target: 'location.street')
  @Mapping(source: 'lat', target: 'location.geo.lat')
  @Mapping(constant: '0.0', target: 'location.geo.lng')
  NtPlace fromMap(Map<String, dynamic> map);
}

// The inverse of a class -> Map mapping reads the nested object back.
@ShouldGenerate(
  r'''
  @override
  NtContact fromMap(Map<String, dynamic> map) {
    return NtContact(
      name: map['name'] as String,
      address: NtAddress(
        street: map['street'] as String,
        city: map['city'] as String,
      ),
    );
  }
''',
  contains: true,
)
@Mapper()
abstract class NtMapInverseMapper {
  @Mapping(source: 'address.street', target: 'street')
  @Mapping(source: 'address.city', target: 'city')
  Map<String, dynamic> toMap(NtContact contact);

  @InheritInverseConfiguration()
  NtContact fromMap(Map<String, dynamic> map);
}

// A multi-source method resolves nested values from its parameters.
@ShouldGenerate(
  r'''
  @override
  NtContact fromMap(Map<String, dynamic> map, String city) {
    return NtContact(
      name: map['name'] as String,
      address: NtAddress(street: map['street'] as String, city: city),
    );
  }
''',
  contains: true,
)
@Mapper()
abstract class NtMapMultiSourceMapper {
  @Mapping(source: 'street', target: 'address.street')
  @Mapping(source: 'city', target: 'address.city')
  NtContact fromMap(Map<String, dynamic> map, String city);
}

// ----- Errors -----

@ShouldThrow(
  "Invalid @Mapping target 'address.country': 'country' is not a constructor parameter of 'NtAddress' (available: street, city).\n"
  "Fix: A dotted target builds a nested object of the target class: every segment must be non-empty, name a constructor parameter of a class that can be instantiated, and the nested object cannot also be mapped as a whole value.",
)
@Mapper()
abstract class NtUnknownPropertyMapper {
  @Mapping(source: 'street', target: 'address.country')
  NtContact toContact(NtFlatContact flat);
}

@ShouldThrow(
  "Invalid @Mapping target 'home.street': 'home' is not a constructor parameter of 'NtContact' (available: name, address).\n"
  "Fix: A dotted target builds a nested object of the target class: every segment must be non-empty, name a constructor parameter of a class that can be instantiated, and the nested object cannot also be mapped as a whole value.",
)
@Mapper()
abstract class NtUnknownRootMapper {
  @Mapping(source: 'street', target: 'home.street')
  NtContact fromMap(Map<String, dynamic> map);
}

@ShouldThrow(
  "Invalid @Mapping target 'name': 'name' is of type 'String', which is not a class that can be built from nested targets.\n"
  "Fix: A dotted target builds a nested object of the target class: every segment must be non-empty, name a constructor parameter of a class that can be instantiated, and the nested object cannot also be mapped as a whole value.",
)
@Mapper()
abstract class NtNotAClassMapper {
  @Mapping(source: 'street', target: 'name.first')
  NtContact toContact(NtFlatContact flat);
}

@ShouldThrow(
  "Invalid @Mapping target 'address': it is mapped as a whole value but it is also the prefix of nested targets.\n"
  "Fix: A dotted target builds a nested object of the target class: every segment must be non-empty, name a constructor parameter of a class that can be instantiated, and the nested object cannot also be mapped as a whole value.",
)
@Mapper()
abstract class NtWholeAndNestedMapper {
  @Mapping(source: 'street', target: 'address')
  @Mapping(source: 'street', target: 'address.street')
  NtContact fromMap(Map<String, dynamic> map);
}

@ShouldThrow(
  "Invalid @Mapping target 'address..street': it contains an empty segment.\n"
  "Fix: A dotted target builds a nested object of the target class: every segment must be non-empty, name a constructor parameter of a class that can be instantiated, and the nested object cannot also be mapped as a whole value.",
)
@Mapper()
abstract class NtEmptySegmentMapper {
  @Mapping(source: 'street', target: 'address..street')
  NtContact toContact(NtFlatContact flat);
}

// A required property of the nested object that is not mapped.
@ShouldThrow(
  "No relation found for required field 'city' in 'NtMissingPropertyMapper.toContact'.\n"
  "Fix: Add @Mapping(target: 'city', source: 'sourceField') to map from a differently named source field, or @Mapping(target: 'city', ignore: true) to skip it.",
)
@Mapper()
abstract class NtMissingPropertyMapper {
  @Mapping(source: 'street', target: 'address.street')
  NtContact toContact(NtFlatContact flat);
}

// ----- built_value targets -----

abstract class NtBuiltAddress
    implements Built<NtBuiltAddress, NtBuiltAddressBuilder> {
  String get street;
}

abstract class NtBuiltAddressBuilder
    implements Builder<NtBuiltAddress, NtBuiltAddressBuilder> {
  String? street;
}

abstract class NtBuiltContact
    implements Built<NtBuiltContact, NtBuiltContactBuilder> {
  String get name;

  NtBuiltAddress get address;
}

abstract class NtBuiltContactBuilder
    implements Builder<NtBuiltContact, NtBuiltContactBuilder> {
  String? name;

  NtBuiltAddressBuilder get address;
}

@ShouldThrow(
  "Invalid @Mapping target 'address.street': nested targets cannot build a built_value class.\n"
  "Fix: A dotted target builds a nested object of the target class: every segment must be non-empty, name a constructor parameter of a class that can be instantiated, and the nested object cannot also be mapped as a whole value.",
)
@Mapper()
abstract class NtMapToBuiltMapper {
  @Mapping(source: 'street', target: 'address.street')
  NtBuiltContact fromMap(Map<String, dynamic> map);
}

@ShouldThrow(
  "Invalid @Mapping target 'address.street': nested targets cannot build a built_value class.\n"
  "Fix: A dotted target builds a nested object of the target class: every segment must be non-empty, name a constructor parameter of a class that can be instantiated, and the nested object cannot also be mapped as a whole value.",
)
@Mapper()
abstract class NtClassToBuiltMapper {
  @Mapping(source: 'street', target: 'address.street')
  NtBuiltContact toContact(NtFlatContact flat);
}
