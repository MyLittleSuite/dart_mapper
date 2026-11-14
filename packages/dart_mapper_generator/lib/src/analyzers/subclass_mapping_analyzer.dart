/*
 * Copyright (c) 2025 MyLittleSuite
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

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dart_mapper_generator/src/analyzers/contexts/analyzer_context.dart';
import 'package:dart_mapper_generator/src/exceptions/ambiguous_inherit_configuration_error.dart';
import 'package:dart_mapper_generator/src/exceptions/duplicate_discriminator_value_error.dart';
import 'package:dart_mapper_generator/src/exceptions/incompatible_discriminator_value_error.dart';
import 'package:dart_mapper_generator/src/exceptions/invalid_subclass_mapping_side_error.dart';
import 'package:dart_mapper_generator/src/exceptions/map_to_map_mapping_not_supported_error.dart';
import 'package:dart_mapper_generator/src/exceptions/missing_discriminator_key_error.dart';
import 'package:dart_mapper_generator/src/exceptions/missing_discriminator_value_error.dart';
import 'package:dart_mapper_generator/src/exceptions/no_subclass_mapping_method_error.dart';
import 'package:dart_mapper_generator/src/exceptions/unexpected_discriminator_key_error.dart';
import 'package:dart_mapper_generator/src/exceptions/unexpected_discriminator_value_error.dart';
import 'package:dart_mapper_generator/src/exceptions/unsupported_discriminator_value_error.dart';
import 'package:dart_mapper_generator/src/extensions/annotations.dart';
import 'package:dart_mapper_generator/src/extensions/dart_type.dart';
import 'package:dart_mapper_generator/src/extensions/element.dart';
import 'package:dart_mapper_generator/src/models/field/field.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/mapping_parameter.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/subclass_mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapping_behavior.dart';

/// The @SubclassMapping annotations and the @DiscriminatorKey of a dispatch
/// method, own or inherited.
typedef _DispatchConfig = ({
  List<ResolvedSubclassMapping> mappings,
  String? key,
});

/// A discriminator value with its comparison kind (`String`, `int`, `double`,
/// `bool` or the name of the enum).
typedef _DiscriminatorValue = ({String kind, Object value});

/// Reads @SubclassMapping annotations from each abstract MethodElement and
/// produces SubclassMappingMethod instances — one per annotated dispatch method.
///
/// Three kinds of dispatch methods are supported, told apart by signature:
/// class -> class ([SubclassDispatchMode.type]), Map -> class hierarchy
/// ([SubclassDispatchMode.fromMap]) and class hierarchy -> Map
/// ([SubclassDispatchMode.toMap]). A method with @InheritInverseConfiguration
/// or @InheritConfiguration and no own @SubclassMapping inherits the ones of
/// the method it refers to.
class SubclassMappingAnalyzer {
  const SubclassMappingAnalyzer();

  /// Returns a list of [SubclassMappingMethod]s to inject into the method list.
  /// Returns empty list when no abstract method has @SubclassMapping annotations.
  List<SubclassMappingMethod> analyze(AnalyzerContext context) {
    if (DiscriminatorKeyAnnotation.isPresent(context.mapperClass)) {
      throw UnexpectedDiscriminatorKeyError.onClass(
        mapperClass: context.mapperClass,
      );
    }

    final result = <SubclassMappingMethod>[];

    for (final method in context.mappingMethods) {
      final config = _loadConfig(context, method);
      if (config == null) {
        if (DiscriminatorKeyAnnotation.isPresent(method)) {
          throw UnexpectedDiscriminatorKeyError.withoutSubclassMapping(
            method: method,
          );
        }
        continue;
      }

      result.add(_analyzeMethod(context, method, config));
    }

    return result;
  }

  SubclassMappingMethod _analyzeMethod(
    AnalyzerContext context,
    MethodElement method,
    _DispatchConfig config,
  ) {
    final parameters = method.formalParameters;
    final returnType = method.returnType;
    final mapParameter =
        parameters.where((p) => p.type.isMapLikeSource).firstOrNull;

    final SubclassDispatchMode mode;
    if (mapParameter != null) {
      if (returnType.isMap) {
        throw MapToMapMappingNotSupportedError(method: method);
      }
      mode = SubclassDispatchMode.fromMap;
    } else if (parameters.length == 1 &&
        !parameters.first.type.isMap &&
        returnType.isStringKeyedMap) {
      mode = SubclassDispatchMode.toMap;
    } else {
      mode = SubclassDispatchMode.type;
    }

    final key = _validate(method, mode, config);
    final values = mode == SubclassDispatchMode.type
        ? const <_DiscriminatorValue>[]
        : _values(method, config);

    final dispatchPairs = <SubclassDispatchPair>[];
    for (final (index, mapping) in config.mappings.indexed) {
      switch (mode) {
        case SubclassDispatchMode.type:
          final sourceType = mapping.sourceType!;
          final targetType = mapping.targetType!;
          dispatchPairs.add(SubclassDispatchPair(
            sourceType: sourceType,
            targetType: targetType,
            delegateMethod: _resolveDelegateMethod(
              context: context,
              sourceType: sourceType,
              targetType: targetType,
            ),
          ));
        case SubclassDispatchMode.fromMap:
          final targetType = mapping.targetType!;
          dispatchPairs.add(SubclassDispatchPair(
            sourceType: mapParameter!.type,
            targetType: targetType,
            delegateMethod: _resolveFromMapDelegate(
              context: context,
              method: method,
              targetType: targetType,
            ),
            discriminatorValue: values[index].value,
          ));
        case SubclassDispatchMode.toMap:
          final sourceType = mapping.sourceType!;
          final delegate = _resolveToMapDelegate(
            context: context,
            method: method,
            sourceType: sourceType,
          );
          dispatchPairs.add(SubclassDispatchPair(
            sourceType: sourceType,
            targetType: returnType,
            delegateMethod: delegate.name!,
            discriminatorValue: values[index].value,
            delegateReturnsNullable: delegate.returnType.isNullable,
          ));
      }
    }

    final baseType = parameters.first.type;
    final needsWildcard = switch (mode) {
      SubclassDispatchMode.fromMap => true,
      SubclassDispatchMode.type => _computeNeedsWildcard(
          baseType: baseType,
          dispatchPairs: dispatchPairs,
        ),
      // A nullable base is guarded against null only when the method may
      // return null.
      SubclassDispatchMode.toMap =>
        (baseType.isNullable && !returnType.isNullable) ||
            _computeNeedsWildcard(
              baseType: baseType,
              dispatchPairs: dispatchPairs,
            ),
    };

    return SubclassMappingMethod(
      name: method.name!,
      returnType: method.returnType,
      optionalReturn: method.returnType.isNullable,
      isOverride: true,
      parameters: method.formalParameters
          .map((p) => MappingParameter(
                field: Field.from(
                  name: p.name!,
                  type: p.type,
                  nullable: p.isNullable,
                ),
                isNullable: p.isNullable,
              ))
          .toList(growable: false),
      bindings: const [],
      behavior: MappingBehavior.standard,
      dispatchPairs: dispatchPairs,
      needsWildcard: needsWildcard,
      mode: mode,
      discriminatorKey: key,
      discriminatorParameter: mapParameter?.name,
    );
  }

  /// Validates [config] against the signature of [method]. Returns the
  /// discriminator key, null in [SubclassDispatchMode.type].
  String? _validate(
    MethodElement method,
    SubclassDispatchMode mode,
    _DispatchConfig config,
  ) {
    switch (mode) {
      case SubclassDispatchMode.type:
        if (config.key != null ||
            DiscriminatorKeyAnnotation.isPresent(method)) {
          throw UnexpectedDiscriminatorKeyError.onTypeDispatch(method: method);
        }
        for (final mapping in config.mappings) {
          if (mapping.discriminatorValue != null) {
            throw UnexpectedDiscriminatorValueError(method: method);
          }
          if (mapping.sourceType == null || mapping.targetType == null) {
            throw InvalidSubclassMappingSideError.missingTypes(method: method);
          }
        }
        return null;
      case SubclassDispatchMode.fromMap:
      case SubclassDispatchMode.toMap:
        final key = config.key;
        if (key == null) {
          throw MissingDiscriminatorKeyError(method: method);
        }
        if (key.isEmpty) {
          throw MissingDiscriminatorKeyError(method: method, empty: true);
        }

        final fromMap = mode == SubclassDispatchMode.fromMap;
        for (final mapping in config.mappings) {
          if (fromMap && mapping.sourceType != null) {
            throw InvalidSubclassMappingSideError.sourceOnMapSource(
              method: method,
            );
          }
          if (!fromMap && mapping.targetType != null) {
            throw InvalidSubclassMappingSideError.targetOnMapTarget(
              method: method,
            );
          }
          if (fromMap && mapping.targetType == null) {
            throw InvalidSubclassMappingSideError.missingTarget(
              method: method,
            );
          }
          if (!fromMap && mapping.sourceType == null) {
            throw InvalidSubclassMappingSideError.missingSource(
              method: method,
            );
          }
        }

        final values = _values(method, config);
        if (!fromMap) {
          _validateMapValueType(method, values);
        }
        return key;
    }
  }

  /// The validated discriminator values of [config], in declaration order:
  /// all of a supported and the same type, with no duplicates.
  List<_DiscriminatorValue> _values(
    MethodElement method,
    _DispatchConfig config,
  ) {
    final values = <_DiscriminatorValue>[];
    for (final mapping in config.mappings) {
      final object = mapping.discriminatorValue;
      if (object == null) {
        final subclass = mapping.targetType ?? mapping.sourceType;
        throw MissingDiscriminatorValueError(
          method: method,
          subclass: subclass?.getDisplayString() ?? '?',
        );
      }

      final value = _readValue(method, object);
      final first = values.firstOrNull;
      if (first != null && first.kind != value.kind) {
        throw UnsupportedDiscriminatorValueError.mixed(
          method: method,
          first: first.kind,
          other: value.kind,
        );
      }
      if (values.any((v) => v.value == value.value)) {
        throw DuplicateDiscriminatorValueError(
          method: method,
          value: value.value,
        );
      }
      values.add(value);
    }

    return values;
  }

  _DiscriminatorValue _readValue(MethodElement method, DartObject object) {
    final type = object.type;
    if (type == null) {
      throw UnsupportedDiscriminatorValueError.type(
        method: method,
        valueType: 'unknown',
      );
    }

    if (type.isDartCoreString) {
      return (kind: 'String', value: object.toStringValue()!);
    }
    if (type.isDartCoreInt) {
      return (kind: 'int', value: object.toIntValue()!);
    }
    if (type.isDartCoreDouble) {
      return (kind: 'double', value: object.toDoubleValue()!);
    }
    if (type.isDartCoreBool) {
      return (kind: 'bool', value: object.toBoolValue()!);
    }

    final element = type.element;
    if (element is EnumElement) {
      final name = object.getField('_name')?.toStringValue() ??
          element.constants
              .elementAtOrNull(object.getField('index')?.toIntValue() ?? -1)
              ?.name;
      if (name != null) {
        return (kind: element.name ?? 'enum', value: name);
      }
    }

    throw UnsupportedDiscriminatorValueError.type(
      method: method,
      valueType: type.getDisplayString(),
    );
  }

  /// Checks the discriminator values fit the value type of the `Map` returned
  /// by [method].
  void _validateMapValueType(
    MethodElement method,
    List<_DiscriminatorValue> values,
  ) {
    final first = values.firstOrNull;
    final mapType = method.returnType;
    if (first == null || mapType is! InterfaceType) {
      return;
    }

    final valueType = mapType.typeArguments.elementAtOrNull(1);
    if (valueType == null ||
        valueType is DynamicType ||
        valueType.isDartCoreObject) {
      return;
    }

    final accepted = switch (first.value) {
      String() => valueType.isDartCoreString,
      int() => valueType.isDartCoreInt || valueType.isDartCoreNum,
      double() => valueType.isDartCoreDouble || valueType.isDartCoreNum,
      bool() => valueType.isDartCoreBool,
      _ => false,
    };
    if (!accepted) {
      throw IncompatibleDiscriminatorValueError(
        method: method,
        valueType: first.value is String ? 'String' : first.kind,
        mapType: mapType.getDisplayString(),
      );
    }
  }

  /// The own @SubclassMapping annotations of [method], else the ones it
  /// inherits through @InheritInverseConfiguration or @InheritConfiguration.
  /// Null when [method] is not a dispatch method.
  _DispatchConfig? _loadConfig(AnalyzerContext context, MethodElement method) {
    final ownKey = DiscriminatorKeyAnnotation.loadFirst(method);
    final own = SubclassMappingAnnotation.loadAll(method).toList();
    if (own.isNotEmpty) {
      return (mappings: own, key: ownKey);
    }

    final inverse =
        InheritInverseConfigurationAnnotation.loadFirst(method) != null;
    if (!inverse && InheritConfigurationAnnotation.loadFirst(method) == null) {
      return null;
    }

    final source = _findInheritedSource(context, method, inverse: inverse);
    if (source == null) {
      return null;
    }

    final inherited = SubclassMappingAnnotation.loadAll(source).map(
      (mapping) => inverse
          ? (
              sourceType: mapping.targetType,
              targetType: mapping.sourceType,
              discriminatorValue: mapping.discriminatorValue,
            )
          : mapping,
    );

    return (
      mappings: inherited.toList(growable: false),
      key: ownKey ?? DiscriminatorKeyAnnotation.loadFirst(source),
    );
  }

  /// Finds the dispatch method [method] inherits from, matched like
  /// `InheritConfigurationAnalyzer` does: the very same signature (swapped for
  /// [inverse]) first, then the one differing only by the kind of `Map`.
  MethodElement? _findInheritedSource(
    AnalyzerContext context,
    MethodElement method, {
    required bool inverse,
  }) {
    final parameters = method.formalParameters;
    if (inverse && parameters.length != 1) {
      return null;
    }

    final candidates = context.mapperClass.methods
        .where((m) => m != method)
        .where((m) => SubclassMappingAnnotation.loadAll(m).isNotEmpty)
        .toList(growable: false);

    final expectedReturn = inverse ? parameters.first.type : method.returnType;
    final expectedParameters =
        inverse ? [method.returnType] : parameters.map((p) => p.type).toList();

    bool matches(MethodElement m, bool Function(DartType, DartType) same) =>
        same(m.returnType, expectedReturn) &&
        m.formalParameters.length == expectedParameters.length &&
        m.formalParameters.indexed
            .every((e) => same(e.$2.type, expectedParameters[e.$1]));

    bool exact(DartType a, DartType b) =>
        a.same(b, useNullability: false, aliases: context.importAliases);
    bool relaxed(DartType a, DartType b) =>
        exact(a, b) || (a.isMapLikeSource && b.isMapLikeSource);

    final exactMatches =
        candidates.where((m) => matches(m, exact)).toList(growable: false);
    if (exactMatches.isNotEmpty) {
      return exactMatches.first;
    }

    final relaxedMatches =
        candidates.where((m) => matches(m, relaxed)).toList(growable: false);
    if (relaxedMatches.length > 1) {
      throw AmbiguousInheritConfigurationError(
        method: method.displayName,
        candidates: relaxedMatches.map((m) => m.displayName).toList(),
        element: method,
      );
    }

    return relaxedMatches.firstOrNull;
  }

  /// Resolves the delegate method name for a given @SubclassMapping pair.
  /// Throws [NoSubclassMappingMethodError] when no matching method is found (D-06).
  String _resolveDelegateMethod({
    required AnalyzerContext context,
    required DartType sourceType,
    required DartType targetType,
  }) {
    final match = context.mapperClass.methods
        .where(
          (m) =>
              m.formalParameters.length == 1 &&
              m.formalParameters.first.type
                  .same(sourceType, useNullability: false) &&
              m.returnType.same(targetType, useNullability: false),
        )
        .firstOrNull;

    if (match == null) {
      throw NoSubclassMappingMethodError(
        sourceType: sourceType,
        targetType: targetType,
        mapperClass: context.mapperClass,
      );
    }

    return match.name!;
  }

  /// Resolves the method turning the parameters of the dispatch [method] into
  /// [targetType]: the very same parameter types first, then Map-like
  /// parameters the dispatch one is assignable to.
  ///
  /// Only positional delegates are considered, as the dispatch forwards its
  /// parameters positionally, and a delegate returning a nullable value is
  /// skipped unless the dispatch [method] returns a nullable value as well.
  String _resolveFromMapDelegate({
    required AnalyzerContext context,
    required MethodElement method,
    required DartType targetType,
  }) {
    final system = context.mapperClass.library.typeSystem;
    final candidates = context.mapperClass.methods
        .where((m) => m != method)
        .where((m) => m.returnType.same(targetType, useNullability: false))
        .where((m) => method.returnType.isNullable || !m.returnType.isNullable)
        .where(
            (m) => m.formalParameters.length == method.formalParameters.length)
        .toList(growable: false);

    // The Map parameter the discriminator is read from is null-checked before
    // the dispatch, so a delegate taking a non-nullable Map accepts it.
    final mapParameter =
        method.formalParameters.where((p) => p.type.isMapLikeSource).first;

    bool matches(
      MethodElement m,
      bool Function(DartType delegate, FormalParameterElement dispatch) same,
    ) =>
        m.formalParameters.indexed.every(
          (e) =>
              e.$2.isPositional &&
              same(e.$2.type, method.formalParameters[e.$1]),
        );

    // What the dispatch passes to the delegate: only the discriminator Map is
    // promoted, the auxiliary parameters keep their nullability.
    bool accepts(DartType delegate, FormalParameterElement dispatch) =>
        system.isAssignableTo(
          dispatch == mapParameter
              ? system.promoteToNonNull(dispatch.type)
              : dispatch.type,
          delegate,
        );

    bool exact(DartType delegate, FormalParameterElement dispatch) =>
        delegate.same(dispatch.type, useNullability: false) &&
        accepts(delegate, dispatch);
    bool relaxed(DartType delegate, FormalParameterElement dispatch) =>
        exact(delegate, dispatch) ||
        (delegate.isMapLikeSource &&
            dispatch.type.isMapLikeSource &&
            accepts(delegate, dispatch));

    final match = candidates.where((m) => matches(m, exact)).firstOrNull ??
        candidates.where((m) => matches(m, relaxed)).firstOrNull;
    if (match == null) {
      throw NoSubclassMappingMethodError.fromMap(
        targetType: targetType,
        method: method,
      );
    }

    return match.name!;
  }

  /// Resolves the method turning [sourceType] into a `Map` assignable to the
  /// return type of the dispatch [method].
  ///
  /// Only delegates taking the subclass as a positional parameter are
  /// considered, as the dispatch calls them positionally. The nullability of
  /// the delegate `Map` itself is ignored (a null result is not spread), while
  /// the one of its keys and values is checked.
  MethodElement _resolveToMapDelegate({
    required AnalyzerContext context,
    required MethodElement method,
    required DartType sourceType,
  }) {
    final candidates = context.mapperClass.methods
        .where((m) => m != method)
        .where((m) => m.formalParameters.length == 1)
        .where((m) => m.formalParameters.first.isPositional)
        .where((m) => m.formalParameters.first.type.same(
              sourceType,
              useNullability: false,
            ))
        .toList(growable: false);

    final system = context.mapperClass.library.typeSystem;
    final returnType = system.promoteToNonNull(method.returnType);

    bool exact(DartType type) => system.promoteToNonNull(type) == returnType;
    bool assignable(DartType type) =>
        system.isAssignableTo(system.promoteToNonNull(type), returnType);

    final match = candidates.where((m) => exact(m.returnType)).firstOrNull ??
        candidates.where((m) => assignable(m.returnType)).firstOrNull;
    if (match == null) {
      throw NoSubclassMappingMethodError.toMap(
        sourceType: sourceType,
        method: method,
      );
    }

    return match;
  }

  /// Computes whether a wildcard fallthrough arm must be emitted (D-04).
  ///
  /// Returns false only when [baseType] is sealed AND every direct subtype
  /// of [baseType] within the sealed class's own library is present in
  /// [dispatchPairs]. In all other cases returns true.
  bool _computeNeedsWildcard({
    required DartType baseType,
    required List<SubclassDispatchPair> dispatchPairs,
  }) {
    final baseElement = baseType.element?.classElementOrNull;
    if (baseElement == null || !baseElement.isSealed) return true;

    // Scan the sealed class's own library for subtypes.
    // Uses allSupertypes to include classes that implement or mixin the sealed
    // base (not just direct extends), so sealed interface coverage is complete.
    final directSubtypes = baseElement.library.classes
        .where((cls) => cls.allSupertypes.any((t) => t.element == baseElement))
        .toList();

    if (directSubtypes.isEmpty) return true;

    // All direct subtypes must be in dispatchPairs.
    return !directSubtypes.every(
        (subtype) => dispatchPairs.any((p) => p.sourceType.element == subtype));
  }
}
