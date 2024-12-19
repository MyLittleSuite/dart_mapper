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

import 'package:code_builder/code_builder.dart' hide Field;
import 'package:dart_mapper/dart_mapper.dart';
import 'package:dart_mapper_generator/src/mixins/aliases_mixin.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapper_class.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/intenal_mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/mapping_method.dart';

class ProcessorContext with AliasesMixin {
  final Mapper mapperAnnotation;
  final MapperClass mapperClass;
  @override
  final Map<Uri, String> importAliases;

  const ProcessorContext({
    required this.mapperAnnotation,
    required this.mapperClass,
    required this.importAliases,
  });

  Iterable<MappingMethod> get mappingMethods => mapperClass.mappingMethods;

  Iterable<InternalMappingMethod> get internalMappingMethods =>
      mappingMethods.whereType<InternalMappingMethod>();
}

class ProcessorMethodContext extends ProcessorContext {
  final InternalMappingMethod currentMethod;

  const ProcessorMethodContext({
    required super.mapperAnnotation,
    required super.mapperClass,
    required super.importAliases,
    required this.currentMethod,
  });
}

abstract class ComponentProcessor<R extends Spec> {
  const ComponentProcessor();

  R process(ProcessorContext context);
}
