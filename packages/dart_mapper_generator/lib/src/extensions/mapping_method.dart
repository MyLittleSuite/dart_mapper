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

import 'package:analyzer/dart/element/type.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/bases/bindable_mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/bases/mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/external_mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/internal_mapping_method.dart';

extension MappingMethodExtension on MappingMethod {
  /// The type of the first parameter of this method, when it is known.
  DartType? get firstParameterType => switch (this) {
        InternalMappingMethod(:final mapperUsage) =>
          mapperUsage.parameters.firstOrNull?.field.type,
        ExternalMappingMethod(:final mapperUsage) =>
          mapperUsage.parameters.firstOrNull?.field.type,
        BindableMappingMethod(:final parameters) =>
          parameters.firstOrNull?.field.type,
        _ => null,
      };
}
