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

Expression earlyReturnIfNull(String name) =>
    CodeExpression(Code('if ($name == null) return null'));

Expression throwArgumentErrorIfNull(String name) => CodeExpression(
      Code(
        'if ($name == null) throw ArgumentError.notNull(\'The argument \$$name must not be null.\')',
      ),
    );

Expression throwArgumentError(String message) =>
    CodeExpression(Code('throw ArgumentError(\'$message\')'));

Expression ifValueReturns(
        String name, Expression rightSize, Expression returnValue) =>
    CodeExpression(Block.of(
      [
        Code('if ('),
        Code(name),
        Code('=='),
        rightSize.code,
        Code(')'),
        returnValue.returned.code,
      ],
    ));

Expression builderClosure(List<(String, Expression)> expressions) {
  Expression closure = CodeExpression(Code('(b) => b'));
  for (final (name, expression) in expressions) {
    closure = closure.cascade(name).assign(expression);
  }
  return closure;
}
