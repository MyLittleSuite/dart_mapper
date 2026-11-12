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
import 'package:code_builder/code_builder.dart' hide Field;
import 'package:dart_mapper_generator/src/extensions/class_element.dart';
import 'package:dart_mapper_generator/src/extensions/dart_type.dart';
import 'package:dart_mapper_generator/src/extensions/element.dart';
import 'package:dart_mapper_generator/src/extensions/expression.dart';
import 'package:dart_mapper_generator/src/extensions/mapping_method.dart';
import 'package:dart_mapper_generator/src/factories/expression_factory.dart';
import 'package:dart_mapper_generator/src/misc/map_expressions.dart';
import 'package:dart_mapper_generator/src/misc/strings.dart';
import 'package:dart_mapper_generator/src/models/field/field.dart';
import 'package:dart_mapper_generator/src/models/field/map_entry_field.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/bases/bindable_mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/bases/mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/callable_mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/generated_private_mapping_method.dart';

/// Builds the expressions reading a value out of a map (Map -> class).
///
/// Bindings whose source is not a map key (a plain method parameter or a field
/// of a non-map parameter, in multi-source methods) are delegated to
/// [defaultFactory].
class FromMapExpressionFactory extends ExpressionFactory {
  final ExpressionFactory defaultFactory;

  const FromMapExpressionFactory({
    required this.defaultFactory,
  });

  @override
  Expression create(ExpressionContext context) {
    // Expression / constant bindings never read the map.
    if (context.expression != null || context.constant != null) {
      return super.basic(context);
    }

    if (context.ignored) {
      return literalNull;
    }

    if (context.expressionMappingMethod != null) {
      return _callable(context);
    }

    final field = context.field;
    if (field is! MapEntryField) {
      return defaultFactory.create(context);
    }

    final result = _entry(context, field);

    // `b..field = value as String?..other = ...` does not lex: the `?..` is
    // taken as a null-aware cascade. Built value setters are cascades.
    return _isBuiltTarget(context) &&
            result.accept(DartEmitter()).toString().endsWith('?')
        ? result.parenthesized
        : result;
  }

  Expression _callable(ExpressionContext context) {
    final sources = context.sources;
    final fields =
        sources != null && sources.isNotEmpty ? sources : [context.field];
    final chains = sources != null && sources.isNotEmpty
        ? context.sourceAccessChains
        : [context.accessChain];

    final arguments = [
      for (var i = 0; i < fields.length; i++)
        _castArgument(
          context,
          fields[i],
          _forceNonNull(
            context,
            fields.length == 1,
            fields[i],
            _sourceRead(fields[i], chains?[i]),
          ),
          _parameterType(context.expressionMappingMethod!, i),
        ),
    ];

    return refer(context.expressionMappingMethod!.name).call(arguments);
  }

  /// `forceNonNull` unwraps a nullable typed map value before it is used.
  Expression _forceNonNull(
    ExpressionContext context,
    bool single,
    Field source,
    Expression read,
  ) =>
      single &&
              context.forceNonNull &&
              source is MapEntryField &&
              source.nullable
          ? read.nullChecked
          : read;

  DartType? _parameterType(MappingMethod method, int index) =>
      method is CallableMappingMethod
          ? method.parameters.elementAtOrNull(index)?.field.type
          : null;

  /// Typed map values (`Map<String, Object?>`) do not flow into the typed
  /// parameter of a callable: they are cast to it. `dynamic` values do.
  Expression _castArgument(
    ExpressionContext context,
    Field source,
    Expression read,
    DartType? parameterType,
  ) {
    if (source is! MapEntryField ||
        parameterType == null ||
        parameterType is DynamicType ||
        (parameterType.isDartCoreObject && parameterType.isNullable)) {
      return read;
    }

    final valueType = _mapValueType(context, source);
    if (valueType == null || valueType is DynamicType) {
      return read;
    }

    // A map read is always nullable (`map['key']` is `T?`), so it flows as it
    // is only into a parameter accepting null.
    if (_sameBase(valueType, parameterType) && parameterType.isNullable) {
      return read;
    }

    return read.castTo(context.resolveTypeDeep(parameterType));
  }

  /// The value type of the map [source] is read from, `null` for the nested
  /// paths of dot notation (always `dynamic`).
  DartType? _mapValueType(ExpressionContext context, MapEntryField source) {
    if (source.keys.length != 1) {
      return null;
    }

    final method = context.currentMethod;
    final parameter = method is BindableMappingMethod
        ? method.parameters
            .where((p) => p.field.name == source.instance!.name)
            .firstOrNull
        : null;
    final generics = parameter?.field.type.asGenerics;

    return generics != null && generics.length > 1 ? generics[1] : null;
  }

  Expression _sourceRead(Field source, List<(String, bool)>? chain) {
    if (source is MapEntryField) {
      return mapRead(source.instance!.name, source.keys);
    }

    if (chain != null && chain.isNotEmpty) {
      Expression result = refer(source.instance!.name);
      for (final (segment, parentIsNullable) in chain) {
        result = parentIsNullable
            ? result.nullSafeProperty(segment)
            : result.property(segment);
      }
      return result;
    }

    return source.instance != null
        ? refer(source.instance!.name).property(source.name)
        : refer(source.name);
  }

  Expression _entry(ExpressionContext context, MapEntryField source) {
    final target = context.counterpartField;
    var raw = mapRead(source.instance!.name, source.keys);

    // A typed `Map<String, T?>` value with forceNonNull is unwrapped, whether
    // or not the target is nullable (as the class -> class mapping does). A
    // defaultValue takes precedence: the null entry falls back to it instead.
    var bang = false;
    if (context.forceNonNull &&
        source.nullable &&
        context.defaultValue == null) {
      raw = raw.nullChecked;
      bang = true;
    }

    final defaultValue = context.defaultValue;
    final defaultExpression = defaultValue == null
        ? null
        : target.type.isDartCoreString
            ? literalString(defaultValue)
            : CodeExpression(Code(defaultValue));

    return _read(
      context,
      raw,
      target.type,
      nullable: target.nullable && !bang,
      defaultExpression: defaultExpression,
      extra: context.extraMappingMethod,
      direct: true,
      staticType: source.keys.length == 1 ? source.valueType : null,
      bang: bang,
    );
  }

  Expression _read(
    ExpressionContext context,
    Expression raw,
    DartType type, {
    required bool nullable,
    Expression? defaultExpression,
    MappingMethod? extra,
    bool direct = false,
    DartType? staticType,
    bool bang = false,
  }) {
    if (type.isIterable) {
      return _readIterable(
        context,
        raw,
        type,
        nullable: nullable,
        defaultExpression: defaultExpression,
        extra: extra,
      );
    }

    if (type.isMap) {
      return _readMap(
        context,
        raw,
        type,
        nullable: nullable,
        defaultExpression: defaultExpression,
        extra: extra,
      );
    }

    return _readLeaf(
      context,
      raw,
      type,
      nullable: nullable,
      defaultExpression: defaultExpression,
      extra: extra,
      direct: direct,
      staticType: staticType,
      bang: bang,
    );
  }

  Expression _readLeaf(
    ExpressionContext context,
    Expression raw,
    DartType type, {
    required bool nullable,
    Expression? defaultExpression,
    MappingMethod? extra,
    required bool direct,
    DartType? staticType,
    required bool bang,
  }) {
    if (extra != null) {
      return _readWithMethod(
        context,
        raw,
        type,
        extra,
        nullable: nullable,
        defaultExpression: defaultExpression,
        direct: direct,
      );
    }

    // Dynamic values are taken as they are.
    if (type is DynamicType || (type.isDartCoreObject && nullable)) {
      return defaultExpression != null ? raw.orElse(defaultExpression) : raw;
    }

    if (type.isEnum) {
      final enumReference = refer(context.resolveType(type));
      final name = raw.castTo('String');
      final value = type.isBuiltEnum
          ? enumReference.property('valueOf').call([name])
          : enumReference.property('values').property('byName').call([name]);

      return _guard(raw, nullable, defaultExpression, value);
    }

    final canSkipCast = staticType != null &&
        _sameBase(staticType, type) &&
        (nullable || bang || defaultExpression != null);
    final castNullable = nullable || defaultExpression != null;

    Expression value;
    if (type.isDartCoreDouble) {
      if (canSkipCast) {
        value = raw;
      } else {
        final number = raw.castTo(castNullable ? 'num?' : 'num').parenthesized;
        value = (castNullable
                ? number.nullSafeProperty('toDouble')
                : number.property('toDouble'))
            .call([]);
      }
    } else {
      value = canSkipCast
          ? raw
          : raw.castTo(
              context.resolveType(type, withNullability: castNullable),
            );
    }

    return defaultExpression != null ? value.orElse(defaultExpression) : value;
  }

  Expression _readWithMethod(
    ExpressionContext context,
    Expression raw,
    DartType type,
    MappingMethod method, {
    required bool nullable,
    Expression? defaultExpression,
    required bool direct,
  }) {
    final parameterType = method.firstParameterType;
    final isNested = parameterType == null || parameterType.isMapLikeSource;

    Expression argument;
    if (parameterType == null) {
      argument = raw;
    } else if (isNested) {
      argument = _mapArgument(context, raw, parameterType);
    } else {
      argument = raw.castTo(context.resolveTypeDeep(parameterType));
    }

    final call = _wrapBuilt(
      context,
      refer(method.name).call([argument]),
      method,
      type,
      direct: direct,
    );

    // A converter accepting null deals with null values on its own.
    if (!isNested && parameterType.isNullable) {
      return defaultExpression != null ? call.orElse(defaultExpression) : call;
    }

    return _guard(raw, nullable, defaultExpression, call);
  }

  /// Typed `Map<String, ...>` parameters get a normalized copy; raw and
  /// `Object?`-keyed maps are only cast.
  Expression _mapArgument(
    ExpressionContext context,
    Expression raw,
    DartType parameterType,
  ) {
    final generics = parameterType.asGenerics;
    final cast = raw.castTo('Map');
    if (generics == null ||
        generics.length < 2 ||
        !generics.first.isDartCoreString) {
      return cast;
    }

    return TypeReference(
      (b) => b
        ..symbol = 'Map'
        ..types.addAll([
          refer('String'),
          refer(context.resolveTypeDeep(generics[1])),
        ]),
    ).newInstanceNamed('from', [cast]);
  }

  /// Built values are assigned to builder setters as builders.
  Expression _wrapBuilt(
    ExpressionContext context,
    Expression call,
    MappingMethod method,
    DartType type, {
    required bool direct,
  }) {
    if (!type.isBuiltValue) {
      return call;
    }

    final inBuilder = direct && _isBuiltTarget(context);
    if (method is GeneratedPrivateMappingMethod) {
      // Generated methods return the builder.
      return inBuilder ? call : call.property('build').call([]);
    }

    if (!inBuilder) {
      return call;
    }

    final constructor = type.element!.classElement.mainConstructor;

    return refer([context.resolveConstructor(constructor), 'Builder'].join())
        .newInstance([])
        .cascade('replace')
        .call([call])
        .parenthesized;
  }

  bool _isBuiltTarget(ExpressionContext context) =>
      context.currentMethod.returnType?.isBuiltValue == true;

  Expression _readIterable(
    ExpressionContext context,
    Expression raw,
    DartType type, {
    required bool nullable,
    Expression? defaultExpression,
    MappingMethod? extra,
  }) {
    final element = type.asGenerics?.firstOrNull;
    final elementName = element == null
        ? 'dynamic'
        : context.resolveType(element, withNullability: element.isNullable);
    final isSet = type.isSet;
    final identity = extra == null && !_needsConversion(element);

    Expression result;
    if (identity) {
      result = TypeReference(
        (b) => b
          ..symbol = isSet ? 'Set' : 'List'
          ..types.add(refer(elementName)),
      ).newInstanceNamed(
        'from',
        [_container(raw, 'Iterable', defaultExpression, parenthesized: false)],
      );
    } else {
      final converted = _read(
        context,
        refer('e'),
        element!,
        nullable: element.isNullable,
        extra: extra,
      );
      final mapped =
          _container(raw, 'Iterable', defaultExpression).property('map').call(
        [
          Method(
            (b) => b
              ..requiredParameters.add(Parameter((p) => p.name = 'e'))
              ..body = converted.code,
          ).closure,
        ],
        {},
        [refer(elementName)],
      );
      result = mapped
          .property(
            type.isFicIList
                ? 'toIList'
                : type.isFicISet
                    ? 'toISet'
                    : isSet
                        ? 'toSet'
                        : 'toList',
          )
          .call([]);
    }

    if (type.isBuiltList || type.isBuiltSet) {
      final builder = type.isBuiltList ? 'ListBuilder' : 'SetBuilder';
      final built = type.isBuiltList ? 'BuiltList' : 'BuiltSet';
      result = _isBuiltTarget(context)
          ? refer(builder).call([result])
          : refer(built).property('of').call([result]);
    } else if (identity && type.isFicIList) {
      result = result.property('toIList').call([]);
    } else if (identity && type.isFicISet) {
      result = result.property('toISet').call([]);
    } else if (type.isFicListSet) {
      result = _ficReference(context, type).property('of').call([result]);
    }

    return _guard(raw, nullable, defaultExpression, result,
        defaultFolded: true);
  }

  Expression _readMap(
    ExpressionContext context,
    Expression raw,
    DartType type, {
    required bool nullable,
    Expression? defaultExpression,
    MappingMethod? extra,
  }) {
    final generics = type.asGenerics;
    final key = generics?.firstOrNull;
    final value = generics != null && generics.length > 1 ? generics[1] : null;
    final keyName = key == null
        ? 'dynamic'
        : context.resolveType(key, withNullability: key.isNullable);
    final valueName = value == null
        ? 'dynamic'
        : context.resolveType(value, withNullability: value.isNullable);
    final convertsKey = key != null && key.isEnum;
    final convertsValue = extra != null || _needsConversion(value);

    Expression result;
    if (!convertsKey && !convertsValue) {
      result = TypeReference(
        (b) => b
          ..symbol = 'Map'
          ..types.addAll([refer(keyName), refer(valueName)]),
      ).newInstanceNamed(
        'from',
        [_container(raw, 'Map', defaultExpression, parenthesized: false)],
      );
    } else {
      final keyExpression = convertsKey
          ? _read(context, refer('key'), key, nullable: false)
          : key == null || key is DynamicType
              ? refer('key')
              : refer('key').castTo(keyName);
      final valueExpression = value == null
          ? refer('value')
          : _read(
              context,
              refer('value'),
              value,
              nullable: value.isNullable,
              extra: extra,
            );

      result = _container(raw, 'Map', defaultExpression).property('map').call(
        [
          Method(
            (b) => b
              ..requiredParameters.addAll([
                Parameter((p) => p.name = 'key'),
                Parameter((p) => p.name = 'value'),
              ])
              ..body = refer('MapEntry')
                  .newInstance([keyExpression, valueExpression]).code,
          ).closure,
        ],
        {},
        [refer(keyName), refer(valueName)],
      );
    }

    if (type.isBuiltMap) {
      result = _isBuiltTarget(context)
          ? refer('MapBuilder').call([result])
          : refer('BuiltMap').property('of').call([result]);
    } else if (type.isFicIMap) {
      result = result.property('toIMap').call([]);
    } else if (type.isFicListMap) {
      result = _ficReference(context, type).property('of').call([result]);
    }

    return _guard(raw, nullable, defaultExpression, result,
        defaultFolded: true);
  }

  /// The class of the fast_immutable_collections collection [type], with
  /// the prefix of its import.
  Expression _ficReference(ExpressionContext context, DartType type) => refer(
        chainDot([context.resolvePrefix(type), type.element?.name]),
      );

  /// `raw as Iterable`, or `(raw as Iterable? ?? default)` when a default is given.
  Expression _container(
    Expression raw,
    String name,
    Expression? defaultExpression, {
    bool parenthesized = true,
  }) {
    if (defaultExpression == null) {
      final cast = raw.castTo(name);

      return parenthesized ? cast.parenthesized : cast;
    }

    final value = raw.castTo('$name?').orElse(defaultExpression);

    return parenthesized ? value.parenthesized : value;
  }

  /// Maps [value] only when [raw] is present; absent values fall back to the
  /// default (or `null`). Containers fold their default into the cast
  /// ([defaultFolded]).
  Expression _guard(
    Expression raw,
    bool nullable,
    Expression? defaultExpression,
    Expression value, {
    bool defaultFolded = false,
  }) {
    if (defaultFolded) {
      return nullable && defaultExpression == null
          ? raw.isNotNull.conditional(value, literalNull)
          : value;
    }

    if (defaultExpression == null) {
      return nullable ? raw.isNotNull.conditional(value, literalNull) : value;
    }

    return raw.isNotNull.conditional(value, defaultExpression);
  }

  bool _needsConversion(DartType? type) {
    if (type == null || type is DynamicType || type.isDartCoreObject) {
      return false;
    }

    return type.isIterable ||
        type.isMap ||
        type.isEnum ||
        type.isDartCoreDouble ||
        needsGeneratedMapping(type);
  }

  /// Whether [a] and [b] are the same type, ignoring only their top-level
  /// nullability. Analyzer types are compared, not their names: same-named
  /// classes of different libraries and the nullability of type arguments
  /// (`List<int?>` and `List<int>`) still set them apart.
  bool _sameBase(DartType a, DartType b) {
    final system = (a.element ?? b.element)?.library?.typeSystem;
    if (system == null) {
      return a == b;
    }

    return system.promoteToNonNull(a) == system.promoteToNonNull(b);
  }
}

/// Whether [type] is a class that must be read through a (generated or
/// declared) Map -> class mapping method.
bool needsGeneratedMapping(DartType type) {
  final element = type.element;

  return element != null &&
      element.classElementOrNull != null &&
      !type.isEnum &&
      !type.isPrimitive &&
      !type.isDartCoreObject &&
      !type.isIterable &&
      !type.isMap &&
      !type.isLibraryFic &&
      element.library?.isInSdk != true;
}
