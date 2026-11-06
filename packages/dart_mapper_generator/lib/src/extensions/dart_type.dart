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
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dart_mapper_generator/src/extensions/element.dart';
import 'package:strings/strings.dart';

extension DartTypeExtension on DartType {
  bool get isList => isDartCoreList || isBuiltList;

  bool get isSet => isDartCoreSet || isBuiltSet;

  bool get isIterable => isList || isSet || isDartCoreIterable;

  bool get isMap => isDartCoreMap || isBuiltMap;

  /// Whether this is a `dart:core` [Map] whose key type is `String`, such as
  /// `Map<String, dynamic>` or `Map<String, Object?>`.
  bool get isStringKeyedMap {
    final type = this;
    return type is InterfaceType &&
        type.isDartCoreMap &&
        type.typeArguments.firstOrNull?.isDartCoreString == true &&
        !type.typeArguments.first.isNullable;
  }

  bool get isEnum => element is EnumElement || isBuiltEnum;

  /// Whether this type is a `dart:core` [Map] accepted as the source of a
  /// Map -> class mapping: a raw/`dynamic`-keyed map, an `Object?`/`Object`
  /// keyed map or a `String`-keyed map.
  bool get isMapLikeSource {
    if (!isDartCoreMap) {
      return false;
    }

    final key = asGenerics?.firstOrNull;

    return key == null ||
        key is DynamicType ||
        key.isDartCoreObject ||
        key.isDartCoreString;
  }

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

  String get humanReadable => displayString
      .replaceAll('<', 'Of')
      .replaceAll('>', '')
      .replaceAll(', ', 'And');

  String get className => displayString.replaceAll(RegExp(r'<[^]*>?'), '');

  String get displayString => getDisplayString().replaceAll('?', '');

  bool get isNullable => nullabilitySuffix == NullabilitySuffix.question;

  String get parameterName => displayString
      .replaceAll(RegExp(r'[^A-Za-z0-9_$]+'), '_')
      .toSnakeCase()
      .toCamelCase(lower: true);

  /// A readable identifier fragment unique per type, nullability of the
  /// generic arguments included: `Box<String?>` is `BoxOfNullableString`
  /// whereas `Box<String>` is `BoxOfString`. The nullability of the type
  /// itself is left to the caller.
  String get uniqueName => uniqueNameWith((_) => null);

  /// Like [uniqueName], with the import prefix given by [prefixOf] prepended
  /// to every generic argument: `Box<models.Foo>` is `BoxOfModelsFoo`, so it
  /// stays apart from `Box<Foo>`. The prefix of the type itself is left to the
  /// caller.
  String uniqueNameWith(String? Function(DartType type) prefixOf) {
    final type = this;
    if (type is! InterfaceType || type.typeArguments.isEmpty) {
      return humanReadable;
    }

    final arguments = type.typeArguments
        .map((argument) => [
              if (argument.isNullable) 'Nullable',
              prefixOf(argument)?.toCapitalised() ?? '',
              argument.uniqueNameWith(prefixOf),
            ].join())
        .join('And');

    return '${type.className}Of$arguments';
  }

  /// Returns a map of getter name to substituted [DartType] for this type,
  /// using [InterfaceType.getters] which performs type-parameter substitution
  /// (e.g. T to Todo when the instantiated type is Pagination of Todo).
  ///
  /// Returns null for non-[InterfaceType] values so all existing call-sites
  /// that use [ClassElement.getterElements] fall back to unsubstituted types
  /// unchanged.
  Map<String, DartType>? get substitutedGetterTypes {
    if (this is! InterfaceType) return null;
    final iface = this as InterfaceType;
    final result = <String, DartType>{};
    final allTypes = [iface, ...iface.allSupertypes.where((t) => !t.isDartCoreObject)];
    for (final t in allTypes) {
      for (final getter in t.getters) {
        if (getter.isStatic) continue;
        final rawName = getter.name;
        if (rawName == null || rawName.isEmpty) continue;
        result.putIfAbsent(rawName, () => getter.returnType);
      }
    }
    return result.isEmpty ? null : result;
  }

  bool same(
    DartType other, {
    Map<Uri, String>? aliases,
    bool useNullability = true,
  }) {
    final thisUri = element?.library?.uri;
    final otherUri = other.element?.library?.uri;

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
        (acc, uri) {
          final libraryUri = element?.library?.firstFragment.source.uri;
          return acc || libraryUri?.toString().contains(uri) == true;
        },
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

  bool get isBuiltMap =>
      isLibraryBuilt &&
      {
        'BuiltMap',
      }.contains(className);

  /// Whether this type is a class implementing `Built<V, B>`.
  bool get isBuiltValue =>
      (element?.interfaceElementOrNull?.allSupertypes ?? const []).any(
        (type) => type.isLibraryBuilt && type.element.name == 'Built',
      );

  bool get isBuiltEnum {
    final superType = element?.classElementOrNull?.supertype;

    return superType?.isLibraryBuilt == true &&
        superType?.className == 'EnumClass';
  }

  String get builtBuilderClass =>
      [displayString, 'Builder', if (isNullable) '?'].join();
}
