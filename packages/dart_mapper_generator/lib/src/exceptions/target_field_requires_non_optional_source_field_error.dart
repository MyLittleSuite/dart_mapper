/*
 *
 *  * Copyright (c) 2026 MyLittleSuite
 *  *
 *  * Permission is hereby granted, free of charge, to any person
 *  * obtaining a copy of this software and associated documentation
 *  * files (the "Software"), to deal in the Software without
 *  * restriction, including without limitation the rights to use,
 *  * copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  * copies of the Software, and to permit persons to whom the
 *  * Software is furnished to do so, subject to the following
 *  * conditions:
 *  *
 *  * The above copyright notice and this permission notice shall be
 *  * included in all copies or substantial portions of the Software.
 *  *
 *  * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 *  * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 *  * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 *  * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 *  * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 *  * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *  * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 *  * OTHER DEALINGS IN THE SOFTWARE.
 *
 */

import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

/// Thrown when a non-nullable target field (constructor parameter or built
/// value getter) is bound to a nullable source.
class TargetFieldRequiresNonOptionalSourceFieldError
    extends InvalidGenerationSourceError {
  TargetFieldRequiresNonOptionalSourceFieldError({
    required String fieldName,
    required ClassElement targetClass,
    required String mapperName,
    required String methodName,
  }) : super(
          'Target field \'$fieldName\' of \'${targetClass.name}\' '
          'in \'$mapperName.$methodName\' requires a non-nullable source, '
          'but the source field is nullable.\n'
          'Fix: Add @Mapping(target: \'$fieldName\', forceNonNull: true) '
          'to force-unwrap the nullable source field, or make the source field non-nullable.',
          element: targetClass,
        );
}
