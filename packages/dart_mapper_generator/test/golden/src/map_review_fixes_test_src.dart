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

// Golden test source for the fixes that came out of the independent review of
// the class <-> Map feature: shared converter lookup, callables on typed
// sources, same-named classes of different libraries, import prefixes,
// verbatim constants and Map -> Map detection.

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

import 'alias_models.dart' as models;

// ----- 1. One converter lookup for both directions -----

class MrfEvent {
  final int count;
  final List<int> counts;
  final DateTime at;

  const MrfEvent({
    required this.count,
    required this.counts,
    required this.at,
  });
}

@ShouldGenerate(
  r'''return {'count': dto.count, 'counts': dto.counts, 'at': toMillis(dto.at)};''',
  contains: true,
)
@ShouldGenerate(
  r'''    return MrfEvent(
      count: map['count'] as int,
      counts: List<int>.from(map['counts'] as Iterable),
      at: fromMillis(map['at'] as int),
    );''',
  contains: true,
)
@Mapper()
abstract class MrfConverterMapper {
  Map<String, dynamic> toMap(MrfEvent dto);

  MrfEvent fromMap(Map<String, dynamic> map);

  int toMillis(DateTime date) => date.millisecondsSinceEpoch;

  DateTime fromMillis(int milliseconds) =>
      DateTime.fromMillisecondsSinceEpoch(milliseconds);
}

// ----- 2. Callables get a cast argument on typed sources -----

class MrfNick {
  final String nickname;

  const MrfNick({required this.nickname});
}

class MrfFullName {
  final String full;

  const MrfFullName({required this.full});
}

String mrfUpper(String value) => value.toUpperCase();

String mrfJoin(String a, String b) => '$a $b';

@ShouldGenerate(
  r'''nickname: mrfUpper(map['nickname'] as String)''',
  contains: true,
)
@Mapper()
abstract class MrfCallableObjectKeyMapper {
  @Mapping(target: 'nickname', callable: mrfUpper)
  MrfNick fromMap(Map<Object?, Object?> map);
}

@ShouldGenerate(
  r'''nickname: mrfUpper(map['nickname'] as String)''',
  contains: true,
)
@Mapper()
abstract class MrfCallableObjectValueMapper {
  @Mapping(target: 'nickname', callable: mrfUpper)
  MrfNick fromMap(Map<String, Object?> map);
}

@ShouldGenerate(
  r'''full: mrfJoin(map['a'] as String, map['b'] as String)''',
  contains: true,
)
@Mapper()
abstract class MrfMultiCallableObjectValueMapper {
  @Mapping(target: 'full', source: 'a,b', callable: mrfJoin)
  MrfFullName fromMap(Map<String, Object?> map);
}

// ----- 3. Same-named classes of different libraries -----

class AliasObject {
  final String label;

  const AliasObject({required this.label});
}

class MrfTwins {
  final AliasObject local;
  final models.AliasObject remote;

  const MrfTwins({required this.local, required this.remote});
}

@ShouldGenerate(
  r'''      'local': _mapAliasObjectToMap(dto.local),
      'remote': _mapModelsAliasObjectToMap(dto.remote),''',
  contains: true,
)
@ShouldGenerate(
  r'''
      'description': aliasObject.description,
      'alias': aliasObject.alias.name,''',
  contains: true,
)
@ShouldGenerate(
  r'''return {'label': aliasObject.label};''',
  contains: true,
)
@Mapper()
abstract class MrfTwinsToMapMapper {
  Map<String, dynamic> toMap(MrfTwins dto);
}

@ShouldGenerate(
  r'''      local: _mapMapToAliasObject(
        Map<String, dynamic>.from(map['local'] as Map),
      ),
      remote: _mapMapToModelsAliasObject(
        Map<String, dynamic>.from(map['remote'] as Map),
      ),''',
  contains: true,
)
@Mapper()
abstract class MrfTwinsFromMapMapper {
  MrfTwins fromMap(Map<String, dynamic> map);
}

// ----- 3b. Generic classes over same-named classes of different libraries -----

class MrfBox<T> {
  final T value;

  const MrfBox({required this.value});
}

class MrfBoxedTwins {
  final MrfBox<AliasObject> local;
  final MrfBox<models.AliasObject> remote;

  const MrfBoxedTwins({required this.local, required this.remote});
}

@ShouldGenerate(
  r'''      'local': _mapMrfBoxOfAliasObjectToMap(dto.local),
      'remote': _mapMrfBoxOfModelsAliasObjectToMap(dto.remote),''',
  contains: true,
)
@ShouldGenerate(
  r'''  Map<String, dynamic> _mapMrfBoxOfModelsAliasObjectToMap(
    MrfBox<models.AliasObject> mrfBoxAliasObject,
  ) {
    return {'value': _mapModelsAliasObjectToMap(mrfBoxAliasObject.value)};
  }''',
  contains: true,
)
@Mapper()
abstract class MrfBoxedTwinsToMapMapper {
  Map<String, dynamic> toMap(MrfBoxedTwins dto);
}

@ShouldGenerate(
  r'''      local: _mapMapToMrfBoxOfAliasObject(
        Map<String, dynamic>.from(map['local'] as Map),
      ),
      remote: _mapMapToMrfBoxOfModelsAliasObject(
        Map<String, dynamic>.from(map['remote'] as Map),
      ),''',
  contains: true,
)
@ShouldGenerate(
  r'''  MrfBox<models.AliasObject> _mapMapToMrfBoxOfModelsAliasObject(
    Map<String, dynamic> map,
  ) {
    return MrfBox(
      value: _mapMapToModelsAliasObject(
        Map<String, dynamic>.from(map['value'] as Map),
      ),
    );
  }''',
  contains: true,
)
@Mapper()
abstract class MrfBoxedTwinsFromMapMapper {
  MrfBoxedTwins fromMap(Map<String, dynamic> map);
}

// ----- 4. Import prefixes -----

class MrfKinds {
  final models.AliasEnum kind;

  const MrfKinds({required this.kind});
}

@ShouldGenerate(
  r'''MrfKinds fromMap(Map<String, models.AliasEnum?> map)''',
  contains: true,
)
@Mapper()
abstract class MrfPrefixedParameterMapper {
  @Mapping(target: 'kind', forceNonNull: true)
  MrfKinds fromMap(Map<String, models.AliasEnum?> map);
}

class MrfInner {
  final models.AliasEnum kind;

  const MrfInner({required this.kind});
}

class MrfWrap {
  final MrfInner inner;

  const MrfWrap({required this.inner});
}

@ShouldGenerate(
  r'''Map<String, models.AliasEnum>.from(map['inner'] as Map)''',
  contains: true,
)
@ShouldGenerate(
  r'''MrfInner innerFrom(Map<String, models.AliasEnum> map)''',
  contains: true,
)
@Mapper()
abstract class MrfPrefixedNestedArgumentMapper {
  MrfWrap fromMap(Map<String, dynamic> map);

  MrfInner innerFrom(Map<String, models.AliasEnum> map);
}

class MrfStamped {
  final MrfStamp stamp;

  const MrfStamped({required this.stamp});
}

class MrfStamp {
  final String value;

  const MrfStamp(this.value);
}

@ShouldGenerate(
  r'''stamp: stampFrom(map['stamp'] as models.AliasEnum)''',
  contains: true,
)
@Mapper()
abstract class MrfPrefixedConverterMapper {
  MrfStamped fromMap(Map<String, dynamic> map);

  MrfStamp stampFrom(models.AliasEnum kind) => MrfStamp(kind.name);
}

// ----- 5b. Constants are emitted verbatim -----

const mrfLabel = 'label';

class MrfConstants {
  final String name;
  final String label;
  final DateTime created;
  final int version;

  const MrfConstants({
    required this.name,
    required this.label,
    required this.created,
    required this.version,
  });
}

@ShouldGenerate(
  r'''    return {
      'name': dto.name,
      'label': mrfLabel,
      'created': DateTime(2020),
      'version': 2,
      'kind': 'dto',
    };''',
  contains: true,
)
@Mapper()
abstract class MrfVerbatimConstantMapper {
  @Mapping(target: 'label', constant: 'mrfLabel')
  @Mapping(target: 'created', constant: 'DateTime(2020)')
  @Mapping(target: 'version', constant: '2')
  @Mapping(target: 'kind', constant: "'dto'")
  Map<String, dynamic> toMap(MrfConstants dto);
}
