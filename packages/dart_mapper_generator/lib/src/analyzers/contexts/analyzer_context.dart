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

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dart_mapper/dart_mapper.dart';
import 'package:dart_mapper_generator/src/extensions/dart_type.dart';
import 'package:dart_mapper_generator/src/mixins/aliases_mixin.dart';
import 'package:dart_mapper_generator/src/models/mapper_usage.dart';

class AnalyzerContext with AliasesMixin {
  final Mapper mapperAnnotation;
  final ClassElement mapperClass;
  final Set<MapperUsage> mapperUsages;
  final Set<MapperUsage> internalMapperUsages;
  @override
  final Map<Uri, String> importAliases;

  const AnalyzerContext({
    required this.mapperAnnotation,
    required this.mapperClass,
    this.mapperUsages = const {},
    this.internalMapperUsages = const {},
    this.importAliases = const {},
  });

  MapperUsage? findUsage(
    DartType returnType,
    List<DartType> parameters, {
    required bool internally,
    bool useNullabilityForReturn = true,
    bool useNullabilityForParams = true,
  }) =>
      (internally ? internalMapperUsages : mapperUsages)
          .where(
            (usage) =>
                usage.returnType.same(
                  returnType,
                  aliases: importAliases,
                  useNullability: useNullabilityForReturn,
                ) &&
                usage.parameters.length == parameters.length &&
                usage.parameters.every(
                  (parameter) => parameters.any(
                    (param) => param.same(
                      parameter.field.type,
                      aliases: importAliases,
                      useNullability: useNullabilityForParams,
                    ),
                  ),
                ),
          )
          .firstOrNull;

  Iterable<MethodElement> get mappingMethods =>
      mapperClass.methods.where((method) => method.isAbstract);
}
