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

/// Thrown when an inheriting method matches more than one method only through
/// the class <-> Map type relaxation (`Map<String, dynamic>`, `Map<String,
/// Object?>`, raw `Map`, ...), so that it is unclear which configuration to
/// inherit.
class AmbiguousInheritConfigurationError extends InvalidGenerationSourceError {
  AmbiguousInheritConfigurationError({
    required String method,
    required List<String> candidates,
    required Element element,
  }) : super(
          "Ambiguous inherited configuration for method '$method': multiple "
          "methods are candidates (${candidates.join(', ')}).\n"
          "Fix: Declare the parameter and return types of '$method' exactly "
          "like the ones of the method to inherit from, or keep a single "
          "candidate.",
          element: element,
        );
}
