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

// Golden test source for additional class <-> Map coverage: converters vs
// plain primitives, abstract methods, conditional defaults, Set/Iterable
// fields, non-String map keys, raw Map sources and absence of re-keying.

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

class McCard {
  final String label;
  const McCard({required this.label});
}

class McStamped {
  final int count;
  final String name;
  final bool flag;
  final double ratio;
  final num amount;
  final DateTime at;

  const McStamped({
    required this.count,
    required this.name,
    required this.flag,
    required this.ratio,
    required this.amount,
    required this.at,
  });
}

// ----- 1. Converters never hijack plain primitive fields -----

@ShouldGenerate(
  r'''Map<String, dynamic> toMap(McStamped dto) {
    return {
      'count': dto.count,
      'name': dto.name,
      'flag': dto.flag,
      'ratio': dto.ratio,
      'amount': dto.amount,
      'at': toMillis(dto.at),
    };
  }''',
  contains: true,
)
@Mapper()
abstract class McToMapConverterMapper {
  Map<String, dynamic> toMap(McStamped dto);

  int toMillis(DateTime date) => date.millisecondsSinceEpoch;
}

@ShouldGenerate(
  r'''McStamped fromMap(Map<String, dynamic> map) {
    return McStamped(
      count: map['count'] as int,
      name: map['name'] as String,
      flag: map['flag'] as bool,
      ratio: (map['ratio'] as num).toDouble(),
      amount: map['amount'] as num,
      at: fromMillis(map['at'] as int),
    );
  }''',
  contains: true,
)
@Mapper()
abstract class McFromMapConverterMapper {
  McStamped fromMap(Map<String, dynamic> map);

  DateTime fromMillis(int milliseconds) =>
      DateTime.fromMillisecondsSinceEpoch(milliseconds);
}

// ----- 2. Abstract methods are not converters in Map -> class -----

class McOther {
  final String label;
  const McOther({required this.label});
}

class McHolder {
  final McCard card;
  const McHolder({required this.card});
}

@ShouldGenerate(
  r'''McHolder fromMap(Map<String, dynamic> map) {
    return McHolder(
      card: _mapMapToMcCard(Map<String, dynamic>.from(map['card'] as Map)),
    );
  }''',
  contains: true,
)
@ShouldGenerate(
  r'''McCard fromOther(McOther other) {
    return McCard(label: other.label);
  }''',
  contains: true,
)
@Mapper()
abstract class McAbstractNotConverterMapper {
  McHolder fromMap(Map<String, dynamic> map);

  // Abstract: a mapping method of its own, never a converter for 'card'.
  McCard fromOther(McOther other);
}

// ----- 3. conditionExpression + defaultValue (class -> Map) -----

class McCond {
  final String? secret;
  const McCond({this.secret});
}

@ShouldGenerate(
  r'''return {
      'secret': dto.secret!.length > 3 ? dto.secret ?? 'hidden' : 'hidden',
    };''',
  contains: true,
)
@Mapper()
abstract class McConditionDefaultMapper {
  @Mapping(
    target: 'secret',
    source: 'secret',
    conditionExpression: 'dto.secret!.length > 3',
    defaultValue: 'hidden',
  )
  Map<String, dynamic> toMap(McCond dto);
}

// ----- 4. Set and Iterable of classes (class -> Map) -----

class McCollections {
  final Set<McCard> cardSet;
  final Iterable<McCard> cardIterable;
  const McCollections({required this.cardSet, required this.cardIterable});
}

@ShouldGenerate(
  r'''return {
      'cardSet': dto.cardSet.map((item) => _mapMcCardToMap(item)).toList(),
      'cardIterable': dto.cardIterable
          .map((item) => _mapMcCardToMap(item))
          .toList(),
    };''',
  contains: true,
)
@Mapper()
abstract class McSetIterableMapper {
  Map<String, dynamic> toMap(McCollections dto);
}

// ----- 5. Map<int, Class> keys pass through (both directions) -----

class McIntKeyed {
  final Map<int, McCard> cards;
  const McIntKeyed({required this.cards});
}

@ShouldGenerate(
  r'''return {
      'cards': dto.cards.map(
        (key, value) => MapEntry(key, _mapMcCardToMap(value)),
      ),
    };''',
  contains: true,
)
@Mapper()
abstract class McIntKeyToMapMapper {
  Map<String, dynamic> toMap(McIntKeyed dto);
}

@ShouldGenerate(
  r'''return McIntKeyed(
      cards: (map['cards'] as Map).map<int, McCard>(
        (key, value) => MapEntry(
          key as int,
          _mapMapToMcCard(Map<String, dynamic>.from(value as Map)),
        ),
      ),
    );''',
  contains: true,
)
@Mapper()
abstract class McIntKeyFromMapMapper {
  McIntKeyed fromMap(Map<String, dynamic> map);
}

// ----- 6. Explicit Map<dynamic, dynamic> source -----

@ShouldGenerate(
  r'''McCard fromMap(Map<dynamic, dynamic> map) {
    return McCard(label: map['label'] as String);
  }''',
  contains: true,
)
@Mapper()
abstract class McDynamicSourceMapper {
  McCard fromMap(Map<dynamic, dynamic> map);
}

// ----- 7. No automatic re-keying -----

class McKeyed {
  final Map<String, McCard> members;
  const McKeyed({required this.members});
}

@ShouldGenerate(
  r'''return {
      'members': dto.members.map(
        (key, value) => MapEntry(key, _mapMcCardToMap(value)),
      ),
    };''',
  contains: true,
)
@ShouldGenerate(
  r'''return McKeyed(
      members: (map['members'] as Map).map<String, McCard>(
        (key, value) => MapEntry(
          key as String,
          _mapMapToMcCard(Map<String, dynamic>.from(value as Map)),
        ),
      ),
    );''',
  contains: true,
)
@Mapper()
abstract class McNoRekeyMapper {
  Map<String, dynamic> toMap(McKeyed dto);

  McKeyed fromMap(Map<String, dynamic> map);
}
