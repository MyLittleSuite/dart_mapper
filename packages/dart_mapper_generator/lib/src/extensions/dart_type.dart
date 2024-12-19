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
import 'package:dart_mapper_generator/src/extensions/element.dart';
import 'package:strings/strings.dart';

extension DartTypeExtension on DartType {
  bool get isList => isDartCoreList || isBuiltList;

  bool get isSet => isDartCoreSet || isBuiltSet;

  bool get isIterable => isList || isSet || isDartCoreIterable;

  bool get isMap => isDartCoreMap;

  bool get isEnum => element is EnumElement || isBuiltEnum;

  bool get isDateTime => className == 'DateTime';

  bool get isDuration => className == 'Duration';

  bool get isPrimitive =>
      isDartCoreBool ||
      isDartCoreDouble ||
      isDartCoreInt ||
      isDartCoreNum ||
      isDartCoreString ||
      isDartCoreSymbol ||
      isDateTime ||
      isDuration;

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

  bool get isNullable => getDisplayString(withNullability: true).endsWith('?');

  String get parameterName =>
      displayString.toSnakeCase().toCamelCase(lower: true);

  bool same(
    DartType other, {
    Map<Uri, String>? aliases,
    bool useNullability = true,
  }) {
    final thisUri = element?.librarySource?.uri;
    final otherUri = other.element?.librarySource?.uri;

    if (useNullability) {
      return aliases?[thisUri] == aliases?[otherUri] && this == other;
    }

    return (thisUri == otherUri) &&
        aliases?[thisUri] == aliases?[otherUri] &&
        (displayString == other.displayString);
  }
}

extension DartTypeBuilt on DartType {
  bool get isLibraryBuilt => {
        'package:built_value/',
        'package:built_collection/',
      }.fold(
        false,
        (acc, uri) =>
            acc || element?.librarySource?.uri.toString().contains(uri) == true,
      );

  bool get isBuiltSet =>
      isLibraryBuilt &&
      {
        'BuiltSet',
      }.contains(className);

  bool get isBuiltList =>
      isLibraryBuilt &&
      {
        'BuiltList',
      }.contains(className);

  bool get isBuiltEnum {
    final superType = element?.classElementOrNull?.supertype;

    return superType?.isLibraryBuilt == true &&
        superType?.className == 'EnumClass';
  }

  String get builtBuilderClass =>
      [displayString, 'Builder', if (isNullable) '?'].join();
}
