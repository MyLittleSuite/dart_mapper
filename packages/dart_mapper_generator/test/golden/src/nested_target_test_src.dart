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

import 'nested_target_models.dart' hide NtvHiddenAddress;

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

class NtDefaultAddress {
  final String street;
  final String city;

  const NtDefaultAddress({required this.street, this.city = 'n/a'});
}

class NtDefaultContact {
  final String name;
  final NtDefaultAddress address;

  const NtDefaultContact({required this.name, required this.address});
}

class NtSlotAddress {
  final String street;
  final String city;
  final String? zip;

  const NtSlotAddress(this.street, [this.city = 'n/a', this.zip]);
}

class NtSlotContact {
  final String name;
  final NtSlotAddress address;

  const NtSlotContact({required this.name, required this.address});
}

/// A nested class with a constructor that is private, but reachable from the
/// library of the mapper.
class NtOwnPrivateAddress {
  final String street;

  const NtOwnPrivateAddress._(this.street);
}

class NtOwnPrivateContact {
  final String name;
  final NtOwnPrivateAddress address;

  const NtOwnPrivateContact({required this.name, required this.address});
}

/// A source with no `city`.
class NtStreetOnly {
  final String name;
  final String street;

  const NtStreetOnly({required this.name, required this.street});
}

class NtNullableCityAddress {
  final String street;
  final String? city;

  const NtNullableCityAddress({required this.street, required this.city});
}

class NtNullableCityContact {
  final String name;
  final NtNullableCityAddress address;

  const NtNullableCityContact({required this.name, required this.address});
}

class NtZipDefaultAddress {
  final String street;
  final String? zip;

  const NtZipDefaultAddress({required this.street, this.zip = 'none'});
}

class NtZipDefaultContact {
  final String name;
  final NtZipDefaultAddress address;

  const NtZipDefaultContact({required this.name, required this.address});
}

class NtBox<T> {
  final T value;

  const NtBox(this.value);
}

class NtEnvelope<T> {
  final String name;
  final T value;

  const NtEnvelope({required this.name, required this.value});
}

/// `input` is not stored in a field of the same name.
class NtInputBox<T> {
  final T value;

  NtInputBox({required T input}) : value = input;
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
        street: (map['address'] as Map?)?['street'] as String? ?? 'n/a',
        geo: NtGeo(lat: (map['lat'] as num).toDouble(), lng: 0.0),
      ),
    );
  }
''',
  contains: true,
)
@Mapper()
abstract class NtMapDeepMapper {
  @Mapping(
    source: 'address.street',
    target: 'location.street',
    defaultValue: 'n/a',
  )
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

// A dotted target without a source reads the property named like its last
// segment, and keeps the other settings of the target.
@ShouldGenerate(
  r"""
  @override
  NtOptionalContact toContact(NtFlatContact flat) {
    return NtOptionalContact(
      name: flat.name,
      address: NtOptionalAddress(street: flat.street, zip: flat.zip ?? '0000'),
    );
  }
""",
  contains: true,
)
@Mapper()
abstract class NtClassImplicitSourceMapper {
  @Mapping(target: 'address.street')
  @Mapping(target: 'address.zip', defaultValue: '0000')
  NtOptionalContact toContact(NtFlatContact flat);
}

// Generic types are resolved while walking a source path.
@ShouldGenerate(
  r"""
  @override
  NtContact toContact(NtBox<NtFlatContact> box) {
    return NtContact(
      name: box.value.name,
      address: NtAddress(street: box.value.street, city: box.value.city),
    );
  }
""",
  contains: true,
)
@Mapper()
abstract class NtGenericSourceMapper {
  @Mapping(source: 'value.name', target: 'name')
  @Mapping(source: 'value.street', target: 'address.street')
  @Mapping(source: 'value.city', target: 'address.city')
  NtContact toContact(NtBox<NtFlatContact> box);
}

// ... and the type arguments of the target.
@ShouldGenerate(
  r"""
  @override
  NtEnvelope<NtAddress> toEnvelope(NtFlatContact flat) {
    return NtEnvelope(
      name: flat.name,
      value: NtAddress(street: flat.street, city: flat.city),
    );
  }

  @override
  NtEnvelope<NtAddress> fromMap(Map<String, dynamic> map) {
    return NtEnvelope(
      name: map['name'] as String,
      value: NtAddress(
        street: map['street'] as String,
        city: map['city'] as String,
      ),
    );
  }
""",
  contains: true,
)
@Mapper()
abstract class NtGenericTargetMapper {
  @Mapping(source: 'street', target: 'value.street')
  @Mapping(source: 'city', target: 'value.city')
  NtEnvelope<NtAddress> toEnvelope(NtFlatContact flat);

  @Mapping(source: 'street', target: 'value.street')
  @Mapping(source: 'city', target: 'value.city')
  NtEnvelope<NtAddress> fromMap(Map<String, dynamic> map);
}

// Constructor parameters are resolved even without a getter of the same name.
@ShouldGenerate(
  r"""
  @override
  NtInputBox<NtAddress> toBox(NtFlatContact flat) {
    return NtInputBox(
      input: NtAddress(street: flat.street, city: flat.city),
    );
  }

  @override
  NtInputBox<NtAddress> fromMap(Map<String, dynamic> map) {
    return NtInputBox(
      input: NtAddress(
        street: map['street'] as String,
        city: map['city'] as String,
      ),
    );
  }
""",
  contains: true,
)
@Mapper()
abstract class NtInputParameterMapper {
  @Mapping(source: 'street', target: 'input.street')
  @Mapping(source: 'city', target: 'input.city')
  NtInputBox<NtAddress> toBox(NtFlatContact flat);

  @Mapping(source: 'street', target: 'input.street')
  @Mapping(source: 'city', target: 'input.city')
  NtInputBox<NtAddress> fromMap(Map<String, dynamic> map);
}

// A target mentioned without any other setting reads the key named like its
// last segment.
@ShouldGenerate(
  r"""
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
""",
  contains: true,
)
@Mapper()
abstract class NtMapTargetOnlyMapper {
  @Mapping(target: 'address.street')
  @Mapping(target: 'address.city')
  NtContact fromMap(Map<String, dynamic> map);
}

// An ignored optional property keeps its default value.
@ShouldGenerate(
  r"""
  @override
  NtDefaultContact toContact(NtFlatContact flat) {
    return NtDefaultContact(
      name: flat.name,
      address: NtDefaultAddress(street: flat.street),
    );
  }
""",
  contains: true,
)
@Mapper()
abstract class NtClassIgnoredOptionalMapper {
  @Mapping(source: 'street', target: 'address.street')
  @Mapping(target: 'address.city', ignore: true)
  NtDefaultContact toContact(NtFlatContact flat);
}

// An optional positional parameter that is skipped keeps its default value
// when a later one is passed.
@ShouldGenerate(
  r"""
  @override
  NtSlotContact toContact(NtFlatContact flat) {
    return NtSlotContact(
      name: flat.name,
      address: NtSlotAddress(flat.street, 'n/a', flat.zip),
    );
  }
""",
  contains: true,
)
@Mapper()
abstract class NtClassPositionalSlotMapper {
  @Mapping(source: 'street', target: 'address.street')
  @Mapping(source: 'zip', target: 'address.zip')
  NtSlotContact toContact(NtFlatContact flat);
}

// A private constructor can be called from the library declaring it.
@ShouldGenerate(
  r"""
  @override
  NtOwnPrivateContact toContact(NtFlatContact flat) {
    return NtOwnPrivateContact(
      name: flat.name,
      address: NtOwnPrivateAddress._(flat.street),
    );
  }
""",
  contains: true,
)
@Mapper()
abstract class NtOwnPrivateConstructorMapper {
  @Mapping(source: 'street', target: 'address.street')
  NtOwnPrivateContact toContact(NtFlatContact flat);
}

// An ignored nested property that no source property feeds is set to null
// when it is required and nullable.
@ShouldGenerate(
  r"""
  @override
  NtNullableCityContact toContact(NtStreetOnly source) {
    return NtNullableCityContact(
      name: source.name,
      address: NtNullableCityAddress(street: source.street, city: null),
    );
  }
""",
  contains: true,
)
@Mapper()
abstract class NtIgnoredNullableMapper {
  @Mapping(source: 'street', target: 'address.street')
  @Mapping(target: 'address.city', ignore: true)
  NtNullableCityContact toContact(NtStreetOnly source);
}

// An ignored property with a nullable source is left out when the parameter
// has a default value to keep.
@ShouldGenerate(
  r"""
  @override
  NtZipDefaultContact toContact(NtFlatContact flat) {
    return NtZipDefaultContact(
      name: flat.name,
      address: NtZipDefaultAddress(street: flat.street),
    );
  }
""",
  contains: true,
)
@Mapper()
abstract class NtIgnoredDefaultMapper {
  @Mapping(source: 'street', target: 'address.street')
  @Mapping(target: 'address.zip', ignore: true)
  NtZipDefaultContact toContact(NtFlatContact flat);
}

// The default of a skipped positional parameter is written as a value, even
// when it is a private constant of another library.
@ShouldGenerate(
  r"""
  @override
  NtvSlotContact toContact(NtFlatContact flat) {
    return NtvSlotContact(
      name: flat.name,
      address: NtvSlotAddress(flat.street, 'n/a', flat.zip),
    );
  }
""",
  contains: true,
)
@Mapper()
abstract class NtForeignDefaultSlotMapper {
  @Mapping(source: 'street', target: 'address.street')
  @Mapping(source: 'zip', target: 'address.zip')
  NtvSlotContact toContact(NtFlatContact flat);
}

// A skipped positional parameter defaulting to a non-finite double is written
// as a Dart expression, not as `Infinity` / `NaN`.
@ShouldGenerate(
  r"""
  @override
  NtvNonFiniteContact toContact(NtFlatContact flat) {
    return NtvNonFiniteContact(
      name: flat.name,
      address: NtvNonFiniteAddress(
        flat.street,
        double.infinity,
        double.negativeInfinity,
        double.nan,
        flat.zip,
      ),
    );
  }
""",
  contains: true,
)
@Mapper()
abstract class NtNonFiniteDefaultSlotMapper {
  @Mapping(source: 'street', target: 'address.street')
  @Mapping(source: 'zip', target: 'address.zip')
  NtvNonFiniteContact toContact(NtFlatContact flat);
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
  "No relation found for required field 'address.city' in 'NtMissingPropertyMapper.toContact'.\n"
  "Fix: Add @Mapping(target: 'address.city', source: 'sourceField') to map from a differently named source field, or @Mapping(target: 'address.city', ignore: true) to skip it.",
)
@Mapper()
abstract class NtMissingPropertyMapper {
  @Mapping(source: 'street', target: 'address.street')
  NtContact toContact(NtFlatContact flat);
}


// A configured nested object is built even when none of its properties could
// be bound, so the properties it is missing are reported.
@ShouldThrow(
  "No relation found for required field 'address.street' in 'NtNoSourceMapper.toContact'.\n"
  "Fix: Add @Mapping(target: 'address.street', source: 'sourceField') to map from a differently named source field, or @Mapping(target: 'address.street', ignore: true) to skip it.",
)
@Mapper()
abstract class NtNoSourceMapper {
  @Mapping(source: 'nope', target: 'address.street')
  NtOptionalContact toContact(NtFlatContact flat);
}

// Invalid target-only paths are validated as well.
@ShouldThrow(
  "Invalid @Mapping target 'address.country': 'country' is not a constructor parameter of 'NtAddress' (available: street, city).\n"
  "Fix: A dotted target builds a nested object of the target class: every segment must be non-empty, name a constructor parameter of a class that can be instantiated, and the nested object cannot also be mapped as a whole value.",
)
@Mapper()
abstract class NtMapTargetOnlyUnknownMapper {
  @Mapping(target: 'address.country')
  NtContact fromMap(Map<String, dynamic> map);
}

@ShouldThrow(
  "Invalid @Mapping target 'address': the constructor 'NtvPrivateAddress._' of 'NtvPrivateAddress' is private to its library, so the mapper cannot call it.\n"
  "Fix: Expose a public constructor on the nested class, or build the value with callable.",
)
@Mapper()
abstract class NtPrivateConstructorMapper {
  @Mapping(source: 'street', target: 'address.street')
  NtvPrivateContact toContact(NtFlatContact flat);
}

@ShouldThrow(
  "Invalid @Mapping target 'address': 'NtvHiddenAddress' is not imported by the mapper's library, so the generated code cannot name it.\n"
  "Fix: Import the library declaring 'NtvHiddenAddress' in the file of the mapper (and do not hide it).",
)
@Mapper()
abstract class NtHiddenClassMapper {
  @Mapping(source: 'street', target: 'address.street')
  NtvHiddenContact fromMap(Map<String, dynamic> map);
}


// A default that is not a literal cannot be copied into the generated code.
@ShouldThrow(
  "Cannot skip the optional positional parameter 'address.tag' of 'NtvObjectSlotAddress' in 'NtObjectDefaultSlotMapper.toContact': a later parameter is mapped and its default value 'const NtvTag()' cannot be copied into the generated code.\n"
  "Fix: Map 'address.tag' explicitly with @Mapping(target: 'address.tag', source: ..., constant: ... or expression: ...).",
)
@Mapper()
abstract class NtObjectDefaultSlotMapper {
  @Mapping(source: 'street', target: 'address.street')
  @Mapping(source: 'zip', target: 'address.zip')
  NtvObjectSlotContact toContact(NtFlatContact flat);
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
