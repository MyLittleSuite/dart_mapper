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

import 'package:analyzer/dart/element/type.dart';
import 'package:dart_mapper_generator/src/extensions/element.dart';

extension DartTypeExtension on DartType {
  bool get isList =>
      isDartCoreList ||
      {
        'BuiltList',
      }.contains(className);

  bool get isSet =>
      isDartCoreSet ||
      {
        'BuiltSet',
      }.contains(className);

  bool get isIterable => isList || isSet || isDartCoreIterable;

  bool get isMap => isDartCoreMap;

  bool get isEnum => element?.enumElementOrNull != null;

  bool get isPrimitive =>
      isDartCoreBool ||
      isDartCoreDouble ||
      isDartCoreInt ||
      isDartCoreNum ||
      isDartCoreString ||
      isDartCoreSymbol ||
      {
        'DateTime',
        'Duration',
      }.contains(className);

  List<DartType>? get asGenerics {
    if (this is ParameterizedType) {
      return (this as ParameterizedType).typeArguments;
    }

    return null;
  }

  String get humanReadable => getDisplayString(withNullability: false)
      .replaceAll('<', 'Of')
      .replaceAll('>', '')
      .replaceAll(', ', 'And');

  String get className => getDisplayString(withNullability: false)
      .replaceAll(RegExp(r'<[^]*>?'), '');

  String get displayString => getDisplayString(withNullability: false);

  String get builtBuilderClass =>
      [displayString, 'Builder', if (isNullable) '?'].join();

  bool get isNullable => getDisplayString(withNullability: true).endsWith('?');
}
