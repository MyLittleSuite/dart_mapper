/*
 *
 *  * Copyright (c) 2024 MyLittleSuite
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
import 'package:dart_mapper_generator/src/models/mapper/mapper_class.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/bases/mapping_method.dart';
import 'package:source_gen/source_gen.dart';

class TargetFieldRequiresNonOptionalSourceFieldError
    extends InvalidGenerationSourceError {
  TargetFieldRequiresNonOptionalSourceFieldError({
    required ParameterElement parameter,
    required ClassElement targetClass,
    required MapperClass mapperClass,
    required MappingMethod method,
  }) : super(
          'Target field \'${parameter.name}\' '
          'in class \'${targetClass.name}\', '
          'method \'${method.name}\' in class \'${mapperClass.name}\', '
          'requires a non-optional source field.',
          element: targetClass,
        );
}
