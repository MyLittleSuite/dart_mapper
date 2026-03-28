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

// Golden test source for SRC-01 and SRC-02:
// SRC-01: multi-source mapping with unique field names resolves from all params
// SRC-02: qualified source (paramName.fieldName) resolves correct param when ambiguous

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

// ----- SRC-01: Two-source method with unique fields -----

class UserInfo {
  final String name;
  final int age;

  const UserInfo({required this.name, required this.age});
}

class AddressInfo {
  final String street;
  final String city;

  const AddressInfo({required this.street, required this.city});
}

class UserProfile {
  final String name;
  final int age;
  final String street;
  final String city;

  const UserProfile({
    required this.name,
    required this.age,
    required this.street,
    required this.city,
  });
}

@ShouldGenerate(
  r'''UserProfile merge(UserInfo user, AddressInfo address) {
    return UserProfile(
      name: user.name,
      age: user.age,
      street: address.street,
      city: address.city,
    );
  }''',
  contains: true,
)
@Mapper()
abstract class MultiSourceMapper {
  UserProfile merge(UserInfo user, AddressInfo address);
}

// ----- SRC-02: Two sources with shared field name, explicit qualification -----

class NameSource1 {
  final String name;

  const NameSource1({required this.name});
}

class NameSource2 {
  final String name;

  const NameSource2({required this.name});
}

class CombinedTarget {
  final String userName;
  final String companyName;

  const CombinedTarget({required this.userName, required this.companyName});
}

@ShouldGenerate(
  r'''CombinedTarget combine(NameSource1 user, NameSource2 company) {
    return CombinedTarget(userName: user.name, companyName: company.name);
  }''',
  contains: true,
)
@Mapper()
abstract class QualifiedSourceMapper {
  @Mapping(target: 'userName', source: 'user.name')
  @Mapping(target: 'companyName', source: 'company.name')
  CombinedTarget combine(NameSource1 user, NameSource2 company);
}
