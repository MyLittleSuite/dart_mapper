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

import 'package:analyzer/dart/element/element.dart';
import 'package:dart_mapper_generator/src/exceptions/map_key_path_conflict_error.dart';

/// A node of the tree describing the (possibly nested) keys of a map built by
/// a class to Map mapping method.
sealed class MapKeyNode<T> {
  const MapKeyNode();
}

/// A key holding a value.
final class MapKeyLeaf<T> extends MapKeyNode<T> {
  final T value;

  const MapKeyLeaf(this.value);
}

/// A key holding a nested map, whose keys are [children].
final class MapKeyBranch<T> extends MapKeyNode<T> {
  final Map<String, MapKeyNode<T>> children;

  const MapKeyBranch(this.children);
}

/// Groups [entries] whose path uses dot notation (`address.street`) into a
/// tree of nested keys. Keys sharing a prefix end up in the same branch and
/// the insertion order is preserved (a branch is positioned where its first
/// key appears).
///
/// Throws [MapKeyPathConflictError] when a segment is empty, a path is
/// repeated, or a key is used both as a value and as a container of other
/// keys (`address` and `address.street`).
MapKeyBranch<T> buildMapKeyTree<T>(
  Iterable<(String path, T value)> entries, {
  Element? element,
}) {
  final root = <String, MapKeyNode<T>>{};

  for (final (path, value) in entries) {
    final segments = path.split('.');
    if (segments.any((segment) => segment.isEmpty)) {
      throw MapKeyPathConflictError(
        path: path,
        conflictDescription: 'it contains an empty segment',
        element: element,
      );
    }

    var current = root;
    for (var i = 0; i < segments.length - 1; i++) {
      final segment = segments[i];
      final existing = current[segment];
      switch (existing) {
        case null:
          final branch = <String, MapKeyNode<T>>{};
          current[segment] = MapKeyBranch(branch);
          current = branch;
        case MapKeyBranch<T>(:final children):
          current = children;
        case MapKeyLeaf<T>():
          throw MapKeyPathConflictError(
            path: path,
            conflictDescription:
                "'${segments.sublist(0, i + 1).join('.')}' is already mapped "
                'as a whole value',
            element: element,
          );
      }
    }

    final last = segments.last;
    final existing = current[last];
    switch (existing) {
      case null:
        current[last] = MapKeyLeaf(value);
      case MapKeyBranch<T>():
        throw MapKeyPathConflictError(
          path: path,
          conflictDescription: 'it is also used as the prefix of nested keys',
          element: element,
        );
      case MapKeyLeaf<T>():
        throw MapKeyPathConflictError(
          path: path,
          conflictDescription: 'it is mapped more than once',
          element: element,
        );
    }
  }

  return MapKeyBranch(root);
}
