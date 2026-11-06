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

// Golden test source for the CodeRabbit review findings of the Map -> class
// side.

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

// ----- 1. forceNonNull before a callable -----

String crUpper(String value) => value.toUpperCase();

String crUpperNullable(String? value) => (value ?? '').toUpperCase();

class CrNick {
  final String nick;

  const CrNick({required this.nick});
}

@ShouldGenerate(
  r'''return CrNick(nick: crUpperNullable(map['nick']!));''',
  contains: true,
)
@Mapper()
abstract class CrForceCallableMapper {
  @Mapping(target: 'nick', callable: crUpperNullable, forceNonNull: true)
  CrNick fromMap(Map<String, String?> map);
}

// ----- 3. recursive multi-source -----

class CrTree {
  final String name;
  final int depth;
  final List<CrTree> children;

  const CrTree({
    required this.name,
    required this.depth,
    required this.children,
  });
}

@ShouldGenerate(
  r'''    return CrTree(
      name: map['name'] as String,
      depth: level,
      children: (map['children'] as Iterable)
          .map<CrTree>(
            (e) => _mapMapToCrTree(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
  }

  CrTree _mapMapToCrTree(Map<String, dynamic> map) {
    return CrTree(
      name: map['name'] as String,
      depth: map['depth'] as int,
      children: (map['children'] as Iterable)
          .map<CrTree>(
            (e) => _mapMapToCrTree(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );''',
  contains: true,
)
@Mapper()
abstract class CrRecursiveMapper {
  @Mapping(target: 'depth', source: 'level')
  CrTree fromMap(Map<String, dynamic> map, int level);
}

// ----- 4b. compatible iterable elements are still accepted -----

class CrNumbers {
  final List<double> values;
  final List<int> counts;

  const CrNumbers({required this.values, required this.counts});
}

@ShouldGenerate(
  r'''    return CrNumbers(
      values: (map['values'] as Iterable)
          .map<double>((e) => (e as num).toDouble())
          .toList(),
      counts: List<int>.from(map['counts'] as Iterable),
    );''',
  contains: true,
)
@Mapper()
abstract class CrElementCompatibleMapper {
  CrNumbers fromMap(Map<String, List<num>> map);
}

// ----- 5. Set round trip -----

class CrSets {
  final Set<int> ids;
  final List<String> names;

  const CrSets({required this.ids, required this.names});
}

@ShouldGenerate(
  r'''    return CrSets(
      ids: Set<int>.from(map['ids'] as Iterable),
      names: List<String>.from(map['names'] as Iterable),
    );''',
  contains: true,
)
@Mapper()
abstract class CrSetMapper {
  Map<String, dynamic> toMap(CrSets sets);

  CrSets fromMap(Map<String, dynamic> map);
}

// ----- 6. forceNonNull on nullable target -----

class CrOptional {
  final String? label;

  const CrOptional({this.label});
}

@ShouldGenerate(
  r'''return CrOptional(label: map['label']!);''',
  contains: true,
)
@Mapper()
abstract class CrNullableForceMapper {
  @Mapping(target: 'label', forceNonNull: true)
  CrOptional fromMap(Map<String, String?> map);
}

// ----- 7. generic parameter -----

class CrAddress {
  final String city;

  const CrAddress({required this.city});
}

class CrCity {
  final String city;

  const CrCity({required this.city});
}

class CrBox<T> {
  final T value;

  const CrBox(this.value);
}

class CrHolder {
  final CrCity city;

  const CrHolder({required this.city});
}

@ShouldGenerate(
  r'''    return CrHolder(city: toCity(box.value));
  }

  @override
  CrCity toCity(CrAddress address) {
    return CrCity(city: address.city);''',
  contains: true,
)
@Mapper()
abstract class CrGenericMapper {
  @Mapping(target: 'city', source: 'box.value')
  CrHolder fromBox(CrBox<CrAddress> box, Map<String, dynamic> map);

  CrCity toCity(CrAddress address);
}
