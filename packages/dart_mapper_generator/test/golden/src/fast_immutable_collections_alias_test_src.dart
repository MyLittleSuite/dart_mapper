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

// Golden test source for the collections of fast_immutable_collections
// imported with a prefix: the classes named by the generated code (ListSet,
// ListMap, IMapOfSets) carry it, the extension methods (toIList, toISet,
// toIMap) do not need it.

// ignore_for_file: depend_on_referenced_packages

import 'package:dart_mapper/dart_mapper.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart'
    as fic;
import 'package:source_gen_test/annotations.dart';

class FicAliasSource {
  final List<String> items;
  final List<String> queue;
  final Map<String, int> ratings;
  final Map<String, Set<String>> groups;

  const FicAliasSource({
    required this.items,
    required this.queue,
    required this.ratings,
    required this.groups,
  });
}

class FicAliasTarget {
  final fic.IList<String> items;
  final fic.ListSet<String> queue;
  final fic.ListMap<String, int> ratings;
  final fic.IMapOfSets<String, String> groups;

  const FicAliasTarget({
    required this.items,
    required this.queue,
    required this.ratings,
    required this.groups,
  });
}

@ShouldGenerate(
  r'''class FicAliasMapperImpl extends FicAliasMapper {
  FicAliasMapperImpl();

  @override
  FicAliasTarget toTarget(FicAliasSource source) {
    return FicAliasTarget(
      items: source.items.toIList(),
      queue: fic.ListSet.of(source.queue),
      ratings: fic.ListMap.of(source.ratings),
      groups: fic.IMapOfSets(source.groups),
    );
  }

  @override
  FicAliasTarget fromMap(Map<String, dynamic> map) {
    return FicAliasTarget(
      items: List<String>.from(map['items'] as Iterable).toIList(),
      queue: fic.ListSet.of(List<String>.from(map['queue'] as Iterable)),
      ratings: fic.ListMap.of(Map<String, int>.from(map['ratings'] as Map)),
      groups: map['groups'] as fic.IMapOfSets<String, String>,
    );
  }
}''',
  contains: true,
)
@Mapper()
abstract class FicAliasMapper {
  FicAliasTarget toTarget(FicAliasSource source);

  FicAliasTarget fromMap(Map<String, dynamic> map);
}
