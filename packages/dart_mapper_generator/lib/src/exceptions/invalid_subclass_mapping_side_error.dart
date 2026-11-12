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

/// Thrown when a @SubclassMapping provides the wrong combination of `source`
/// and `target` for the signature of its dispatch method.
class InvalidSubclassMappingSideError extends InvalidGenerationSourceError {
  InvalidSubclassMappingSideError._(super.message, {required Element element})
      : super(element: element);

  /// `source` given while the source of the method is a `Map`.
  InvalidSubclassMappingSideError.sourceOnMapSource({
    required MethodElement method,
  }) : this._(
          "Method '${method.name}' takes a Map: @SubclassMapping must not "
          "declare 'source'.\n"
          "Fix: Declare only 'target' (and discriminatorValue).",
          element: method,
        );

  /// `target` given while the target of the method is a `Map`.
  InvalidSubclassMappingSideError.targetOnMapTarget({
    required MethodElement method,
  }) : this._(
          "Method '${method.name}' returns a Map: @SubclassMapping must not "
          "declare 'target'.\n"
          "Fix: Declare only 'source' (and discriminatorValue).",
          element: method,
        );

  /// `target` missing on a Map -> class hierarchy method.
  InvalidSubclassMappingSideError.missingTarget({
    required MethodElement method,
  }) : this._(
          "Method '${method.name}' takes a Map: every @SubclassMapping must "
          "declare 'target'.\n"
          "Fix: Use @SubclassMapping(target: Subclass, "
          "discriminatorValue: ...).",
          element: method,
        );

  /// `source` missing on a class hierarchy -> Map method.
  InvalidSubclassMappingSideError.missingSource({
    required MethodElement method,
  }) : this._(
          "Method '${method.name}' returns a Map: every @SubclassMapping must "
          "declare 'source'.\n"
          "Fix: Use @SubclassMapping(source: Subclass, "
          "discriminatorValue: ...).",
          element: method,
        );

  /// `source` or `target` missing on a class -> class method.
  InvalidSubclassMappingSideError.missingTypes({
    required MethodElement method,
  }) : this._(
          "Method '${method.name}' dispatches between classes: every "
          "@SubclassMapping must declare both 'source' and 'target'.\n"
          "Fix: Use @SubclassMapping(source: SourceSubclass, "
          "target: TargetSubclass).",
          element: method,
        );
}
