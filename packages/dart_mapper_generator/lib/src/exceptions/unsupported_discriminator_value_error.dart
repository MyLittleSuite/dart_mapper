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
import 'package:source_gen/source_gen.dart';

/// Thrown when the `discriminatorValue`s of a dispatch method are not of a
/// supported type, or are not all of the same type.
class UnsupportedDiscriminatorValueError extends InvalidGenerationSourceError {
  UnsupportedDiscriminatorValueError._(super.message,
      {required Element element})
      : super(element: element);

  /// A value that is neither a String, int, double, bool nor an enum constant.
  UnsupportedDiscriminatorValueError.type({
    required MethodElement method,
    required String valueType,
  }) : this._(
          "Unsupported discriminatorValue of type '$valueType' on method "
          "'${method.name}'.\n"
          "Fix: Use a String, int, double, num, bool or enum constant.",
          element: method,
        );

  /// Values of different types on the same method.
  UnsupportedDiscriminatorValueError.mixed({
    required MethodElement method,
    required String first,
    required String other,
  }) : this._(
          "The discriminatorValues of method '${method.name}' have different "
          "types ('$first' and '$other').\n"
          "Fix: Use values of the same type for all the @SubclassMapping of "
          "a method.",
          element: method,
        );
}
