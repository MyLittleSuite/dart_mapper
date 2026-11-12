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

// Golden test source for the choice of the constructor that builds the target
// (issue #117): a constructor that the generated code cannot call is never
// picked, and the choice does not depend on the order of declaration.

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

import 'constructor_selection_models.dart';

class CsSource {
  final String name;

  const CsSource({required this.name});
}

abstract class CsOwnPrivateFactoryTarget {
  final String name;

  const CsOwnPrivateFactoryTarget(this.name);

  // ignore: unused_element
  const factory CsOwnPrivateFactoryTarget._(String name) =
      _CsOwnPrivateFactoryTarget;
}

class _CsOwnPrivateFactoryTarget extends CsOwnPrivateFactoryTarget {
  const _CsOwnPrivateFactoryTarget(super.name);
}

class CsFlatContact {
  final String name;
  final String street;

  const CsFlatContact({required this.name, required this.street});
}

class CsSourceAddress {
  final String street;

  const CsSourceAddress({required this.street});
}

class CsSourceContact {
  final String name;
  final CsSourceAddress address;

  const CsSourceContact({required this.name, required this.address});
}

/// A Freezed class without fields declared in the library of the mapper: the
/// private constructor can be called, but it is generative and the class is
/// abstract.
abstract class CsOwnFreezedTarget {
  const CsOwnFreezedTarget._();

  const factory CsOwnFreezedTarget() = _CsOwnFreezedTarget;
}

class _CsOwnFreezedTarget extends CsOwnFreezedTarget {
  const _CsOwnFreezedTarget() : super._();
}

/// A class whose only constructor is private, declared in the library of the
/// mapper, which can call it.
class CsOwnPrivateOnlyTarget {
  final String name;

  const CsOwnPrivateOnlyTarget._(this.name);
}

@ShouldGenerate(
  r'''
  @override
  CsvPlainTarget plain(CsSource source) {
    return CsvPlainTarget();
  }

  @override
  CsvFreezedTarget freezed(CsSource source) {
    return CsvFreezedTarget();
  }

  @override
  CsOwnFreezedTarget ownFreezed(CsSource source) {
    return CsOwnFreezedTarget();
  }

  @override
  CsvFieldTarget field(CsSource source) {
    return CsvFieldTarget(name: source.name);
  }

  @override
  CsvNamedFirstTarget namedFirst(CsSource source) {
    return CsvNamedFirstTarget(source.name);
  }

  @override
  CsOwnPrivateOnlyTarget ownPrivateOnly(CsSource source) {
    return CsOwnPrivateOnlyTarget._(source.name);
  }
''',
  contains: true,
)
@Mapper()
abstract class CsConstructorMapper {
  CsvPlainTarget plain(CsSource source);

  CsvFreezedTarget freezed(CsSource source);

  CsOwnFreezedTarget ownFreezed(CsSource source);

  CsvFieldTarget field(CsSource source);

  CsvNamedFirstTarget namedFirst(CsSource source);

  CsOwnPrivateOnlyTarget ownPrivateOnly(CsSource source);
}

@ShouldGenerate(
  r'''
  @override
  CsvContact toContact(CsSourceContact source) {
    return CsvContact(
      name: source.name,
      address: _mapCsSourceAddressToCsvAddress(source.address),
    );
  }

  CsvAddress _mapCsSourceAddressToCsvAddress(CsSourceAddress address) {
    return CsvAddress(street: address.street);
  }
''',
  contains: true,
)
@Mapper()
abstract class CsNestedMapper {
  CsvContact toContact(CsSourceContact source);
}

@ShouldGenerate(
  r'''
  @override
  CsvContact toContact(CsFlatContact flat) {
    return CsvContact(
      name: flat.name,
      address: CsvAddress(street: flat.street),
    );
  }
''',
  contains: true,
)
@Mapper()
abstract class CsDottedTargetMapper {
  @Mapping(source: 'street', target: 'address.street')
  CsvContact toContact(CsFlatContact flat);
}

@ShouldGenerate(
  r'''
  @override
  CsvFieldTarget fromMap(Map<String, dynamic> map) {
    return CsvFieldTarget(name: map['name'] as String);
  }
''',
  contains: true,
)
@Mapper()
abstract class CsFromMapMapper {
  CsvFieldTarget fromMap(Map<String, dynamic> map);
}

@ShouldThrow(
  "Cannot build 'CsvPrivateOnlyTarget': its constructor 'CsvPrivateOnlyTarget._' is private to its library, so the generated code cannot call it.\n"
  "Fix: Add a public constructor to 'CsvPrivateOnlyTarget'.",
)
@Mapper()
abstract class CsPrivateOnlyMapper {
  CsvPrivateOnlyTarget toTarget(CsSource source);
}

@ShouldThrow(
  "Cannot build 'CsvPrivateOnlyTarget': its constructor 'CsvPrivateOnlyTarget._' is private to its library, so the generated code cannot call it.\n"
  "Fix: Add a public constructor to 'CsvPrivateOnlyTarget'.",
)
@Mapper()
abstract class CsFromMapPrivateOnlyMapper {
  CsvPrivateOnlyTarget fromMap(Map<String, dynamic> map);
}

@ShouldGenerate(
  r'''
  @override
  CsOwnPrivateFactoryTarget toTarget(CsSource source) {
    return CsOwnPrivateFactoryTarget._(source.name);
  }
''',
  contains: true,
)
@Mapper()
abstract class CsOwnPrivateFactoryMapper {
  CsOwnPrivateFactoryTarget toTarget(CsSource source);
}
