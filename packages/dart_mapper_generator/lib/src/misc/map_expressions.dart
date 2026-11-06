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

/// Builds the expression reading [keys] from the map held by [mapName].
///
/// A single key is a plain index access (`map['k']`). More keys walk nested
/// maps, every intermediate level being nullable:
/// `(map['a'] as Map?)?['b']`.
Expression mapRead(String mapName, List<String> keys) {
  assert(keys.isNotEmpty, 'At least one key is required.');

  Expression current = refer(mapName);
  for (var i = 0; i < keys.length; i++) {
    final key = literalString(keys[i].replaceAll(r'$', r'\$'));
    current = i == 0
        ? current.index(key)
        : CodeExpression(
            Block.of([current.code, Code('?['), key.code, Code(']')]),
          );

    if (i < keys.length - 1) {
      current = current.castTo('Map?').parenthesized;
    }
  }

  return current;
}

extension CastExpressionExtension on Expression {
  /// `this as type`, without the parentheses code_builder wraps around casts.
  Expression castTo(String type) => CodeExpression(
        Block.of([code, Code(' as '), refer(type).code]),
      );

  /// `this ?? fallback`, without the parentheses code_builder adds.
  Expression orElse(Expression fallback) => CodeExpression(
        Block.of([code, Code(' ?? '), fallback.code]),
      );
}
