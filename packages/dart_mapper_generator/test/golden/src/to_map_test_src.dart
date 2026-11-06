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

// Golden test source for class -> Map mapping (MappingBehavior.toMap).
//
// A method returning a Map<String, ...> and receiving classes as parameters
// produces a map literal in which every map key plays the role of a field.

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

// ----- Canonical example: renamed keys, null values always included -----

class UserDTO {
  final String id;
  final String? email;
  final String? displayName;
  final String? phoneNumber;
  final String? photoURL;
  final bool? verified;

  const UserDTO({
    required this.id,
    this.email,
    this.displayName,
    this.phoneNumber,
    this.photoURL,
    this.verified,
  });
}

@ShouldGenerate(
  r'''Map<String, dynamic> toFirestore(UserDTO dto) {
    return {
      'uid': dto.id,
      'email': dto.email,
      'displayName': dto.displayName,
      'phoneNumber': dto.phoneNumber,
      'photoURL': dto.photoURL,
      'emailVerified': dto.verified,
    };
  }''',
  contains: true,
)
@Mapper()
abstract class UserDTOMapper {
  @Mapping(source: 'id', target: 'uid')
  @Mapping(source: 'verified', target: 'emailVerified')
  Map<String, dynamic> toFirestore(UserDTO dto);
}

// ----- Nested classes, collections, maps, enums -----

enum Vote { yes, no }

class CardDTO {
  final String label;
  final double value;
  final Vote? vote;

  const CardDTO({required this.label, required this.value, this.vote});
}

class SessionDTO {
  final String id;
  final CardDTO? current;
  final Map<String, CardDTO> votes;
  final List<CardDTO> history;
  final Set<Vote> allowed;
  final Map<Vote, CardDTO> byVote;
  final DateTime createdAt;
  final List<String> tags;

  const SessionDTO({
    required this.id,
    this.current,
    required this.votes,
    required this.history,
    required this.allowed,
    required this.byVote,
    required this.createdAt,
    required this.tags,
  });
}

@ShouldGenerate(
  r'''Map<String, dynamic> toRealtime(SessionDTO session) {
    return {
      'id': session.id,
      'current': session.current != null
          ? _mapCardDTOToMap(session.current!)
          : null,
      'votes': session.votes.map(
        (key, value) => MapEntry(key, _mapCardDTOToMap(value)),
      ),
      'history': session.history.map((item) => _mapCardDTOToMap(item)).toList(),
      'allowed': session.allowed.map((item) => item.name).toList(),
      'byVote': session.byVote.map(
        (key, value) => MapEntry(key.name, _mapCardDTOToMap(value)),
      ),
      'createdAt': session.createdAt,
      'tags': session.tags,
    };
  }''',
  contains: true,
)
@ShouldGenerate(
  r'''Map<String, dynamic> _mapCardDTOToMap(CardDTO cardDTO) {
    return {
      'label': cardDTO.label,
      'value': cardDTO.value,
      'vote': cardDTO.vote?.name,
    };
  }''',
  contains: true,
)
@Mapper()
abstract class SessionDTOMapper {
  Map<String, dynamic> toRealtime(SessionDTO session);
}

// ----- Keys: constructor parameters only, ignore, computed getters -----

class ProfileDTO {
  final String id;
  final String? nickname;
  final String secret;
  final List<String> names;

  const ProfileDTO({
    required this.id,
    this.nickname,
    required this.secret,
    required this.names,
  });

  static const String kind = 'profile';

  // Computed getters are not keys unless they are explicitly mapped.
  String get initials => id.substring(0, 1);

  int get nameCount => names.length;
}

@ShouldGenerate(
  r'''return {'id': dto.id, 'nickname': dto.nickname, 'names': dto.names};''',
  contains: true,
)
@Mapper()
abstract class IgnoreMapper {
  @Mapping(target: 'secret', ignore: true)
  Map<String, dynamic> toMap(ProfileDTO dto);
}

@ShouldGenerate(
  r'''Map<String, dynamic> toMap(ProfileDTO dto) {
    return {
      'id': dto.id,
      'nickname': dto.nickname,
      'secret': dto.secret,
      'names': dto.names,
      'initials': dto.initials,
    };
  }''',
  contains: true,
)
@Mapper()
abstract class ComputedGetterMapper {
  @Mapping(source: 'initials', target: 'initials')
  Map<String, dynamic> toMap(ProfileDTO dto);
}

// ----- Nullable source and return -----

@ShouldGenerate(
  r'''Map<String, dynamic>? toMap([ProfileDTO? dto]) {
    if (dto == null) {
      return null;
    }
    return {
      'id': dto.id,
      'nickname': dto.nickname,
      'secret': dto.secret,
      'names': dto.names,
    };
  }''',
  contains: true,
)
@Mapper()
abstract class NullableReturnMapper {
  Map<String, dynamic>? toMap(ProfileDTO? dto);
}

// ----- Freezed-like source (factory constructor parameters) -----

class FreezedLikeDTO {
  final String id;
  final int count;
  final Vote vote;

  const FreezedLikeDTO._(this.id, this.count, this.vote);

  // Like freezed, the keys are the parameters of the factory constructor.
  factory FreezedLikeDTO({
    required String id,
    required int count,
    required Vote vote,
  }) = _FreezedLikeDTO;
}

class _FreezedLikeDTO extends FreezedLikeDTO {
  const _FreezedLikeDTO({
    required String id,
    required int count,
    required Vote vote,
  }) : super._(id, count, vote);
}

@ShouldGenerate(
  r'''return {'id': dto.id, 'count': dto.count, 'vote': dto.vote.name};''',
  contains: true,
)
@Mapper()
abstract class FreezedLikeMapper {
  Map<String, dynamic> toMap(FreezedLikeDTO dto);
}

// ----- Dot notation -----

class StreetDTO {
  final String name;
  final String zip;

  const StreetDTO({required this.name, required this.zip});
}

class AddressDTO {
  final String city;
  final StreetDTO? street;

  const AddressDTO({required this.city, this.street});
}

class PersonDTO {
  final String fullName;
  final AddressDTO address;
  final AddressDTO? previous;

  const PersonDTO({
    required this.fullName,
    required this.address,
    this.previous,
  });
}

@ShouldGenerate(
  r'''Map<String, dynamic> toMap(PersonDTO dto) {
    return {
      'fullName': dto.fullName,
      'city': dto.address.city,
      'street': dto.address.street?.name,
      'previousCity': dto.previous?.city,
    };
  }''',
  contains: true,
)
@Mapper()
abstract class SourceDotNotationMapper {
  @Mapping(source: 'address.city', target: 'city')
  @Mapping(source: 'address.street.name', target: 'street')
  @Mapping(source: 'previous.city', target: 'previousCity')
  @Mapping(target: 'address', ignore: true)
  @Mapping(target: 'previous', ignore: true)
  Map<String, dynamic> toMap(PersonDTO dto);
}

class FlatAddressDTO {
  final String street;
  final String city;
  final String name;

  const FlatAddressDTO({
    required this.street,
    required this.city,
    required this.name,
  });
}

@ShouldGenerate(
  r'''Map<String, dynamic> toMap(FlatAddressDTO dto) {
    return {
      'address': {'street': dto.street, 'city': dto.city},
      'name': dto.name,
    };
  }''',
  contains: true,
)
@Mapper()
abstract class TargetDotNotationMapper {
  @Mapping(source: 'street', target: 'address.street')
  @Mapping(source: 'city', target: 'address.city')
  Map<String, dynamic> toMap(FlatAddressDTO dto);
}

@ShouldGenerate(
  r'''Map<String, dynamic> toMap(FlatAddressDTO dto) {
    return {
      'location': {
        'address': {'street': dto.street, 'zip': 'n/a'},
        'city': dto.city,
      },
      'name': dto.name,
    };
  }''',
  contains: true,
)
@Mapper()
abstract class DeepTargetDotNotationMapper {
  @Mapping(source: 'street', target: 'location.address.street')
  @Mapping(target: 'location.address.zip', constant: "'n/a'")
  @Mapping(source: 'city', target: 'location.city')
  Map<String, dynamic> toMap(FlatAddressDTO dto);
}

// ----- Multi-source -----

class SettingsDTO {
  final String theme;
  final String id;

  const SettingsDTO({required this.theme, required this.id});
}

@ShouldGenerate(
  r'''Map<String, dynamic> toMap(ProfileDTO profile, SettingsDTO settings) {
    return {
      'profileId': profile.id,
      'nickname': profile.nickname,
      'secret': profile.secret,
      'names': profile.names,
      'theme': settings.theme,
      'settingsId': settings.id,
    };
  }''',
  contains: true,
)
@Mapper()
abstract class MultiSourceToMapMapper {
  @Mapping(source: 'profile.id', target: 'profileId')
  @Mapping(source: 'settings.id', target: 'settingsId')
  Map<String, dynamic> toMap(ProfileDTO profile, SettingsDTO settings);
}

// ----- Inherit configuration -----

@ShouldGenerate(
  r'''Map<String, dynamic> toRealtime(UserDTO dto) {
    return {
      'uid': dto.id,
      'email': dto.email,
      'displayName': dto.displayName,
      'phoneNumber': dto.phoneNumber,
      'photoURL': dto.photoURL,
      'emailVerified': dto.verified,
    };
  }''',
  contains: true,
)
@Mapper()
abstract class InheritToMapMapper {
  @Mapping(source: 'id', target: 'uid')
  @Mapping(source: 'verified', target: 'emailVerified')
  Map<String, dynamic> toFirestore(UserDTO dto);

  @InheritConfiguration()
  Map<String, dynamic> toRealtime(UserDTO dto);
}

// ----- Converters: declared methods and `uses` -----

enum Role { admin, member }

class EventDTO {
  final String title;
  final DateTime createdAt;
  final DateTime? deletedAt;
  final List<DateTime> reminders;
  final Role role;
  final CardDTO card;

  const EventDTO({
    required this.title,
    required this.createdAt,
    this.deletedAt,
    required this.reminders,
    required this.role,
    required this.card,
  });
}

// A declared converter takes precedence over pass-through and enum-by-name;
// a declared method converting a class is used instead of a generated one.
@ShouldGenerate(
  r'''Map<String, dynamic> toMap(EventDTO dto) {
    return {
      'title': dto.title,
      'createdAt': toMillis(dto.createdAt),
      'deletedAt': dto.deletedAt != null ? toMillis(dto.deletedAt!) : null,
      'reminders': dto.reminders.map((item) => toMillis(item)).toList(),
      'role': roleLabel(dto.role),
      'card': cardToMap(dto.card),
    };
  }''',
  contains: true,
)
@Mapper()
abstract class DeclaredConverterMapper {
  Map<String, dynamic> toMap(EventDTO dto);

  int toMillis(DateTime date) => date.millisecondsSinceEpoch;

  String roleLabel(Role role) => role.name.toUpperCase();

  Map<String, Object?> cardToMap(CardDTO card);
}

class DateConverters {
  const DateConverters();

  int toMillis(DateTime date) => date.millisecondsSinceEpoch;
}

@ShouldGenerate(
  r'''Map<String, dynamic> toMap(EventDTO dto) {
    return {
      'title': dto.title,
      'createdAt': dateConverters.toMillis(dto.createdAt),
      'deletedAt': dto.deletedAt != null
          ? dateConverters.toMillis(dto.deletedAt!)
          : null,
      'reminders': dto.reminders
          .map((item) => dateConverters.toMillis(item))
          .toList(),
      'role': dto.role.name,
      'card': _mapCardDTOToMap(dto.card),
    };
  }''',
  contains: true,
)
@Mapper(uses: {DateConverters})
abstract class UsesConverterMapper {
  Map<String, dynamic> toMap(EventDTO dto);
}

// ----- Typed maps -----

class LabelsDTO {
  final String name;
  final String? description;

  const LabelsDTO({required this.name, this.description});
}

@ShouldGenerate(
  r'''Map<String, String?> toMap(LabelsDTO dto) {
    return {'name': dto.name, 'description': dto.description};
  }''',
  contains: true,
)
@Mapper()
abstract class TypedNullableMapMapper {
  Map<String, String?> toMap(LabelsDTO dto);
}

@ShouldGenerate(
  r'''Map<String, Object> toMap(LabelsDTO dto) {
    return {'name': dto.name, 'description': dto.description!};
  }''',
  contains: true,
)
@Mapper()
abstract class TypedNonNullMapMapper {
  @Mapping(target: 'description', forceNonNull: true)
  Map<String, Object> toMap(LabelsDTO dto);
}

@ShouldGenerate(
  r'''Map<String, Object> toMap(LabelsDTO dto) {
    return {'name': dto.name, 'description': dto.description ?? 'none'};
  }''',
  contains: true,
)
@Mapper()
abstract class TypedDefaultMapMapper {
  @Mapping(target: 'description', defaultValue: 'none')
  Map<String, Object> toMap(LabelsDTO dto);
}

// A typed value that matches the field type is passed through unconverted.
@ShouldGenerate(
  r'''Map<String, CardDTO> toMap(SessionDTO dto) {
    return {'current': dto.current!};
  }''',
  contains: true,
)
@Mapper()
abstract class TypedClassValueMapper {
  @Mapping(source: 'current', target: 'current', forceNonNull: true)
  @Mapping(target: 'id', ignore: true)
  @Mapping(target: 'votes', ignore: true)
  @Mapping(target: 'history', ignore: true)
  @Mapping(target: 'allowed', ignore: true)
  @Mapping(target: 'byVote', ignore: true)
  @Mapping(target: 'createdAt', ignore: true)
  @Mapping(target: 'tags', ignore: true)
  Map<String, CardDTO> toMap(SessionDTO dto);
}

// ----- constant, expression, callable, defaultValue, conditionExpression -----

String shout(String value) => value.toUpperCase();

String join(String id, String? nickname) => '$id/$nickname';

@ShouldGenerate(
  r'''Map<String, dynamic> toMap(ProfileDTO dto) {
    return {
      'id': shout(dto.id),
      'nickname': dto.nickname ?? 'anonymous',
      'secret': dto.secret.length > 3 ? dto.secret : null,
      'names': dto.names,
      'joined': join(dto.id, dto.nickname),
      'version': 2,
      'kind': 'profile',
      'upper': dto.id.toUpperCase(),
    };
  }''',
  contains: true,
)
@Mapper()
abstract class MappingFeaturesToMapMapper {
  @Mapping(target: 'id', callable: shout)
  @Mapping(target: 'nickname', defaultValue: 'anonymous')
  @Mapping(
    target: 'secret',
    conditionExpression: 'dto.secret.length > 3',
  )
  @Mapping(target: 'version', constant: '2')
  @Mapping(target: 'kind', constant: "'profile'")
  @Mapping(target: 'upper', expression: 'dto.id.toUpperCase()')
  @Mapping(source: 'id, nickname', target: 'joined', callable: join)
  Map<String, dynamic> toMap(ProfileDTO dto);
}

// ----- Typed Map<String, Object?> and self-referencing classes -----

class NodeDTO {
  final String name;
  final List<NodeDTO> children;

  const NodeDTO({required this.name, required this.children});
}

// A self-referencing class needs a declared method: it is used for the
// nested values, including the recursion.
@ShouldGenerate(
  r'''return {
      'name': dto.name,
      'children': dto.children.map((item) => toMap(item)).toList(),
    };''',
  contains: true,
)
@Mapper()
abstract class SelfReferencingMapper {
  Map<String, Object?> toMap(NodeDTO dto);
}

@ShouldGenerate(
  r'''Map<String, Object?> toMap(EventDTO dto) {
    return {
      'title': dto.title,
      'createdAt': dto.createdAt,
      'deletedAt': dto.deletedAt,
      'reminders': dto.reminders,
      'role': dto.role.name,
      'card': _mapCardDTOToMap(dto.card),
    };
  }''',
  contains: true,
)
@Mapper()
abstract class ObjectNullableMapMapper {
  Map<String, Object?> toMap(EventDTO dto);
}

// A converter declared in the mapper wins over the one in `uses`.
@ShouldGenerate(
  r'''return {
      'title': dto.title,
      'createdAt': iso(dto.createdAt),
      'deletedAt': dto.deletedAt != null ? iso(dto.deletedAt!) : null,
    };''',
  contains: true,
)
@Mapper(uses: {DateConverters})
abstract class DeclaredOverUsesMapper {
  @Mapping(target: 'reminders', ignore: true)
  @Mapping(target: 'role', ignore: true)
  @Mapping(target: 'card', ignore: true)
  Map<String, dynamic> toMap(EventDTO dto);

  String iso(DateTime date) => date.toIso8601String();
}
