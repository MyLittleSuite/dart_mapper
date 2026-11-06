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

/// Thrown when a field of a typed `Map<String, V>` source is not compatible
/// with the map value type `V`.
///
/// [converter] holds the types a converter method would have to convert
/// between to fix the mapping, `null` when no converter can (a map read as
/// an iterable, or the other way around).
class IncompatibleMapValueTypeError extends InvalidGenerationSourceError {
  IncompatibleMapValueTypeError({
    required String field,
    required String fieldType,
    required String valueType,
    required Element element,
    ({String from, String to})? converter,
  }) : super(
          "Field '$field' of type '$fieldType' is not compatible with the "
          "map value type '$valueType'.\n"
          "Fix: Declare the source map as Map<String, dynamic> (or "
          "Map<String, Object?>)"
          "${converter == null ? ' or' : ', declare a converter method from '
              "'${converter.from}' to '${converter.to}', or"} use callable.",
          element: element,
        );
}
