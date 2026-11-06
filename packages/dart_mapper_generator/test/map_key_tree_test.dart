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

import 'package:dart_mapper_generator/src/exceptions/map_key_path_conflict_error.dart';
import 'package:dart_mapper_generator/src/misc/map_key_tree.dart';
import 'package:test/test.dart';

void main() {
  group('buildMapKeyTree()', () {
    test('keeps flat keys as leaves, in insertion order', () {
      final tree = buildMapKeyTree<int>([('b', 1), ('a', 2)]);

      expect(tree.children.keys, ['b', 'a']);
      expect((tree.children['b'] as MapKeyLeaf<int>).value, 1);
      expect((tree.children['a'] as MapKeyLeaf<int>).value, 2);
    });

    test('groups keys sharing a prefix into a branch', () {
      final tree = buildMapKeyTree<int>([
        ('address.street', 1),
        ('name', 2),
        ('address.city', 3),
      ]);

      // The branch is placed where its first key appears.
      expect(tree.children.keys, ['address', 'name']);

      final address = tree.children['address'] as MapKeyBranch<int>;
      expect(address.children.keys, ['street', 'city']);
      expect((address.children['street'] as MapKeyLeaf<int>).value, 1);
      expect((address.children['city'] as MapKeyLeaf<int>).value, 3);
    });

    test('supports several levels of nesting', () {
      final tree = buildMapKeyTree<int>([
        ('a.b.c', 1),
        ('a.b.d', 2),
        ('a.e', 3),
      ]);

      final a = tree.children['a'] as MapKeyBranch<int>;
      expect(a.children.keys, ['b', 'e']);
      final b = a.children['b'] as MapKeyBranch<int>;
      expect(b.children.keys, ['c', 'd']);
    });

    test('is empty without entries', () {
      expect(buildMapKeyTree<int>([]).children, isEmpty);
    });

    test('throws when a key is also the prefix of another key', () {
      expect(
        () => buildMapKeyTree<int>([('address', 1), ('address.street', 2)]),
        throwsA(
          isA<MapKeyPathConflictError>().having(
            (e) => e.message,
            'message',
            contains("'address' is already mapped as a whole value"),
          ),
        ),
      );
    });

    test('throws when a prefix is later used as a whole key', () {
      expect(
        () => buildMapKeyTree<int>([('address.street', 1), ('address', 2)]),
        throwsA(
          isA<MapKeyPathConflictError>().having(
            (e) => e.message,
            'message',
            contains('it is also used as the prefix of nested keys'),
          ),
        ),
      );
    });

    test('throws when the same path is mapped twice', () {
      expect(
        () => buildMapKeyTree<int>([('a.b', 1), ('a.b', 2)]),
        throwsA(
          isA<MapKeyPathConflictError>().having(
            (e) => e.message,
            'message',
            contains('it is mapped more than once'),
          ),
        ),
      );
    });

    for (final path in ['', '.a', 'a.', 'a..b']) {
      test("throws on the empty segment of '$path'", () {
        expect(
          () => buildMapKeyTree<int>([(path, 1)]),
          throwsA(
            isA<MapKeyPathConflictError>().having(
              (e) => e.message,
              'message',
              contains('it contains an empty segment'),
            ),
          ),
        );
      });
    }
  });
}
