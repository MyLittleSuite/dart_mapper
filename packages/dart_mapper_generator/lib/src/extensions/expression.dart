/*
 * Copyright (c) 2024 MyLittleSuite
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

extension ExpressionExtension on Expression {
  Expression arrowReturn(Expression expression) =>
      assign(literal('')).greaterThan(literal(expression));

  Expression conditionalNull(Expression whenTrue) =>
      notEqualTo(literalNull).conditional(literal(whenTrue), literalNull);

  Expression propertyToList({bool growable = true}) =>
      property('toList').call([], {'growable': literal(growable)});

  Expression propertyToSet() => property('toSet').call([]);

  Expression dateTimeToIsoString({bool nullable = false}) {
    final functionName = 'toIso8601String';
    return (nullable ? nullSafeProperty(functionName) : property(functionName))
        .call([]);
  }

  Expression stringToDateTime({bool nullable = false}) {
    final dateTimeRefer = refer('DateTime');
    return (nullable
            ? dateTimeRefer.property('tryParse')
            : dateTimeRefer.property('parse'))
        .call([nullable ? ifNullThen(literal('')) : this]);
  }

  Expression stringToInt({bool nullable = false}) {
    final intRefer = refer('int');
    return (nullable
            ? intRefer.property('tryParse')
            : intRefer.property('parse'))
        .call([nullable ? ifNullThen(literal('')) : this]);
  }

  Expression stringToDouble({bool nullable = false}) {
    final doubleRefer = refer('double');
    return (nullable
            ? doubleRefer.property('tryParse')
            : doubleRefer.property('parse'))
        .call([nullable ? ifNullThen(literal('')) : this]);
  }

  Expression stringToNum({bool nullable = false}) {
    final numRefer = refer('num');
    return (nullable
            ? numRefer.property('tryParse')
            : numRefer.property('parse'))
        .call([nullable ? ifNullThen(literal('')) : this]);
  }

  Expression propertyToString({bool nullable = false}) {
    final functionName = 'toString';
    return (nullable ? nullSafeProperty(functionName) : property(functionName))
        .call([]);
  }

  Expression propertyToInt({bool nullable = false}) {
    final functionName = 'toInt';
    return (nullable ? nullSafeProperty(functionName) : property(functionName))
        .call([]);
  }

  Expression propertyToDouble({bool nullable = false}) {
    final functionName = 'toDouble';
    return (nullable ? nullSafeProperty(functionName) : property(functionName))
        .call([]);
  }
}
