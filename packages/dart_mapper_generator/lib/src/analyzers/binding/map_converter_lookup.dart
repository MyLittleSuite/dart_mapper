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
import 'package:analyzer/dart/element/type.dart';
import 'package:dart_mapper_generator/src/analyzers/contexts/analyzer_context.dart';
import 'package:dart_mapper_generator/src/exceptions/ambiguous_map_converter_error.dart';
import 'package:dart_mapper_generator/src/extensions/dart_type.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/bases/mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/external_mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/internal_mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper_usage.dart';

/// The direction of a class <-> Map conversion.
enum MapConverterDirection {
  /// class -> Map: the class-side type is the parameter of the method.
  toMap,

  /// Map -> class: the class-side type is the return type of the method.
  fromMap,
}

/// Whether [type] is a plain value that is stored in a map as it is.
bool isPlainMapPrimitive(DartType type) =>
    type.isDartCoreBool ||
    type.isDartCoreInt ||
    type.isDartCoreDouble ||
    type.isDartCoreNum ||
    type.isDartCoreString;

/// The key identifying [type] in the per-run caches of generated nested
/// methods. It is qualified with the library, so that same-named classes of
/// different libraries (prefixed imports) are told apart, type arguments
/// included: `Box<a.Foo>` and `Box<b.Foo>` get different keys.
String mapTypeKey(DartType type) {
  final base = '${type.element?.library?.uri}#';
  if (type is! InterfaceType || type.typeArguments.isEmpty) {
    return '$base${type.getDisplayString()}';
  }

  final arguments = type.typeArguments.map(mapTypeKey).join(', ');

  return '$base${type.element.name}<$arguments>${type.isNullable ? '?' : ''}';
}

/// Whether [type] is a user class that has to be converted to a nested map.
bool isMapCustomClass(DartType type) {
  final element = type.element;

  return type is InterfaceType &&
      element is ClassElement &&
      element.library.isInSdk == false &&
      !type.isEnum &&
      !type.isIterable &&
      !type.isMap &&
      !type.isPrimitive &&
      !type.isLibraryBuilt &&
      !type.isLibraryFic;
}

/// The single converter lookup of class <-> Map mappings.
///
/// Both directions share one rule set. For a class-side type `T`:
///
/// * plain primitives (`bool`, `int`, `double`, `num`, `String`) and whole
///   `Map` / `Iterable` types are never converted, callers look at the
///   element / value type instead;
/// * a converter is a hand-written (non-abstract) one-parameter method:
///   `toMap` takes `T` and returns a wire type assignable to the map value
///   type, other than `T`; `fromMap` returns `T` out of a non-map parameter
///   whose type differs from `T`;
/// * a nested mapper converts `T` to / from a whole map. It may be abstract
///   (generated): `Map<String, ...> m(T)` or `T m(Map<String, ...>)`;
/// * methods declared in the mapper win over the ones of the `uses` mappers,
///   converters win over nested mappers;
/// * more than one candidate is an [AmbiguousMapConverterError].
class MapConverterLookup {
  final AnalyzerContext context;
  final Element element;
  final MapConverterDirection direction;

  /// The value type of the map written by a `toMap` method, `null` when
  /// untyped (`dynamic` / `Object`).
  final DartType? valueType;

  const MapConverterLookup({
    required this.context,
    required this.element,
    required this.direction,
    this.valueType,
  });

  bool get _isToMap => direction == MapConverterDirection.toMap;

  /// The method converting [type], if any.
  MappingMethod? find(DartType type) {
    final plain = context.mapperClass.library.typeSystem.promoteToNonNull(type);
    if (plain is DynamicType ||
        plain.isDartCoreObject ||
        isPlainMapPrimitive(plain) ||
        plain.isMap ||
        plain.isIterable) {
      return null;
    }

    for (final internally in const [true, false]) {
      final usages =
          (internally ? context.internalMapperUsages : context.mapperUsages)
              .where((usage) => usage.parameters.length == 1)
              .toList(growable: false);

      final chosen = _single(
            plain,
            usages.where((u) => _isConverter(u, plain)).toList(),
          ) ??
          _single(
            plain,
            usages.where((u) => _isNested(u, plain)).toList(),
          );

      if (chosen != null) {
        return internally
            ? InternalMappingMethod(mapperUsage: chosen)
            : ExternalMappingMethod(mapperUsage: chosen);
      }
    }

    return null;
  }

  bool _same(DartType a, DartType b) => a.same(
        b,
        aliases: context.importAliases,
        useNullability: false,
      );

  bool _isConverter(MapperUsage usage, DartType plain) {
    if (usage.isAbstract) return false;

    final parameter = usage.parameters.single.field.type;

    return _isToMap
        ? _same(parameter, plain) &&
            !usage.returnType.isDartCoreMap &&
            !_same(usage.returnType, plain) &&
            _isWire(usage.returnType, plain)
        : _same(usage.returnType, plain) &&
            !parameter.isMapLikeSource &&
            !_same(parameter, plain);
  }

  bool _isNested(MapperUsage usage, DartType plain) {
    final parameter = usage.parameters.single.field.type;

    return _isToMap
        ? _same(parameter, plain) &&
            usage.returnType.isDartCoreMap &&
            _isWire(usage.returnType, plain)
        : _same(usage.returnType, plain) && parameter.isMapLikeSource;
  }

  /// Whether [returnType] can be stored in the written map.
  bool _isWire(DartType returnType, DartType plain) {
    final value = valueType;
    if (value != null && !(value is DynamicType || value.isDartCoreObject)) {
      return context.mapperClass.library.typeSystem
          .isAssignableTo(returnType, value);
    }

    // Untyped maps accept anything for plain values, but classes and enums
    // are only replaced by values that make sense in a map.
    final semantic = isMapCustomClass(plain) || plain.isEnum;

    return !semantic || _isWireType(returnType);
  }

  static bool _isWireType(DartType type) {
    if (type is DynamicType || type.isDartCoreObject) return true;
    if (isPlainMapPrimitive(type)) return true;
    if (type.isDartCoreMap) return true;
    if (type.isDartCoreList || type.isDartCoreSet || type.isDartCoreIterable) {
      final item = (type as InterfaceType).typeArguments.firstOrNull;

      return item == null || _isWireType(item);
    }

    return false;
  }

  MapperUsage? _single(DartType type, List<MapperUsage> usages) {
    if (usages.length > 1) {
      throw AmbiguousMapConverterError(
        type: type.displayString,
        candidates: usages
            .map((usage) => '${usage.mapperName}.${usage.functionName}')
            .toList(growable: false),
        element: element,
      );
    }

    return usages.firstOrNull;
  }
}
