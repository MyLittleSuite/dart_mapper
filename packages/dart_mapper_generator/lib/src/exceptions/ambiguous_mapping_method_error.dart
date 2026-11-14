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

/// Thrown when more than one mapper method accepts the sources of a
/// comma-separated `source` (or the single source of a mapping).
class AmbiguousMappingMethodError extends InvalidGenerationSourceError {
  AmbiguousMappingMethodError({
    required String target,
    required List<String> candidates,
    required Element element,
  }) : super(
          "Ambiguous mapper method for @Mapping(target: '$target'): multiple "
          "methods match (${candidates.join(', ')}).\n"
          "Fix: Select the one to use with @Mapping(target: '$target', "
          "qualifiedBy: 'methodName') or qualifiedBy: 'MapperClass.methodName'.",
          element: element,
        );
}
