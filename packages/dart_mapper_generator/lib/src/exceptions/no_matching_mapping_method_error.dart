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

/// Thrown when no mapper method accepts the sources of a comma-separated
/// `source` (or the single source of a `qualifiedBy` mapping).
class NoMatchingMappingMethodError extends InvalidGenerationSourceError {
  /// [arguments] are the source types as written (`String? field`),
  /// [rejected] the candidates with the reason each one was discarded.
  NoMatchingMappingMethodError({
    required String target,
    required List<String> arguments,
    required String? targetType,
    required Map<String, String> rejected,
    required Element element,
  }) : super(
          "No mapper method found for @Mapping(target: '$target') with "
          "source (${arguments.join(', ')})"
          "${targetType == null ? '' : ' returning $targetType'}.\n"
          "${rejected.isEmpty ? 'No other mapper method is available.' : 'Rejected candidates:\n${rejected.entries.map((e) => '  - ${e.key}: ${e.value}').join('\n')}'}\n"
          "Fix: Add a mapper method (in the mapper or in a mapper listed in "
          "uses) taking these parameters in this order and returning a "
          "value assignable to the target, or use callable.",
          element: element,
        );
}
