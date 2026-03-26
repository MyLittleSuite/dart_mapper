/*
 * Copyright (c) 2024 MyLittleSuite
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

// Golden test source for freezed-like class mapping.
//
// Since source_gen_test cannot run the freezed generator first, these
// classes simulate freezed-like shapes: immutable classes with named
// constructor parameters (which is how the mapper generator sees
// freezed classes). The generator treats these as MappingBehavior.standard
// because the @freezed annotation and supertypes are not present.
//
// This test verifies the generator correctly handles classes with
// factory-constructor-like shapes (all named parameters), which is the
// pattern freezed produces.

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

// Tests mapper behavior with freezed-like class shapes.
// These classes use named parameters in constructors, mirroring what
// freezed generates (e.g., User({required String name, required String password})).

class FreezedLikeUser {
  final String name;
  final String password;

  const FreezedLikeUser({
    required this.name,
    required this.password,
  });
}

class FreezedLikeUserDTO {
  final String name;
  final String password;

  const FreezedLikeUserDTO({
    required this.name,
    required this.password,
  });
}

class FreezedLikeCredentials {
  final String username;
  final String token;

  const FreezedLikeCredentials({
    required this.username,
    required this.token,
  });
}

class FreezedLikeAnonCredentials {
  const FreezedLikeAnonCredentials();
}

@ShouldGenerate(
  r'''FreezedLikeUserDTO toUserDTO(FreezedLikeUser user)''',
  contains: true,
)
@ShouldGenerate(
  r'''return FreezedLikeUserDTO(name: user.name, password: user.password);''',
  contains: true,
)
@ShouldGenerate(
  r'''return FreezedLikeUser(name: userDTO.name, password: userDTO.password);''',
  contains: true,
)
@ShouldGenerate(
  r'''return FreezedLikeAnonCredentials();''',
  contains: true,
)
@Mapper()
abstract class FreezedLikeMapper {
  FreezedLikeUserDTO toUserDTO(FreezedLikeUser user);

  FreezedLikeUser toUser(FreezedLikeUserDTO userDTO);

  FreezedLikeAnonCredentials toAnonCredentials(
      FreezedLikeCredentials credentials);
}
