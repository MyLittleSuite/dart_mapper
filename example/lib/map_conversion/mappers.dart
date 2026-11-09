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

import 'package:dart_mapper/dart_mapper.dart';
import 'package:dart_mapper_example/map_conversion/built_profile.dart';
import 'package:dart_mapper_example/map_conversion/converters.dart';
import 'package:dart_mapper_example/map_conversion/dtos.dart';
import 'package:dart_mapper_example/map_conversion/plain_models.dart';

part 'mappers.g.dart';

/// Firestore-style mapper: the document is a `Map<String, dynamic>`.
///
/// `fromFirestore` reuses the renames of `toFirestore` in reverse.
@Mapper()
abstract class UserDTOMapper {
  const UserDTOMapper();

  @Mapping(source: 'id', target: 'uid')
  @Mapping(source: 'verified', target: 'emailVerified')
  Map<String, dynamic> toFirestore(UserDTO dto);

  @InheritInverseConfiguration()
  UserDTO fromFirestore(Map<String, dynamic> map);
}

/// Realtime-Database-style mapper: reads come back as a raw `Map`, and the
/// node key (`id`) is passed separately from the node value.
///
/// `DateTime` fields are converted by [DateTimeMillisConverter].
@Mapper(uses: {DateTimeMillisConverter})
abstract class RealtimeMapper {
  const RealtimeMapper();

  /// `id` is the node key, so it is not written inside the value.
  @Mapping(target: 'id', ignore: true)
  Map<String, dynamic> toRealtime(RoomDTO room);

  /// Multi-source: `id` is resolved from the [id] parameter first, every
  /// other field is read from the [map].
  RoomDTO fromRealtime(Map map, String id);

  /// Used for the nested `session` field of a room.
  ///
  /// Realtime Database drops empty collections, so `votes` and `tags` fall
  /// back to an empty collection when the key is missing.
  @Mapping(target: 'votes', defaultValue: 'const {}')
  @Mapping(target: 'tags', defaultValue: 'const []')
  SessionDTO fromRealtimeSession(Map map);

  Map<String, dynamic> toRealtimeSession(SessionDTO session);
}

/// Target dot notation: targets sharing a prefix are grouped into a nested
/// map, producing `{'name': ..., 'address': {'street': ..., 'city': ...}}`.
@Mapper()
abstract class ContactMapMapper {
  const ContactMapMapper();

  @Mapping(source: 'street', target: 'address.street')
  @Mapping(source: 'city', target: 'address.city')
  Map<String, dynamic> toMap(Contact contact);

  /// Source dot notation walks the nested map (every level is nullable).
  @Mapping(source: 'address.street', target: 'street')
  @Mapping(source: 'address.city', target: 'city')
  Contact fromMap(Map<String, dynamic> map);
}

/// Target dot notation also builds nested objects: the flat `street` and
/// `city` are used to instantiate the `address` of the target.
@Mapper()
abstract class StructuredContactMapper {
  const StructuredContactMapper();

  /// class -> class
  @Mapping(source: 'street', target: 'address.street')
  @Mapping(source: 'city', target: 'address.city')
  StructuredContact fromContact(Contact contact);

  /// Map -> class: the keys of the map are flat.
  @Mapping(source: 'street', target: 'address.street')
  @Mapping(source: 'city', target: 'address.city')
  StructuredContact fromMap(Map<String, dynamic> map);
}

/// A built_value model mapped to and from a map.
@Mapper()
abstract class ProfileMapMapper {
  const ProfileMapMapper();

  Map<String, dynamic> toMap(Profile profile);

  Profile fromMap(Map<String, dynamic> map);
}

/// A plain class mapped to and from a map.
@Mapper()
abstract class ProductMapMapper {
  const ProductMapMapper();

  Map<String, dynamic> toMap(Product product);

  Product fromMap(Map<String, dynamic> map);
}
