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

import 'package:dart_mapper_generator/src/models/field/field.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/bases/mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/callable_mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/generated_private_mapping_method.dart';

class Binding {
  final Field source;
  final Field target;
  final bool ignored;
  final bool forceNonNull;
  final CallableMappingMethod? callableMappingMethod;
  final MappingMethod? extraMappingMethod;

  Binding({
    required this.source,
    required this.target,
    this.ignored = false,
    this.forceNonNull = false,
    this.callableMappingMethod,
    this.extraMappingMethod,
  }) /* : assert(target.required && ignored,
            'Target field \'${target.name}\' must be required') TODO:*/
  ;

  Iterable<MappingMethod> get mappingMethods sync* {
    if (extraMappingMethod != null &&
        extraMappingMethod is GeneratedPrivateMappingMethod) {
      yield extraMappingMethod!;

      yield* (extraMappingMethod! as GeneratedPrivateMappingMethod)
          .bindings
          .expand((binding) => binding.mappingMethods);
    }
  }

  @override
  String toString() => 'Binding{'
      'source: $source, '
      'target: $target, '
      'ignored: $ignored, '
      'forceNonNull: $forceNonNull, '
      'callableMappingMethod: $callableMappingMethod, '
      'extraMappingMethod: $extraMappingMethod'
      '}';
}
