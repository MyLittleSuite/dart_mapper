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
import 'package:code_builder/code_builder.dart';
import 'package:dart_mapper_generator/src/extensions/dart_type.dart';
import 'package:dart_mapper_generator/src/extensions/expression.dart';
import 'package:dart_mapper_generator/src/extensions/mapping_method.dart';
import 'package:dart_mapper_generator/src/factories/expression_factory.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/bases/mapping_method.dart';

/// Creates the value of a map entry from a property of the source class
/// (`MappingBehavior.toMap`).
///
/// The type of the counterpart (target) field is the type of the value stored
/// in the map, as computed by the analyzer: comparing it with the type of the
/// source property tells which conversions are required (enum names, nested
/// maps, plain collections instead of built_value ones).
class ToMapExpressionFactory extends ExpressionFactory {
  const ToMapExpressionFactory();

  @override
  Expression create(ExpressionContext context) {
    if (context.expression != null ||
        context.constant != null ||
        context.expressionMappingMethod != null) {
      return basic(context);
    }

    final chainNullable = context.accessChain?.any((e) => e.$2) ?? false;
    final nullable =
        !context.forceNonNull && (context.field.nullable || chainNullable);

    final (value, conditional) = _convert(
      context,
      sourceOnly(context),
      context.field.type,
      context.counterpartField.type,
      nullable: nullable,
      parenthesizeSource: chainNullable && !context.forceNonNull,
      depth: 0,
    );

    if (context.defaultValue != null) {
      final defaultExpr = context.counterpartField.type.isDartCoreString
          ? literalString(context.defaultValue!)
          : CodeExpression(Code(context.defaultValue!));

      return (conditional ? value.parenthesized : value)
          .ifNullThen(defaultExpr);
    }

    return value;
  }

  /// Returns the converted expression and whether it is a conditional
  /// expression (which needs parentheses when used as operand).
  (Expression, bool) _convert(
    ExpressionContext context,
    Expression source,
    DartType sourceType,
    DartType wireType, {
    required bool nullable,
    required bool parenthesizeSource,
    required int depth,
  }) {
    final extra = context.extraMappingMethod;
    if (extra != null && _isWholeMatch(extra, sourceType)) {
      return _call(extra, source, nullable, parenthesizeSource);
    }

    if (sourceType.isEnum) {
      if (wireType.isEnum) return (source, false);

      return (
        nullable ? source.nullSafeProperty('name') : source.property('name'),
        false,
      );
    }

    if (sourceType.isIterable) {
      return _convertIterable(
        context,
        source,
        sourceType,
        wireType,
        nullable: nullable,
        depth: depth,
      );
    }

    if (sourceType.isMap) {
      return _convertMap(
        context,
        source,
        sourceType,
        wireType,
        nullable: nullable,
        depth: depth,
      );
    }

    return (source, false);
  }

  (Expression, bool) _convertIterable(
    ExpressionContext context,
    Expression source,
    DartType sourceType,
    DartType wireType, {
    required bool nullable,
    required int depth,
  }) {
    final sourceItem = sourceType.asGenerics?.firstOrNull;
    final wireItem =
        wireType.isIterable ? wireType.asGenerics?.firstOrNull : null;
    if (sourceItem == null || wireItem == null) return (source, false);

    if (_same(sourceItem, wireItem)) {
      final plainName = sourceType.isBuiltList || sourceType.isFicIList
          ? 'toList'
          : sourceType.isBuiltSet || sourceType.isFicISet
              ? 'toSet'
              : null;
      if (plainName == null) return (source, false);

      return (
        (nullable
                ? source.nullSafeProperty(plainName)
                : source.property(plainName))
            .call([]),
        false,
      );
    }

    final itemName = depth == 0 ? 'item' : 'item$depth';
    final (converted, _) = _convert(
      context,
      refer(itemName),
      sourceItem,
      wireItem,
      nullable: sourceItem.isNullable,
      parenthesizeSource: false,
      depth: depth + 1,
    );

    final mapped =
        (nullable ? source.nullSafeProperty('map') : source.property('map'))
            .call([
      _closure([itemName], converted)
    ]);

    return (mapped.property('toList').call([]), false);
  }

  (Expression, bool) _convertMap(
    ExpressionContext context,
    Expression source,
    DartType sourceType,
    DartType wireType, {
    required bool nullable,
    required int depth,
  }) {
    final sourceGenerics = sourceType.asGenerics;
    final wireGenerics = wireType.isMap ? wireType.asGenerics : null;
    if (sourceGenerics == null ||
        wireGenerics == null ||
        sourceGenerics.length != 2 ||
        wireGenerics.length != 2) {
      return (source, false);
    }

    final keyChanged = !_same(sourceGenerics[0], wireGenerics[0]);
    final valueChanged = !_same(sourceGenerics[1], wireGenerics[1]);

    // Built and immutable maps are stored as plain maps.
    final built = sourceType.isBuiltMap;
    final immutable = sourceType.isFicIMap;
    Expression plain() {
      if (immutable) {
        return nullable
            ? source.nullSafeProperty('unlock')
            : source.property('unlock');
      }

      return (nullable
              ? source.nullSafeProperty('toMap')
              : source.property('toMap'))
          .call([]);
    }

    if (!keyChanged && !valueChanged) {
      return (built || immutable ? plain() : source, false);
    }

    final suffix = depth == 0 ? '' : '$depth';
    final keyName = 'key$suffix';
    final valueName = 'value$suffix';

    final keyExpression = keyChanged && sourceGenerics[0].isEnum
        ? (sourceGenerics[0].isNullable
            ? refer(keyName).nullSafeProperty('name')
            : refer(keyName).property('name'))
        : refer(keyName);
    final valueExpression = valueChanged
        ? _convert(
            context,
            refer(valueName),
            sourceGenerics[1],
            wireGenerics[1],
            nullable: sourceGenerics[1].isNullable,
            parenthesizeSource: false,
            depth: depth + 1,
          ).$1
        : refer(valueName);

    Expression base = source;
    var nullAware = nullable;
    if (built || immutable) {
      base = plain();
      nullAware = false;
    }

    final mapped =
        (nullAware ? base.nullSafeProperty('map') : base.property('map')).call([
      _closure(
        [keyName, valueName],
        refer('MapEntry').newInstance([keyExpression, valueExpression]),
      ),
    ]);

    return (mapped, false);
  }

  (Expression, bool) _call(
    MappingMethod method,
    Expression source,
    bool nullable,
    bool parenthesizeSource,
  ) {
    final parameterNullable = method.firstParameterType?.isNullable ?? false;
    if (nullable && !parameterNullable) {
      final nonNull =
          (parenthesizeSource ? source.parenthesized : source).nullChecked;

      return (
        source.isNotNull.conditional(
          refer(method.name).call([nonNull]),
          literalNull,
        ),
        true,
      );
    }

    return (refer(method.name).call([source]), false);
  }

  Expression _closure(List<String> parameters, Expression body) => Method((b) {
        b.requiredParameters.addAll(
          parameters.map((name) => Parameter((p) => p.name = name)),
        );
        b.body = body.code;
      }).closure;

  bool _isWholeMatch(MappingMethod method, DartType type) {
    final parameter = method.firstParameterType;

    return parameter != null && _same(parameter, type);
  }

  bool _same(DartType a, DartType b) => a.displayString == b.displayString;
}
