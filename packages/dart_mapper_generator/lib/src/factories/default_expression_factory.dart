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
import 'package:dart_mapper_generator/src/misc/strings.dart';
import 'package:dart_mapper_generator/src/models/field/field.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/bases/mapping_method.dart';

class DefaultExpressionFactory extends ExpressionFactory {
  @override
  Expression create(ExpressionContext context) {
    // Constant bindings: skip all collection/nested/map special handling.
    if (context.constant != null) {
      return super.basic(context);
    }

    final basicExpression = super.basic(context);

    // Dynamic fields use direct assignment, no conversion
    if (context.field is DynamicField) {
      return basicExpression;
    }

    if (context.expressionMappingMethod == null) {
      if (context.field is MapField) {
        return _createMap(context, context.field as MapField);
      } else if (context.field is IterableField) {
        return _createIterable(context);
      } else if ((context.field is NestedField ||
              context.field is EnumField ||
              context.field is PrimitiveField) &&
          context.extraMappingMethod != null) {
        return _mapFieldWithMethod(context, context.extraMappingMethod!);
      }
    }

    return basicExpression;
  }

  Expression _createMap(
    ExpressionContext context,
    MapField field,
  ) {
    final basicExpression = super.basic(context);
    final extra = context.extraMappingMethod;
    final sourceType = field.type;
    final targetType = context.counterpartField.type;
    final nullable = field.nullable && !context.forceNonNull;

    // A method converting the whole map is called as it is.
    final returnType = extra?.returnType;
    if (returnType != null &&
        (returnType.isMap || returnType.isFicIMapOfSets)) {
      return nullable
          ? basicExpression.conditionalNull(
              refer(extra!.name).call([basicExpression.nullChecked]),
            )
          : refer(extra!.name).call([basicExpression]);
    }

    if (extra == null && _isShared(sourceType, targetType)) {
      return basicExpression;
    }

    if (sourceType.isFicIMapOfSets || targetType.isFicIMapOfSets) {
      return _createMapOfSets(context, field, basicExpression);
    }

    // The entries are mapped one by one to convert their values, or to copy
    // the map. Changing the type of the map is already a copy.
    final converts = extra != null ||
        !(sourceType.isFicIMap || targetType.isFicMap) ||
        (sourceType.isFicIMap && targetType.isFicIMap);
    Expression mapped(Expression receiver, {required bool nullAware}) =>
        converts
            ? (nullAware
                    ? receiver.nullSafeProperty('map')
                    : receiver.property('map'))
                .call([
                _entryClosure(_convertItem(context, refer('value'))),
              ])
            : receiver;

    final entries = mapped(basicExpression, nullAware: field.nullable);
    Expression access(Expression receiver, String name) =>
        field.nullable && !converts
            ? receiver.nullSafeProperty(name)
            : receiver.property(name);

    if (targetType.isDartCoreMap) {
      if (sourceType.isBuiltMap) {
        return entries.property('toMap').call([]);
      }

      return sourceType.isFicIMap ? access(entries, 'unlock') : entries;
    } else if (targetType.isBuiltMap) {
      if (!_isBuiltOwner(context)) {
        // Only the builder of a built_value class wraps the map: the other
        // classes hold the BuiltMap itself.
        return _construct(
          context,
          targetType,
          basicExpression,
          nullable: nullable,
          constructor: 'of',
          argument: (receiver) => _plainMap(
            mapped(receiver, nullAware: false),
            sourceType,
          ),
        );
      }

      // A MapBuilder is created from a Map or a BuiltMap only.
      return sourceType.isFicIMap ? access(entries, 'unlockView') : entries;
    } else if (targetType.isFicIMap) {
      if (sourceType.isFicIMap) {
        return entries;
      }

      return sourceType.isBuiltMap
          ? access(entries, 'asMap').call([]).property('toIMap').call([])
          : access(entries, 'toIMap').call([]);
    } else if (targetType.isFicListMap) {
      return _construct(
        context,
        targetType,
        basicExpression,
        nullable: nullable,
        constructor: 'of',
        argument: (receiver) => _plainMap(
          mapped(receiver, nullAware: false),
          sourceType,
        ),
      );
    }

    return entries;
  }

  /// The mapping of a field when its source or its target is an `IMapOfSets`.
  /// Only the items of the sets of an `IMapOfSets` are converted.
  Expression _createMapOfSets(
    ExpressionContext context,
    MapField field,
    Expression basicExpression,
  ) {
    final sourceType = field.type;
    final targetType = context.counterpartField.type;
    final nullable = field.nullable && !context.forceNonNull;
    final converts = context.extraMappingMethod != null;

    Expression access(String name) => field.nullable
        ? basicExpression.nullSafeProperty(name)
        : basicExpression.property(name);

    if (!sourceType.isFicIMapOfSets) {
      // The sets are given to the IMapOfSets as they are, or converted.
      return _construct(
        context,
        targetType,
        basicExpression,
        nullable: nullable,
        argument: (receiver) => _plainMap(
          converts
              ? receiver.property('map').call([
                  _entryClosure(_convertSet(context, refer('value'))),
                ])
              : receiver,
          sourceType,
        ),
      );
    }

    // The map of the target, whose sets hold the type of set of the target.
    final setType = targetType.asGenerics?.elementAtOrNull(1);
    Expression sets(Expression map, {required bool changesSets}) => converts ||
            changesSets
        ? map.property('map').call([
            _entryClosure(
              _setOf(context, setType, _convertSet(context, refer('value'))),
            ),
          ])
        : map;

    if (targetType.isFicIMapOfSets) {
      return access('map').call([
        _entryClosure(
          converts
              ? _convertSet(context, refer('value')).property('toISet').call([])
              : refer('value'),
        ),
      ]);
    } else if (targetType.isFicIMap) {
      return sets(
        access('asIMap').call([]),
        changesSets: _changesSets(setType, immutable: true),
      );
    } else if (targetType.isDartCoreMap) {
      return sets(
        access('unlock'),
        changesSets: _changesSets(setType, immutable: false),
      );
    }

    // The other maps are created out of a plain map whose sets are of the
    // type of the sets of the target.
    final changesSets = _changesSets(setType, immutable: false);
    if (targetType.isFicListMap ||
        (targetType.isBuiltMap && !_isBuiltOwner(context))) {
      return _construct(
        context,
        targetType,
        basicExpression,
        nullable: nullable,
        constructor: 'of',
        argument: (receiver) => sets(
          receiver.property('unlock'),
          changesSets: changesSets,
        ),
      );
    }

    return sets(access('unlock'), changesSets: changesSets);
  }

  Expression _createIterable(ExpressionContext context) {
    final sourceField = context.field as IterableField;
    final targetField = context.counterpartField as IterableField;
    final basicExpression = super.basic(context);
    final nullable = sourceField.nullable && !context.forceNonNull;

    if (context.extraMappingMethod?.returnType?.isIterable == true) {
      return nullable
          ? basicExpression.conditionalNull(
              refer(context.extraMappingMethod!.name).call(
                [basicExpression.nullChecked],
              ),
            )
          : refer(context.extraMappingMethod!.name).call([basicExpression]);
    }

    final targetType = targetField.type;
    if (context.extraMappingMethod == null &&
        _isShared(sourceField.type, targetType)) {
      return basicExpression;
    }

    final mapProperty = sourceField.nullable
        ? basicExpression.nullSafeProperty('map')
        : basicExpression.property('map');
    final cloneExpression = mapProperty.call([_itemClosure(context)]);

    // The collections of fast_immutable_collections are created out of the
    // source itself when its items are not converted.
    final converts = context.extraMappingMethod != null;

    if ((targetType.isBuiltList || targetType.isBuiltSet) &&
        !_isBuiltOwner(context)) {
      // Only the builder of a built_value class wraps the items: the other
      // classes hold the BuiltList or the BuiltSet itself.
      return _construct(
        context,
        targetType,
        basicExpression,
        nullable: nullable,
        constructor: 'of',
        argument: (receiver) => converts
            ? receiver.property('map').call([_itemClosure(context)])
            : receiver,
      );
    }

    Expression immutable(String name) => converts
        ? cloneExpression.property(name).call([])
        : (sourceField.nullable
                ? basicExpression.nullSafeProperty(name)
                : basicExpression.property(name))
            .call([]);

    if (targetType.isList) {
      return cloneExpression.propertyToList();
    } else if (targetType.isSet) {
      return cloneExpression.propertyToSet();
    } else if (targetType.isFicIList) {
      return immutable('toIList');
    } else if (targetType.isFicISet) {
      return immutable('toISet');
    } else if (targetType.isFicListSet) {
      return _construct(
        context,
        targetType,
        basicExpression,
        nullable: nullable,
        constructor: 'of',
        argument: (receiver) => converts
            ? receiver.property('map').call([_itemClosure(context)])
            : receiver,
      );
    } else if (targetType.isDartCoreIterable) {
      return cloneExpression;
    }

    return basicExpression;
  }

  /// Whether the mapped class is a built_value one: its builder wraps the
  /// built collections, so they are not created here.
  bool _isBuiltOwner(ExpressionContext context) =>
      context.currentMethod.returnType?.isBuiltValue == true;

  /// The items of the [set] of an `IMapOfSets`, converted by the extra mapping
  /// method if any.
  Expression _convertSet(ExpressionContext context, Expression set) =>
      context.extraMappingMethod == null
          ? set
          : set.property('map').call([_itemClosure(context)]);

  /// Whether the sets of a map, `ISet`s when [immutable] and `Set`s
  /// otherwise, are not of the [type] of the sets of the target. A set is
  /// compatible with an `Iterable` target as it is.
  bool _changesSets(DartType? type, {required bool immutable}) =>
      type != null &&
      !type.isDartCoreIterable &&
      !(immutable ? type.isFicISet : type.isDartCoreSet);

  /// The [items] as a set of the [type] given, a `Set` when it is unknown.
  Expression _setOf(
    ExpressionContext context,
    DartType? type,
    Expression items,
  ) {
    if (type == null || type.isDartCoreSet) {
      return items.property('toSet').call([]);
    } else if (type.isFicISet) {
      return items.property('toISet').call([]);
    } else if (type.isDartCoreIterable) {
      return items;
    } else if (!type.isBuiltSet && !type.isFicListSet) {
      return items.property('toSet').call([]);
    }

    return refer(
      chainDot([context.resolvePrefix(type), type.element?.name]),
    ).newInstanceNamed('of', [items]);
  }

  /// Whether a [source] value is assigned to the [target] as it is: an
  /// immutable collection is shared, there is no need to copy it.
  bool _isShared(DartType source, DartType target) {
    final system = target.element?.library?.typeSystem;

    return target.isFicImmutable &&
        system != null &&
        system.isSubtypeOf(
          system.promoteToNonNull(source),
          system.promoteToNonNull(target),
        );
  }

  /// `(item) => convert(item)`
  Expression _itemClosure(ExpressionContext context) => Method(
        (b) {
          final itemName = 'item';

          b.requiredParameters.add(
            Parameter(
              (b) => b..name = itemName,
            ),
          );
          b.body = _convertItem(context, refer(itemName)).code;
        },
      ).closure;

  /// `(key, value) => MapEntry(key, <value>)`
  Expression _entryClosure(Expression value) => Method((b) {
        b.requiredParameters.add(Parameter((b) => b..name = 'key'));
        b.requiredParameters.add(Parameter((b) => b..name = 'value'));
        b.body = refer('MapEntry').newInstance([
          refer('key'),
          value,
        ]).code;
      }).closure;

  /// The [item] of a collection, converted by the extra mapping method if
  /// any. A collection holds built values, never their builders.
  Expression _convertItem(ExpressionContext context, Expression item) {
    final extra = context.extraMappingMethod;
    if (extra == null) {
      return item;
    }

    final call = refer(extra.name).call([item]);
    if (!extra.returnsBuilder) {
      return call;
    }

    return (extra.optionalReturn
            ? call.nullSafeProperty('build')
            : call.property('build'))
        .call([]);
  }

  /// The [map], of the type of [sourceType], as a `dart:core` map.
  Expression _plainMap(Expression map, DartType sourceType) {
    if (sourceType.isBuiltMap) {
      return map.property('asMap').call([]);
    }

    return sourceType.isFicIMap ? map.property('unlockView') : map;
  }

  /// The instantiation of the collection [type] out of the [argument] made of
  /// the non-null source, `null` when the source is.
  Expression _construct(
    ExpressionContext context,
    DartType type,
    Expression basicExpression, {
    required bool nullable,
    required Expression Function(Expression receiver) argument,
    String? constructor,
  }) {
    final reference = refer(
      chainDot([context.resolvePrefix(type), type.element?.name]),
    );
    final arguments = [
      argument(nullable ? basicExpression.nullChecked : basicExpression),
    ];
    final instance = constructor != null
        ? reference.newInstanceNamed(constructor, arguments)
        : reference.newInstance(arguments);

    return nullable ? basicExpression.conditionalNull(instance) : instance;
  }

  Expression _mapFieldWithMethod(
    ExpressionContext context,
    MappingMethod extraMethod,
  ) {
    final sourceExpression = super.sourceOnly(context);

    Expression buildDefaultExpr() => context.counterpartField.type.isDartCoreString
        ? literalString(context.defaultValue!)
        : CodeExpression(Code(context.defaultValue!));

    if (context.field.nullable && !context.forceNonNull) {
      final submapperCall =
          refer(extraMethod.name).call([sourceExpression.nullChecked]);
      if (context.defaultValue != null) {
        final defaultExpr = buildDefaultExpr();
        return sourceExpression.isNotNull.conditional(
          submapperCall.ifNullThen(defaultExpr),
          defaultExpr,
        );
      }
      return sourceExpression.conditionalNull(submapperCall);
    }

    final submapperCall = refer(extraMethod.name).call([sourceExpression]);
    if (context.defaultValue != null) {
      return submapperCall.ifNullThen(buildDefaultExpr());
    }

    return submapperCall;
  }
}
