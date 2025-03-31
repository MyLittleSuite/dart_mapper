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
import 'package:dart_mapper_generator/src/extensions/expression.dart';

Expression throwArgumentError(String message) =>
    refer('ArgumentError').call([literal(message)]).thrown;

Expression throwArgumentErrorNotNull(String name) => refer('ArgumentError')
    .property('notNull')
    .call([literal('The argument \$$name must not be null.')]).thrown;

Expression returnSwitch(
  Expression condition, {
  required Iterable<(Expression, Expression)> cases,
  Expression? otherwise,
  bool ignoreUnreachableCode = false,
}) =>
    CodeExpression(Block((b) {
      b.statements.addAll([
        Code('switch'),
        condition.parenthesized.code,
        Code('{'),
      ]);

      for (final element in cases) {
        b.statements.addAll([
          element.$1.arrowReturn(element.$2).code,
          Code(','),
        ]);
      }

      if (otherwise != null) {
        b.statements.addAll([
          if (ignoreUnreachableCode) Code('// ignore:unreachable_switch_case'),
          refer('_').arrowReturn(otherwise).code,
          Code(','),
        ]);
      }

      b.statements.add(Code('}'));
    }));

Expression builderClosure(List<(String, Expression)> expressions) {
  Expression closure = CodeExpression(Code('(b) => b'));
  for (final (name, expression) in expressions) {
    closure = closure.cascade(name).assign(expression);
  }
  return closure;
}
