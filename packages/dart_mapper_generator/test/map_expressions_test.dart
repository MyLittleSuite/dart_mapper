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

import 'package:code_builder/code_builder.dart';
import 'package:dart_mapper_generator/src/misc/map_expressions.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';

String emit(Expression expression) {
  final source = expression.accept(DartEmitter(useNullSafetySyntax: true));

  return DartFormatter(
    languageVersion: DartFormatter.latestShortStyleLanguageVersion,
  ).formatStatement('$source;').trim().replaceFirst(RegExp(r';$'), '');
}

void main() {
  group('mapRead()', () {
    test('reads a single key with an index access', () {
      expect(emit(mapRead('map', ['uid'])), "map['uid']");
    });

    test('walks nested maps, every intermediate level being nullable', () {
      expect(
        emit(mapRead('map', ['address', 'street'])),
        "(map['address'] as Map?)?['street']",
      );
      expect(
        emit(mapRead('map', ['address', 'geo', 'zip'])),
        "((map['address'] as Map?)?['geo'] as Map?)?['zip']",
      );
    });

    test('uses the given map name', () {
      expect(emit(mapRead('json', ['a'])), "json['a']");
    });

    test('escapes quotes and dollar signs in keys', () {
      expect(emit(mapRead('map', [r"it's$"])), r"map['it\'s\$']");
    });
  });

  group('CastExpressionExtension', () {
    test('castTo() casts without extra parentheses', () {
      expect(
          emit(mapRead('map', ['a']).castTo('String?')), "map['a'] as String?");
    });

    test('orElse() falls back without extra parentheses', () {
      expect(
        emit(mapRead('map', ['a']).castTo('int?').orElse(literalNum(3))),
        "map['a'] as int? ?? 3",
      );
    });

    test('castTo() can be parenthesized to chain calls', () {
      expect(
        emit(
          mapRead('map', ['a'])
              .castTo('num')
              .parenthesized
              .property('toDouble')
              .call([]),
        ),
        "(map['a'] as num).toDouble()",
      );
    });
  });
}
