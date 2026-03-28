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

// Golden test source for DEF-01 and DEF-02:
// DEF-01: defaultValue generates ?? fallback expression
// DEF-02: constant generates literal value with no source reference

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

// ----- DEF-01: defaultValue generates ?? fallback -----

class UserInput {
  final String? status;

  const UserInput({this.status});
}

class UserOutput {
  final String status;

  const UserOutput({required this.status});
}

@ShouldGenerate(
  r'''UserOutput toOutput(UserInput source) {
    return UserOutput(status: source.status ?? 'active');
  }''',
  contains: true,
)
@Mapper()
abstract class DefaultValueMapper {
  @Mapping(target: "status", defaultValue: "active")
  UserOutput toOutput(UserInput source);
}

// ----- DEF-02: constant generates literal, no source reference -----

class VersionInput {
  final String name;

  const VersionInput({required this.name});
}

class VersionOutput {
  final String name;
  final String version;

  const VersionOutput({required this.name, required this.version});
}

@ShouldGenerate(
  r'''VersionOutput toOutput(VersionInput source) {
    return VersionOutput(name: source.name, version: '1.0');
  }''',
  contains: true,
)
@Mapper()
abstract class ConstantMapper {
  @Mapping(target: "version", constant: "1.0")
  VersionOutput toOutput(VersionInput source);
}

// ----- defaultValue with dot notation combo -----

class ContactAddress {
  final String? city;

  const ContactAddress({this.city});
}

class Contact {
  final String name;
  final ContactAddress? address;

  const Contact({required this.name, this.address});
}

class FlatContact {
  final String name;
  final String city;

  const FlatContact({required this.name, required this.city});
}

@ShouldGenerate(
  r'''FlatContact flatten(Contact source) {
    return FlatContact(
      name: source.name,
      city: source.address?.city ?? 'unknown',
    );
  }''',
  contains: true,
)
@Mapper()
abstract class DotNotationDefaultMapper {
  @Mapping(target: "city", source: "address.city", defaultValue: "unknown")
  FlatContact flatten(Contact source);
}

// ----- Bool literal constant -----

class FlagInput {
  final String name;

  const FlagInput({required this.name});
}

class FlagOutput {
  final String name;
  final bool active;

  const FlagOutput({required this.name, required this.active});
}

@ShouldGenerate(
  r'''FlagOutput toOutput(FlagInput source) {
    return FlagOutput(name: source.name, active: true);
  }''',
  contains: true,
)
@Mapper()
abstract class BoolConstantMapper {
  @Mapping(target: 'active', constant: 'true')
  FlagOutput toOutput(FlagInput source);
}
