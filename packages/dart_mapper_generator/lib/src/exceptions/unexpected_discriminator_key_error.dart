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

/// Thrown when @DiscriminatorKey is used where it has no effect: on a method
/// without @SubclassMapping, on a class -> class dispatch method, or on the
/// mapper class.
class UnexpectedDiscriminatorKeyError extends InvalidGenerationSourceError {
  UnexpectedDiscriminatorKeyError._(super.message, {required Element element})
      : super(element: element);

  /// @DiscriminatorKey on a method with no @SubclassMapping.
  UnexpectedDiscriminatorKeyError.withoutSubclassMapping({
    required MethodElement method,
  }) : this._(
          "Method '${method.name}' has a @DiscriminatorKey but no "
          "@SubclassMapping.\n"
          "Fix: Add the @SubclassMapping annotations, or remove "
          "@DiscriminatorKey.",
          element: method,
        );

  /// @DiscriminatorKey on a class -> class dispatch method.
  UnexpectedDiscriminatorKeyError.onTypeDispatch({
    required MethodElement method,
  }) : this._(
          "Method '${method.name}' dispatches between classes: "
          "@DiscriminatorKey only applies when the source or the target is a "
          "Map.\n"
          "Fix: Remove @DiscriminatorKey.",
          element: method,
        );

  /// @DiscriminatorKey on the mapper class.
  UnexpectedDiscriminatorKeyError.onClass({required ClassElement mapperClass})
      : this._(
          "@DiscriminatorKey on class '${mapperClass.name}' is not "
          "supported: it must annotate a method.\n"
          "Fix: Move @DiscriminatorKey on the dispatch method.",
          element: mapperClass,
        );
}
