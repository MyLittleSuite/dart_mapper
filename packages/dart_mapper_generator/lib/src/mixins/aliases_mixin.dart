/*
 *
 *  Copyright (c) 2026 MyLittleSuite
 *
 *  Permission is hereby granted, free of charge, to any person
 *  obtaining a copy of this software and associated documentation
 *  files (the "Software"), to deal in the Software without
 *  restriction, including without limitation the rights to use,
 *  copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the
 *  Software is furnished to do so, subject to the following
 *  conditions:
 *
 *  The above copyright notice and this permission notice shall be
 *  included in all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 *  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 *  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 *  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 *  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 *  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 *  OTHER DEALINGS IN THE SOFTWARE.
 *
 */

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dart_mapper_generator/src/misc/strings.dart';

mixin AliasesMixin {
  Map<Uri, String>? get importAliases;

  String? resolvePrefix(DartType type) =>
      importAliases?[type.element?.library?.firstFragment.source.uri];

  String resolveType(DartType type, {bool withNullability = false}) =>
      chainDot([
        importAliases?[type.element?.library?.firstFragment.source.uri],
        chain([
          _withoutNullability(type),
          if (withNullability) '?',
        ]),
      ]);

  /// Like [resolveType], but the import prefix is applied to every type
  /// argument too (`Map<String, models.Item?>`). The nullability of the type
  /// and of its arguments is kept.
  String resolveTypeDeep(DartType type) {
    if (type is! InterfaceType) {
      return type.getDisplayString();
    }

    final name = type.element.name;
    if (name == null) {
      return type.getDisplayString();
    }

    final arguments = type.typeArguments;

    return chain([
      chainDot([
        importAliases?[type.element.library.firstFragment.source.uri],
        name,
      ]),
      if (arguments.isNotEmpty)
        '<${arguments.map(resolveTypeDeep).join(', ')}>',
      if (type.nullabilitySuffix == NullabilitySuffix.question) '?',
    ]);
  }

  /// The display string of [type] without the nullability suffix of the type
  /// itself; nullability of type arguments (`Map<String, Object?>`) is kept.
  String _withoutNullability(DartType type) {
    final display = type.getDisplayString();

    return display.endsWith('?')
        ? display.substring(0, display.length - 1)
        : display;
  }

  String resolveConstructor(ConstructorElement constructor) => chainDot([
        importAliases?[constructor.library.firstFragment.source.uri],
        constructor.displayName,
      ]);
}
