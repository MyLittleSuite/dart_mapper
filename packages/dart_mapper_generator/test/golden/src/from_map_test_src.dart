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

// Golden test source for Map -> class mapping (MappingBehavior.fromMap).
//
// Covers the read side of the class <-> Map mapping: strict casts, nullable
// casts, defaults, numbers, typed maps, nested classes and collections, enums,
// converters, dot notation, multi-source, renames and inherited
// configuration, for standard, freezed-like and built_value targets.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

// ----- Shared models -----

enum FmStatus { open, closed }

enum FmColor { red, green }

class FmUser {
  final String id;
  final String? email;
  final String? displayName;
  final String? phoneNumber;
  final String? photoURL;
  final bool? verified;

  const FmUser({
    required this.id,
    this.email,
    this.displayName,
    this.phoneNumber,
    this.photoURL,
    this.verified,
  });
}

// freezed-like: abstract class with a factory constructor.
abstract class FmCard {
  const factory FmCard({
    required String name,
    required double value,
  }) = _FmCard;

  String get name;

  double get value;
}

class _FmCard implements FmCard {
  const _FmCard({required this.name, required this.value});

  @override
  final String name;

  @override
  final double value;
}

abstract class FmSession {
  const factory FmSession({
    required String id,
    String? description,
    Map<String, FmCard> votes,
    required int createdAt,
  }) = _FmSession;

  String get id;

  String? get description;

  Map<String, FmCard> get votes;

  int get createdAt;
}

class _FmSession implements FmSession {
  const _FmSession({
    required this.id,
    this.description,
    this.votes = const {},
    required this.createdAt,
  });

  @override
  final String id;

  @override
  final String? description;

  @override
  final Map<String, FmCard> votes;

  @override
  final int createdAt;
}

class FmScalars {
  final String name;
  final int count;
  final bool flag;
  final double ratio;
  final num amount;
  final String? note;
  final int? maybeCount;
  final double? maybeRatio;
  final DateTime createdAt;
  final Duration? elapsed;

  const FmScalars({
    required this.name,
    required this.count,
    required this.flag,
    required this.ratio,
    required this.amount,
    this.note,
    this.maybeCount,
    this.maybeRatio,
    required this.createdAt,
    this.elapsed,
  });
}

class FmPrimitiveSimple {
  final String name;
  final int count;
  final double ratio;

  const FmPrimitiveSimple({
    required this.name,
    required this.count,
    required this.ratio,
  });
}

class FmNestedParent {
  final FmCard card;
  final FmCard? optionalCard;
  final List<FmCard> cards;
  final Set<FmCard> uniqueCards;
  final Iterable<FmCard> iterableCards;
  final List<FmCard>? maybeCards;
  final Map<String, FmCard> byName;

  const FmNestedParent({
    required this.card,
    this.optionalCard,
    required this.cards,
    required this.uniqueCards,
    required this.iterableCards,
    this.maybeCards,
    required this.byName,
  });
}

class FmCollections {
  final List<String> tags;
  final List<String>? maybeTags;
  final Set<int> ids;
  final List<double> weights;
  final List<double?> maybeWeights;
  final Map<String, int> counters;
  final Map<String, double> scores;
  final List<List<String>> matrix;
  final List<FmStatus> statuses;
  final Map<FmStatus, FmCard> cardsByStatus;
  final Map<String, List<FmCard>> groups;
  final List<dynamic> raw;

  const FmCollections({
    required this.tags,
    this.maybeTags,
    required this.ids,
    required this.weights,
    required this.maybeWeights,
    required this.counters,
    required this.scores,
    required this.matrix,
    required this.statuses,
    required this.cardsByStatus,
    required this.groups,
    required this.raw,
  });
}

class FmEnums {
  final FmStatus status;
  final FmStatus? maybeStatus;
  final FmColor color;

  const FmEnums({
    required this.status,
    this.maybeStatus,
    required this.color,
  });
}

class FmAddress {
  final String street;
  final String? city;

  const FmAddress({required this.street, this.city});
}

class FmPerson {
  final String name;
  final FmAddress address;

  const FmPerson({required this.name, required this.address});
}

class FmFlat {
  final String name;
  final String street;
  final String? city;
  final String? zip;

  const FmFlat({
    required this.name,
    required this.street,
    this.city,
    this.zip,
  });
}

class FmNums {
  final num amount;
  final double ratio;

  const FmNums({required this.amount, required this.ratio});
}

class FmTreeHolder {
  final FmTree tree;

  const FmTreeHolder({required this.tree});
}

class FmTree {
  final String name;
  final List<FmTree> children;

  const FmTree({required this.name, required this.children});
}

class FmHolder {
  final int id;
  final String name;

  const FmHolder({required this.id, required this.name});
}

class FmOwner {
  final String ownerName;

  const FmOwner({required this.ownerName});
}

class FmRoom {
  final String id;
  final String name;
  final String ownerName;

  const FmRoom({
    required this.id,
    required this.name,
    required this.ownerName,
  });
}

class FmStamped {
  final String name;
  final DateTime at;
  final DateTime? maybeAt;
  final List<DateTime> history;

  const FmStamped({
    required this.name,
    required this.at,
    this.maybeAt,
    required this.history,
  });
}

class FmCustom {
  final String name;
  final String? nickname;
  final int code;
  final String slug;
  final String? hidden;

  const FmCustom({
    required this.name,
    this.nickname,
    required this.code,
    required this.slug,
    this.hidden,
  });
}

class FmRequiredNullable {
  final String name;
  final String? secret;

  const FmRequiredNullable({required this.name, required this.secret});
}

class FmOptionalDefault {
  final String name;
  final int level;

  const FmOptionalDefault({required this.name, this.level = 1});
}

sealed class FmShape {
  const FmShape();
}

class FmCircle extends FmShape {
  const FmCircle();
}

abstract class FmAbstractThing {
  String get name;
}

class FmHolderNullableSource {
  final int id;
  final int? other;

  const FmHolderNullableSource({required this.id, this.other});
}

class FmHolderStrings {
  final String? first;
  final String? second;

  const FmHolderStrings({this.first, this.second});
}

// ----- built_value-like models (the real package, hand-written parts) -----

abstract class FmBuiltCard implements Built<FmBuiltCard, FmBuiltCardBuilder> {
  String get name;

  double get value;

  FmBuiltCard._();

  factory FmBuiltCard([void Function(FmBuiltCardBuilder) updates]) =
      _$FmBuiltCard;
}

abstract class FmBuiltCardBuilder
    implements Builder<FmBuiltCard, FmBuiltCardBuilder> {
  String? name;
  double? value;

  FmBuiltCardBuilder._();

  factory FmBuiltCardBuilder() = _$FmBuiltCardBuilder;
}

abstract class FmBuiltDeck implements Built<FmBuiltDeck, FmBuiltDeckBuilder> {
  String get id;

  String? get label;

  FmBuiltCard get main;

  BuiltList<String> get tags;

  BuiltList<FmBuiltCard> get cards;

  BuiltMap<String, int> get counters;

  FmBuiltDeck._();

  factory FmBuiltDeck([void Function(FmBuiltDeckBuilder) updates]) =
      _$FmBuiltDeck;
}

abstract class FmBuiltDeckBuilder
    implements Builder<FmBuiltDeck, FmBuiltDeckBuilder> {
  String? id;
  String? label;
  FmBuiltCardBuilder? main;
  ListBuilder<String>? tags;
  ListBuilder<FmBuiltCard>? cards;
  MapBuilder<String, int>? counters;

  FmBuiltDeckBuilder._();

  factory FmBuiltDeckBuilder() = _$FmBuiltDeckBuilder;
}

abstract class FmBuiltDeckAbstract
    implements Built<FmBuiltDeckAbstract, FmBuiltDeckAbstractBuilder> {
  String get id;

  FmBuiltDeckAbstract._();

  factory FmBuiltDeckAbstract(
          [void Function(FmBuiltDeckAbstractBuilder) updates]) =
      _$FmBuiltDeckAbstract;
}

abstract class FmBuiltDeckAbstractBuilder
    implements Builder<FmBuiltDeckAbstract, FmBuiltDeckAbstractBuilder> {
  String? id;

  FmBuiltDeckAbstractBuilder._();

  factory FmBuiltDeckAbstractBuilder() = _$FmBuiltDeckAbstractBuilder;
}

class _$FmBuiltCard extends FmBuiltCard {
  @override
  String get name => throw UnimplementedError();

  @override
  double get value => throw UnimplementedError();

  _$FmBuiltCard([void Function(FmBuiltCardBuilder)? updates]) : super._();

  @override
  FmBuiltCard rebuild(void Function(FmBuiltCardBuilder) updates) =>
      throw UnimplementedError();

  @override
  FmBuiltCardBuilder toBuilder() => throw UnimplementedError();
}

class _$FmBuiltCardBuilder extends FmBuiltCardBuilder {
  _$FmBuiltCardBuilder() : super._();

  @override
  void replace(FmBuiltCard other) {}

  @override
  void update(void Function(FmBuiltCardBuilder)? updates) {}

  @override
  FmBuiltCard build() => throw UnimplementedError();
}

class _$FmBuiltDeck extends FmBuiltDeck {
  @override
  String get id => throw UnimplementedError();

  @override
  String? get label => throw UnimplementedError();

  @override
  FmBuiltCard get main => throw UnimplementedError();

  @override
  BuiltList<String> get tags => throw UnimplementedError();

  @override
  BuiltList<FmBuiltCard> get cards => throw UnimplementedError();

  @override
  BuiltMap<String, int> get counters => throw UnimplementedError();

  _$FmBuiltDeck([void Function(FmBuiltDeckBuilder)? updates]) : super._();

  @override
  FmBuiltDeck rebuild(void Function(FmBuiltDeckBuilder) updates) =>
      throw UnimplementedError();

  @override
  FmBuiltDeckBuilder toBuilder() => throw UnimplementedError();
}

class _$FmBuiltDeckBuilder extends FmBuiltDeckBuilder {
  _$FmBuiltDeckBuilder() : super._();

  @override
  void replace(FmBuiltDeck other) {}

  @override
  void update(void Function(FmBuiltDeckBuilder)? updates) {}

  @override
  FmBuiltDeck build() => throw UnimplementedError();
}

class _$FmBuiltDeckAbstract extends FmBuiltDeckAbstract {
  @override
  String get id => throw UnimplementedError();

  _$FmBuiltDeckAbstract([void Function(FmBuiltDeckAbstractBuilder)? updates]) : super._();

  @override
  FmBuiltDeckAbstract rebuild(void Function(FmBuiltDeckAbstractBuilder) updates) =>
      throw UnimplementedError();

  @override
  FmBuiltDeckAbstractBuilder toBuilder() => throw UnimplementedError();
}

class _$FmBuiltDeckAbstractBuilder extends FmBuiltDeckAbstractBuilder {
  _$FmBuiltDeckAbstractBuilder() : super._();

  @override
  void replace(FmBuiltDeckAbstract other) {}

  @override
  void update(void Function(FmBuiltDeckAbstractBuilder)? updates) {}

  @override
  FmBuiltDeckAbstract build() => throw UnimplementedError();
}

// ----- External converters (used through @Mapper(uses: ...)) -----

class FmDateConverters {
  const FmDateConverters();

  DateTime fromMillis(int milliseconds) =>
      DateTime.fromMillisecondsSinceEpoch(milliseconds);
}

class FmAmbiguousConverters {
  const FmAmbiguousConverters();

  DateTime fromMillis(int milliseconds) =>
      DateTime.fromMillisecondsSinceEpoch(milliseconds);

  DateTime fromIso(String iso) => DateTime.parse(iso);
}

class FmNestedMappers {
  const FmNestedMappers();

  FmCard fromRawMap(Map map) => FmCard(
        name: map['name'] as String,
        value: (map['value'] as num).toDouble(),
      );
}

String upperCase(Object? value) => (value as String).toUpperCase();

String joinNames(Object? first, Object? second) => '$first $second';


@ShouldGenerate(
  r'''class FmUserMapperImpl extends FmUserMapper {
  FmUserMapperImpl();

  @override
  Map<String, dynamic> toFirestore(FmUser dto) {
    return {
      'uid': dto.id,
      'email': dto.email,
      'displayName': dto.displayName,
      'phoneNumber': dto.phoneNumber,
      'photoURL': dto.photoURL,
      'emailVerified': dto.verified,
    };
  }

  @override
  FmUser fromFirestore(Map<String, dynamic> map) {
    return FmUser(
      id: map['uid'] as String,
      email: map['email'] as String?,
      displayName: map['displayName'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      photoURL: map['photoURL'] as String?,
      verified: map['emailVerified'] as bool?,
    );
  }
}''',
  contains: true,
)
@Mapper()
abstract class FmUserMapper {
  @Mapping(source: 'id', target: 'uid')
  @Mapping(source: 'verified', target: 'emailVerified')
  Map<String, dynamic> toFirestore(FmUser dto);

  @InheritInverseConfiguration()
  FmUser fromFirestore(Map<String, dynamic> map);
}

@ShouldGenerate(
  r'''class FmSessionMapperImpl extends FmSessionMapper {
  FmSessionMapperImpl();

  @override
  FmSession fromRealtime(Map<dynamic, dynamic> map) {
    return FmSession(
      id: map['id'] as String,
      description: map['description'] as String?,
      votes: (map['votes'] as Map? ?? const {}).map<String, FmCard>(
        (key, value) => MapEntry(
          key as String,
          _mapMapToFmCard(Map<String, dynamic>.from(value as Map)),
        ),
      ),
      createdAt: map['created_at'] as int,
    );
  }

  FmCard _mapMapToFmCard(Map<String, dynamic> map) {
    return FmCard(
      name: map['name'] as String,
      value: (map['value'] as num).toDouble(),
    );
  }
}''',
  contains: true,
)
@Mapper()
abstract class FmSessionMapper {
  @Mapping(source: 'created_at', target: 'createdAt')
  @Mapping(target: 'votes', defaultValue: 'const {}')
  FmSession fromRealtime(Map map);
}

@ShouldGenerate(
  r'''class FmSessionStrictMapperImpl extends FmSessionStrictMapper {
  FmSessionStrictMapperImpl();

  @override
  FmSession fromRealtime(Map<dynamic, dynamic> map) {
    return FmSession(
      id: map['id'] as String,
      description: map['description'] as String?,
      votes: (map['votes'] as Map).map<String, FmCard>(
        (key, value) => MapEntry(
          key as String,
          _mapMapToFmCard(Map<String, dynamic>.from(value as Map)),
        ),
      ),
      createdAt: map['created_at'] as int,
    );
  }

  FmCard _mapMapToFmCard(Map<String, dynamic> map) {
    return FmCard(
      name: map['name'] as String,
      value: (map['value'] as num).toDouble(),
    );
  }
}''',
  contains: true,
)
@Mapper()
abstract class FmSessionStrictMapper {
  @Mapping(source: 'created_at', target: 'createdAt')
  FmSession fromRealtime(Map map);
}

@ShouldGenerate(
  r'''class FmScalarsMapperImpl extends FmScalarsMapper {
  FmScalarsMapperImpl();

  @override
  FmScalars fromMap(Map<String, dynamic> map) {
    return FmScalars(
      name: map['name'] as String,
      count: map['count'] as int,
      flag: map['flag'] as bool? ?? false,
      ratio: (map['ratio'] as num).toDouble(),
      amount: map['amount'] as num,
      note: map['note'] as String? ?? 'none',
      maybeCount: map['maybeCount'] as int? ?? 3,
      maybeRatio: (map['maybeRatio'] as num?)?.toDouble() ?? 1.5,
      createdAt: map['createdAt'] as DateTime,
      elapsed: map['elapsed'] as Duration?,
    );
  }
}''',
  contains: true,
)
@Mapper()
abstract class FmScalarsMapper {
  @Mapping(target: 'note', defaultValue: 'none')
  @Mapping(target: 'maybeCount', defaultValue: '3')
  @Mapping(target: 'maybeRatio', defaultValue: '1.5')
  @Mapping(target: 'flag', defaultValue: 'false')
  FmScalars fromMap(Map<String, dynamic> map);
}

@ShouldGenerate(
  r'''class FmObjectKeyedMapperImpl extends FmObjectKeyedMapper {
  FmObjectKeyedMapperImpl();

  @override
  FmPrimitiveSimple fromMap(Map<Object?, Object?> map) {
    return FmPrimitiveSimple(
      name: map['name'] as String,
      count: map['count'] as int,
      ratio: (map['ratio'] as num).toDouble(),
    );
  }

  @override
  FmPrimitiveSimple fromObjectMap(Map<String, Object?> map) {
    return FmPrimitiveSimple(
      name: map['name'] as String,
      count: map['count'] as int,
      ratio: (map['ratio'] as num).toDouble(),
    );
  }
}''',
  contains: true,
)
@Mapper()
abstract class FmObjectKeyedMapper {
  FmPrimitiveSimple fromMap(Map<Object?, Object?> map);

  FmPrimitiveSimple fromObjectMap(Map<String, Object?> map);
}

@ShouldGenerate(
  r'''class FmTypedMapperImpl extends FmTypedMapper {
  FmTypedMapperImpl();

  @override
  FmNums fromNums(Map<String, num> map) {
    return FmNums(
      amount: map['amount'] as num,
      ratio: (map['ratio'] as num).toDouble(),
    );
  }
}''',
  contains: true,
)
@Mapper()
abstract class FmTypedMapper {
  FmNums fromNums(Map<String, num> map);
}

@ShouldGenerate(
  r'''class FmTypedNullableForceMapperImpl extends FmTypedNullableForceMapper {
  FmTypedNullableForceMapperImpl();

  @override
  FmHolderNullableSource fromNullable(Map<String, int?> map) {
    return FmHolderNullableSource(id: map['id']!, other: map['other']);
  }
}''',
  contains: true,
)
@Mapper()
abstract class FmTypedNullableForceMapper {
  @Mapping(target: 'id', forceNonNull: true)
  FmHolderNullableSource fromNullable(Map<String, int?> map);
}

@ShouldGenerate(
  r'''class FmDynamicForceMapperImpl extends FmDynamicForceMapper {
  FmDynamicForceMapperImpl();

  @override
  FmHolder fromDynamic(Map<String, Object?> map) {
    return FmHolder(id: map['id'] as int, name: map['title'] as String);
  }
}''',
  contains: true,
)
@Mapper()
abstract class FmDynamicForceMapper {
  // forceNonNull is a no-op on untyped maps: the cast already rejects null.
  @Mapping(target: 'id', forceNonNull: true)
  @Mapping(target: 'name', source: 'title')
  FmHolder fromDynamic(Map<String, Object?> map);
}

@ShouldGenerate(
  r'''class FmTypedNullableDefaultMapperImpl extends FmTypedNullableDefaultMapper {
  FmTypedNullableDefaultMapperImpl();

  @override
  FmHolderNullableSource fromNullable(Map<String, int?> map) {
    return FmHolderNullableSource(id: map['id'] ?? 0, other: map['other']);
  }
}''',
  contains: true,
)
@Mapper()
abstract class FmTypedNullableDefaultMapper {
  @Mapping(target: 'id', defaultValue: '0')
  FmHolderNullableSource fromNullable(Map<String, int?> map);
}

@ShouldGenerate(
  r'''class FmTypedStringsMapperImpl extends FmTypedStringsMapper {
  FmTypedStringsMapperImpl();

  @override
  FmHolderStrings fromStrings(Map<String, String?> map) {
    return FmHolderStrings(first: map['first'], second: map['second']);
  }
}''',
  contains: true,
)
@Mapper()
abstract class FmTypedStringsMapper {
  FmHolderStrings fromStrings(Map<String, String?> map);
}

@ShouldGenerate(
  r'''class FmNestedMapperImpl extends FmNestedMapper {
  FmNestedMapperImpl();

  @override
  FmNestedParent fromMap(Map<String, dynamic> map) {
    return FmNestedParent(
      card: _mapMapToFmCard(Map<String, dynamic>.from(map['card'] as Map)),
      optionalCard: map['optionalCard'] != null
          ? _mapMapToFmCard(
              Map<String, dynamic>.from(map['optionalCard'] as Map),
            )
          : null,
      cards: (map['cards'] as List)
          .map<FmCard>(
            (e) => _mapMapToFmCard(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      uniqueCards: (map['uniqueCards'] as List)
          .map<FmCard>(
            (e) => _mapMapToFmCard(Map<String, dynamic>.from(e as Map)),
          )
          .toSet(),
      iterableCards: (map['iterableCards'] as List)
          .map<FmCard>(
            (e) => _mapMapToFmCard(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      maybeCards: map['maybeCards'] != null
          ? (map['maybeCards'] as List)
                .map<FmCard>(
                  (e) => _mapMapToFmCard(Map<String, dynamic>.from(e as Map)),
                )
                .toList()
          : null,
      byName: (map['byName'] as Map).map<String, FmCard>(
        (key, value) => MapEntry(
          key as String,
          _mapMapToFmCard(Map<String, dynamic>.from(value as Map)),
        ),
      ),
    );
  }

  FmCard _mapMapToFmCard(Map<String, dynamic> map) {
    return FmCard(
      name: map['name'] as String,
      value: (map['value'] as num).toDouble(),
    );
  }
}''',
  contains: true,
)
@Mapper()
abstract class FmNestedMapper {
  FmNestedParent fromMap(Map<String, dynamic> map);
}

@ShouldGenerate(
  r'''class FmCollectionsMapperImpl extends FmCollectionsMapper {
  FmCollectionsMapperImpl();

  @override
  FmCollections fromMap(Map<String, dynamic> map) {
    return FmCollections(
      tags: List<String>.from(map['tags'] as List),
      maybeTags: map['maybeTags'] != null
          ? List<String>.from(map['maybeTags'] as List)
          : null,
      ids: Set<int>.from(map['ids'] as List),
      weights: (map['weights'] as List)
          .map<double>((e) => (e as num).toDouble())
          .toList(),
      maybeWeights: (map['maybeWeights'] as List)
          .map<double?>((e) => (e as num?)?.toDouble())
          .toList(),
      counters: Map<String, int>.from(map['counters'] as Map),
      scores: (map['scores'] as Map).map<String, double>(
        (key, value) => MapEntry(key as String, (value as num).toDouble()),
      ),
      matrix: (map['matrix'] as List)
          .map<List<String>>((e) => List<String>.from(e as List))
          .toList(),
      statuses: (map['statuses'] as List)
          .map<FmStatus>((e) => FmStatus.values.byName(e as String))
          .toList(),
      cardsByStatus: (map['cardsByStatus'] as Map).map<FmStatus, FmCard>(
        (key, value) => MapEntry(
          FmStatus.values.byName(key as String),
          _mapMapToFmCard(Map<String, dynamic>.from(value as Map)),
        ),
      ),
      groups: (map['groups'] as Map).map<String, List<FmCard>>(
        (key, value) => MapEntry(
          key as String,
          (value as List)
              .map<FmCard>(
                (e) => _mapMapToFmCard(Map<String, dynamic>.from(e as Map)),
              )
              .toList(),
        ),
      ),
      raw: List<dynamic>.from(map['raw'] as List),
    );
  }

  FmCard _mapMapToFmCard(Map<String, dynamic> map) {
    return FmCard(
      name: map['name'] as String,
      value: (map['value'] as num).toDouble(),
    );
  }
}''',
  contains: true,
)
@Mapper()
abstract class FmCollectionsMapper {
  FmCollections fromMap(Map<String, dynamic> map);
}

@ShouldGenerate(
  r'''class FmCollectionsDefaultsMapperImpl extends FmCollectionsDefaultsMapper {
  FmCollectionsDefaultsMapperImpl();

  @override
  FmCollections fromMap(Map<String, dynamic> map) {
    return FmCollections(
      tags: List<String>.from(map['tags'] as List? ?? const []),
      maybeTags: map['maybeTags'] != null
          ? List<String>.from(map['maybeTags'] as List)
          : null,
      ids: Set<int>.from(map['ids'] as List),
      weights: (map['weights'] as List)
          .map<double>((e) => (e as num).toDouble())
          .toList(),
      maybeWeights: (map['maybeWeights'] as List)
          .map<double?>((e) => (e as num?)?.toDouble())
          .toList(),
      counters: Map<String, int>.from(map['counters'] as Map? ?? const {}),
      scores: (map['scores'] as Map).map<String, double>(
        (key, value) => MapEntry(key as String, (value as num).toDouble()),
      ),
      matrix: (map['matrix'] as List)
          .map<List<String>>((e) => List<String>.from(e as List))
          .toList(),
      statuses: (map['statuses'] as List)
          .map<FmStatus>((e) => FmStatus.values.byName(e as String))
          .toList(),
      cardsByStatus: (map['cardsByStatus'] as Map).map<FmStatus, FmCard>(
        (key, value) => MapEntry(
          FmStatus.values.byName(key as String),
          _mapMapToFmCard(Map<String, dynamic>.from(value as Map)),
        ),
      ),
      groups: (map['groups'] as Map).map<String, List<FmCard>>(
        (key, value) => MapEntry(
          key as String,
          (value as List)
              .map<FmCard>(
                (e) => _mapMapToFmCard(Map<String, dynamic>.from(e as Map)),
              )
              .toList(),
        ),
      ),
      raw: List<dynamic>.from(map['raw'] as List),
    );
  }

  FmCard _mapMapToFmCard(Map<String, dynamic> map) {
    return FmCard(
      name: map['name'] as String,
      value: (map['value'] as num).toDouble(),
    );
  }
}''',
  contains: true,
)
@Mapper()
abstract class FmCollectionsDefaultsMapper {
  @Mapping(target: 'tags', defaultValue: 'const []')
  @Mapping(target: 'counters', defaultValue: 'const {}')
  FmCollections fromMap(Map<String, dynamic> map);
}

@ShouldGenerate(
  r'''class FmEnumsMapperImpl extends FmEnumsMapper {
  FmEnumsMapperImpl();

  @override
  FmEnums fromMap(Map<String, dynamic> map) {
    return FmEnums(
      status: FmStatus.values.byName(map['status'] as String),
      maybeStatus: map['maybeStatus'] != null
          ? FmStatus.values.byName(map['maybeStatus'] as String)
          : null,
      color: map['color'] != null
          ? FmColor.values.byName(map['color'] as String)
          : FmColor.red,
    );
  }
}''',
  contains: true,
)
@Mapper()
abstract class FmEnumsMapper {
  @Mapping(target: 'color', defaultValue: 'FmColor.red')
  FmEnums fromMap(Map<String, dynamic> map);
}

@ShouldGenerate(
  r'''class FmDeclaredNestedMapperImpl extends FmDeclaredNestedMapper {
  FmDeclaredNestedMapperImpl();

  @override
  FmNestedParent fromMap(Map<String, dynamic> map) {
    return FmNestedParent(
      card: fromCard(Map<String, dynamic>.from(map['card'] as Map)),
      optionalCard: map['optionalCard'] != null
          ? fromCard(Map<String, dynamic>.from(map['optionalCard'] as Map))
          : null,
      cards: (map['cards'] as List)
          .map<FmCard>((e) => fromCard(Map<String, dynamic>.from(e as Map)))
          .toList(),
      uniqueCards: (map['uniqueCards'] as List)
          .map<FmCard>((e) => fromCard(Map<String, dynamic>.from(e as Map)))
          .toSet(),
      iterableCards: (map['iterableCards'] as List)
          .map<FmCard>((e) => fromCard(Map<String, dynamic>.from(e as Map)))
          .toList(),
      maybeCards: map['maybeCards'] != null
          ? (map['maybeCards'] as List)
                .map<FmCard>(
                  (e) => fromCard(Map<String, dynamic>.from(e as Map)),
                )
                .toList()
          : null,
      byName: (map['byName'] as Map).map<String, FmCard>(
        (key, value) => MapEntry(
          key as String,
          fromCard(Map<String, dynamic>.from(value as Map)),
        ),
      ),
    );
  }

  @override
  FmCard fromCard(Map<String, dynamic> map) {
    return FmCard(
      name: map['name'] as String,
      value: (map['value'] as num).toDouble(),
    );
  }
}''',
  contains: true,
)
@Mapper()
abstract class FmDeclaredNestedMapper {
  FmNestedParent fromMap(Map<String, dynamic> map);

  FmCard fromCard(Map<String, dynamic> map);
}

@ShouldGenerate(
  r'''class FmDeclaredRawNestedMapperImpl extends FmDeclaredRawNestedMapper {
  FmDeclaredRawNestedMapperImpl();

  @override
  FmNestedParent fromMap(Map<String, dynamic> map) {
    return FmNestedParent(
      card: fromCard(map['card'] as Map),
      optionalCard: map['optionalCard'] != null
          ? fromCard(map['optionalCard'] as Map)
          : null,
      cards: (map['cards'] as List)
          .map<FmCard>((e) => fromCard(e as Map))
          .toList(),
      uniqueCards: (map['uniqueCards'] as List)
          .map<FmCard>((e) => fromCard(e as Map))
          .toSet(),
      iterableCards: (map['iterableCards'] as List)
          .map<FmCard>((e) => fromCard(e as Map))
          .toList(),
      maybeCards: map['maybeCards'] != null
          ? (map['maybeCards'] as List)
                .map<FmCard>((e) => fromCard(e as Map))
                .toList()
          : null,
      byName: (map['byName'] as Map).map<String, FmCard>(
        (key, value) => MapEntry(key as String, fromCard(value as Map)),
      ),
    );
  }
}''',
  contains: true,
)
@Mapper()
abstract class FmDeclaredRawNestedMapper {
  FmNestedParent fromMap(Map<String, dynamic> map);

  FmCard fromCard(Map map) => FmCard(
        name: map['name'] as String,
        value: (map['value'] as num).toDouble(),
      );
}

@ShouldGenerate(
  r'''class FmUsesNestedMapperImpl extends FmUsesNestedMapper {
  FmUsesNestedMapperImpl({required this.fmNestedMappers});

  final FmNestedMappers fmNestedMappers;

  @override
  FmNestedParent fromMap(Map<String, dynamic> map) {
    return FmNestedParent(
      card: fmNestedMappers.fromRawMap(map['card'] as Map),
      optionalCard: map['optionalCard'] != null
          ? fmNestedMappers.fromRawMap(map['optionalCard'] as Map)
          : null,
      cards: (map['cards'] as List)
          .map<FmCard>((e) => fmNestedMappers.fromRawMap(e as Map))
          .toList(),
      uniqueCards: (map['uniqueCards'] as List)
          .map<FmCard>((e) => fmNestedMappers.fromRawMap(e as Map))
          .toSet(),
      iterableCards: (map['iterableCards'] as List)
          .map<FmCard>((e) => fmNestedMappers.fromRawMap(e as Map))
          .toList(),
      maybeCards: map['maybeCards'] != null
          ? (map['maybeCards'] as List)
                .map<FmCard>((e) => fmNestedMappers.fromRawMap(e as Map))
                .toList()
          : null,
      byName: (map['byName'] as Map).map<String, FmCard>(
        (key, value) =>
            MapEntry(key as String, fmNestedMappers.fromRawMap(value as Map)),
      ),
    );
  }
}''',
  contains: true,
)
@Mapper(uses: {FmNestedMappers})
abstract class FmUsesNestedMapper {
  FmNestedParent fromMap(Map<String, dynamic> map);
}

@ShouldGenerate(
  r'''class FmUsesConverterMapperImpl extends FmUsesConverterMapper {
  FmUsesConverterMapperImpl({required this.fmDateConverters});

  final FmDateConverters fmDateConverters;

  @override
  FmStamped fromMap(Map<String, dynamic> map) {
    return FmStamped(
      name: map['name'] as String,
      at: fmDateConverters.fromMillis(map['at'] as int),
      maybeAt: map['maybeAt'] != null
          ? fmDateConverters.fromMillis(map['maybeAt'] as int)
          : null,
      history: (map['history'] as List)
          .map<DateTime>((e) => fmDateConverters.fromMillis(e as int))
          .toList(),
    );
  }
}''',
  contains: true,
)
@Mapper(uses: {FmDateConverters})
abstract class FmUsesConverterMapper {
  FmStamped fromMap(Map<String, dynamic> map);
}

@ShouldGenerate(
  r'''class FmDeclaredConverterMapperImpl extends FmDeclaredConverterMapper {
  FmDeclaredConverterMapperImpl();

  @override
  FmStamped fromMap(Map<String, dynamic> map) {
    return FmStamped(
      name: map['name'] as String,
      at: fromMillis(map['at'] as int),
      maybeAt: map['maybeAt'] != null
          ? fromMillis(map['maybeAt'] as int)
          : null,
      history: (map['history'] as List)
          .map<DateTime>((e) => fromMillis(e as int))
          .toList(),
    );
  }
}''',
  contains: true,
)
@Mapper()
abstract class FmDeclaredConverterMapper {
  FmStamped fromMap(Map<String, dynamic> map);

  DateTime fromMillis(int milliseconds) =>
      DateTime.fromMillisecondsSinceEpoch(milliseconds);
}

@ShouldGenerate(
  r'''class FmDotNotationMapperImpl extends FmDotNotationMapper {
  FmDotNotationMapperImpl();

  @override
  FmFlat fromMap(Map<String, dynamic> map) {
    return FmFlat(
      name: map['name'] as String,
      street: (map['address'] as Map?)?['street'] as String,
      city: (map['address'] as Map?)?['city'] as String?,
      zip: ((map['address'] as Map?)?['geo'] as Map?)?['zip'] as String?,
    );
  }
}''',
  contains: true,
)
@Mapper()
abstract class FmDotNotationMapper {
  @Mapping(source: 'address.street', target: 'street')
  @Mapping(source: 'address.city', target: 'city')
  @Mapping(source: 'address.geo.zip', target: 'zip')
  FmFlat fromMap(Map<String, dynamic> map);
}

@ShouldGenerate(
  r'''class FmRecursivePrivateMapperImpl extends FmRecursivePrivateMapper {
  FmRecursivePrivateMapperImpl();

  @override
  FmTreeHolder fromMap(Map<String, dynamic> map) {
    return FmTreeHolder(
      tree: _mapMapToFmTree(Map<String, dynamic>.from(map['tree'] as Map)),
    );
  }

  FmTree _mapMapToFmTree(Map<String, dynamic> map) {
    return FmTree(
      name: map['name'] as String,
      children: (map['children'] as List)
          .map<FmTree>(
            (e) => _mapMapToFmTree(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
  }
}''',
  contains: true,
)
@Mapper()
abstract class FmRecursivePrivateMapper {
  FmTreeHolder fromMap(Map<String, dynamic> map);
}

@ShouldGenerate(
  r'''class FmRecursiveMapperImpl extends FmRecursiveMapper {
  FmRecursiveMapperImpl();

  @override
  FmTree fromMap(Map<String, dynamic> map) {
    return FmTree(
      name: map['name'] as String,
      children: (map['children'] as List)
          .map<FmTree>((e) => fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}''',
  contains: true,
)
@Mapper()
abstract class FmRecursiveMapper {
  FmTree fromMap(Map<String, dynamic> map);
}

@ShouldGenerate(
  r'''class FmMultiSourceMapperImpl extends FmMultiSourceMapper {
  FmMultiSourceMapperImpl();

  @override
  FmRoom fromRealtime(Map<dynamic, dynamic> map, String id) {
    return FmRoom(
      id: id,
      name: map['name'] as String,
      ownerName: map['owner'] as String,
    );
  }
}''',
  contains: true,
)
@Mapper()
abstract class FmMultiSourceMapper {
  @Mapping(source: 'map.owner', target: 'ownerName')
  FmRoom fromRealtime(Map map, String id);
}

@ShouldGenerate(
  r'''class FmMultiSourceClassMapperImpl extends FmMultiSourceClassMapper {
  FmMultiSourceClassMapperImpl();

  @override
  FmRoom fromRealtime(Map<dynamic, dynamic> map, FmOwner owner, String id) {
    return FmRoom(
      id: id,
      name: map['name'] as String,
      ownerName: owner.ownerName,
    );
  }
}''',
  contains: true,
)
@Mapper()
abstract class FmMultiSourceClassMapper {
  FmRoom fromRealtime(Map map, FmOwner owner, String id);
}

@ShouldGenerate(
  r'''class FmMultiSourceQualifiedMapperImpl extends FmMultiSourceQualifiedMapper {
  FmMultiSourceQualifiedMapperImpl();

  @override
  FmRoom fromRealtime(Map<dynamic, dynamic> map, FmOwner owner, String id) {
    return FmRoom(
      id: map['id'] as String,
      name: map['name'] as String,
      ownerName: owner.ownerName,
    );
  }
}''',
  contains: true,
)
@Mapper()
abstract class FmMultiSourceQualifiedMapper {
  @Mapping(source: 'map.id', target: 'id')
  @Mapping(source: 'owner.ownerName', target: 'ownerName')
  FmRoom fromRealtime(Map map, FmOwner owner, String id);
}

@ShouldGenerate(
  r'''class FmMappingAttributesMapperImpl extends FmMappingAttributesMapper {
  FmMappingAttributesMapperImpl();

  @override
  FmCustom fromMap(Map<String, dynamic> map) {
    return FmCustom(
      name: map['name'] as String,
      nickname: upperCase(map['nickname']),
      code: 7,
      slug: 'x-${map['name']}',
    );
  }
}''',
  contains: true,
)
@Mapper()
abstract class FmMappingAttributesMapper {
  @Mapping(target: 'hidden', ignore: true)
  @Mapping(target: 'code', constant: '7')
  @Mapping(target: 'slug', expression: "'x-\${map['name']}'")
  @Mapping(target: 'nickname', callable: upperCase)
  FmCustom fromMap(Map<String, dynamic> map);
}

@ShouldGenerate(
  r'''class FmMultiCallableMapperImpl extends FmMultiCallableMapper {
  FmMultiCallableMapperImpl();

  @override
  FmCustom fromMap(Map<String, dynamic> map) {
    return FmCustom(
      name: joinNames(map['first'], map['last']),
      nickname: map['nickname'] as String?,
      code: 1,
      slug: 's',
      hidden: map['hidden'] as String?,
    );
  }
}''',
  contains: true,
)
@Mapper()
abstract class FmMultiCallableMapper {
  @Mapping(target: 'name', source: 'first,last', callable: joinNames)
  @Mapping(target: 'code', constant: '1')
  @Mapping(target: 'slug', constant: 's')
  FmCustom fromMap(Map<String, dynamic> map);
}

@ShouldGenerate(
  r'''class FmConditionMapperImpl extends FmConditionMapper {
  FmConditionMapperImpl();

  @override
  FmCustom fromMap(Map<String, dynamic> map) {
    return FmCustom(
      name: map['name'] as String,
      nickname: map.containsKey('nick') ? map['nick'] as String? : null,
      code: 1,
      slug: 's',
      hidden: map['hidden'] as String?,
    );
  }
}''',
  contains: true,
)
@Mapper()
abstract class FmConditionMapper {
  @Mapping(
    target: 'nickname',
    source: 'nick',
    conditionExpression: "map.containsKey('nick')",
  )
  @Mapping(target: 'code', constant: '1')
  @Mapping(target: 'slug', constant: 's')
  FmCustom fromMap(Map<String, dynamic> map);
}

@ShouldGenerate(
  r'''class FmIgnoreRequiredMapperImpl extends FmIgnoreRequiredMapper {
  FmIgnoreRequiredMapperImpl();

  @override
  FmRequiredNullable fromMap(Map<String, dynamic> map) {
    return FmRequiredNullable(name: map['name'] as String, secret: null);
  }

  @override
  FmOptionalDefault fromMapDefault(Map<String, dynamic> map) {
    return FmOptionalDefault(name: map['name'] as String);
  }
}''',
  contains: true,
)
@Mapper()
abstract class FmIgnoreRequiredMapper {
  @Mapping(target: 'secret', ignore: true)
  FmRequiredNullable fromMap(Map<String, dynamic> map);

  @Mapping(target: 'level', ignore: true)
  FmOptionalDefault fromMapDefault(Map<String, dynamic> map);
}

@ShouldGenerate(
  r'''class FmBuiltMapperImpl extends FmBuiltMapper {
  FmBuiltMapperImpl();

  @override
  FmBuiltCard fromMap(Map<String, dynamic> map) {
    return FmBuiltCard(
      (b) => b
        ..name = map['name'] as String
        ..value = (map['value'] as num).toDouble(),
    );
  }

  @override
  FmBuiltDeck fromDeck(Map<String, dynamic> map) {
    return FmBuiltDeck(
      (b) => b
        ..id = map['id'] as String
        ..label = (map['label'] as String?)
        ..main = (FmBuiltCardBuilder()
          ..replace(fromMap(Map<String, dynamic>.from(map['main'] as Map))))
        ..tags = ListBuilder(List<String>.from(map['tags'] as List))
        ..cards = ListBuilder(
          (map['cards'] as List)
              .map<FmBuiltCard>(
                (e) => fromMap(Map<String, dynamic>.from(e as Map)),
              )
              .toList(),
        )
        ..counters = MapBuilder(Map<String, int>.from(map['counters'] as Map)),
    );
  }
}''',
  contains: true,
)
@Mapper()
abstract class FmBuiltMapper {
  FmBuiltCard fromMap(Map<String, dynamic> map);

  FmBuiltDeck fromDeck(Map<String, dynamic> map);
}

@ShouldGenerate(
  r'''class FmBuiltForceMapperImpl extends FmBuiltForceMapper {
  FmBuiltForceMapperImpl();

  @override
  FmBuiltDeckAbstract fromMap(Map<String, String?> map) {
    return FmBuiltDeckAbstract((b) => b..id = map['id']!);
  }
}''',
  contains: true,
)
@Mapper()
abstract class FmBuiltForceMapper {
  @Mapping(target: 'id', forceNonNull: true)
  FmBuiltDeckAbstract fromMap(Map<String, String?> map);
}

@ShouldGenerate(
  r'''class FmBuiltPrivateMapperImpl extends FmBuiltPrivateMapper {
  FmBuiltPrivateMapperImpl();

  @override
  FmBuiltDeck fromDeck(Map<String, dynamic> map) {
    return FmBuiltDeck(
      (b) => b
        ..id = map['id'] as String
        ..label = (map['label'] as String?)
        ..main = _mapMapToFmBuiltCard(
          Map<String, dynamic>.from(map['main'] as Map),
        )
        ..tags = ListBuilder(List<String>.from(map['tags'] as List))
        ..cards = ListBuilder(
          (map['cards'] as List)
              .map<FmBuiltCard>(
                (e) =>
                    _mapMapToFmBuiltCard(Map<String, dynamic>.from(e as Map))
                        .build(),
              )
              .toList(),
        )
        ..counters = MapBuilder(Map<String, int>.from(map['counters'] as Map)),
    );
  }

  FmBuiltCardBuilder _mapMapToFmBuiltCard(Map<String, dynamic> map) {
    return FmBuiltCardBuilder()..replace(
      FmBuiltCard(
        (b) => b
          ..name = map['name'] as String
          ..value = (map['value'] as num).toDouble(),
      ),
    );
  }
}''',
  contains: true,
)
@Mapper()
abstract class FmBuiltPrivateMapper {
  FmBuiltDeck fromDeck(Map<String, dynamic> map);
}
