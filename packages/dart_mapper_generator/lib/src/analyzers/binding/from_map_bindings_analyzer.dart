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
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:dart_mapper_generator/src/analyzers/analyzer.dart';
import 'package:dart_mapper_generator/src/analyzers/binding/map_converter_lookup.dart';
import 'package:dart_mapper_generator/src/analyzers/contexts/analyzer_context.dart';
import 'package:dart_mapper_generator/src/analyzers/contexts/bindings_analyzer_context.dart';
import 'package:dart_mapper_generator/src/analyzers/contexts/fields_analyzer_context.dart';
import 'package:dart_mapper_generator/src/exceptions/ambiguous_source_field_error.dart';
import 'package:dart_mapper_generator/src/exceptions/from_map_target_not_instantiable_error.dart';
import 'package:dart_mapper_generator/src/exceptions/incompatible_map_value_type_error.dart';
import 'package:dart_mapper_generator/src/exceptions/map_target_dot_notation_unsupported_error.dart';
import 'package:dart_mapper_generator/src/exceptions/target_field_requires_non_optional_source_field_error.dart';
import 'package:dart_mapper_generator/src/exceptions/unknown_target_class_error.dart';
import 'package:dart_mapper_generator/src/extensions/class_element.dart';
import 'package:dart_mapper_generator/src/extensions/dart_type.dart';
import 'package:dart_mapper_generator/src/extensions/element.dart';
import 'package:dart_mapper_generator/src/extensions/mapping_method.dart';
import 'package:dart_mapper_generator/src/factories/from_map_expression_factory.dart';
import 'package:dart_mapper_generator/src/models/binding.dart';
import 'package:dart_mapper_generator/src/models/field/field.dart';
import 'package:dart_mapper_generator/src/models/field/map_entry_field.dart';
import 'package:dart_mapper_generator/src/models/instance.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/mapping_parameter.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/bases/mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/callable_mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/generated_private_mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapping_behavior.dart';
import 'package:source_gen/source_gen.dart';

/// Computes the bindings of a Map -> class mapping method.
///
/// Every property of the target class (constructor parameter, or abstract
/// getter for built values) is bound to a map key, or to a regular method
/// parameter in multi-source methods. Nested classes are read through a
/// declared method, a method of the `uses` mappers, or a generated private
/// method, in this order.
class FromMapBindingsAnalyzer extends Analyzer<List<Binding>> {
  final Analyzer<MappingMethod?> extraMappingMethodAnalyzer;

  const FromMapBindingsAnalyzer({
    required this.extraMappingMethodAnalyzer,
  });

  @override
  List<Binding> analyze(AnalyzerContext context) {
    if (context is! BindingsAnalyzerContext) {
      throw ArgumentError('context must be a BindingsAnalyzerContext');
    }

    context.validateMappingCombinations();
    context.validateCommaSeparatedSource();

    final config = _Config.from(context);
    final method = context.method;
    for (final target in config.targets) {
      if (target.contains('.')) {
        throw MapTargetDotNotationUnsupportedError(
          target: target,
          element: method,
        );
      }
    }

    final run = _Run(
      context: context,
      method: method,
      extraMappingMethodAnalyzer: extraMappingMethodAnalyzer,
    );

    return _bindings(
      run,
      targetType: method.returnType,
      params: method.formalParameters
          .where((param) => param.name != null)
          .map((param) => _Param(param.name!, param.type))
          .toList(growable: false),
      config: config,
      // Only a method taking the map alone can be called back by nested
      // values of its own type.
      visiting:
          _isSelfReferencing(method) ? {mapTypeKey(method.returnType)} : {},
    );
  }

  bool _isSelfReferencing(MethodElement method) {
    final parameters = method.formalParameters;

    return parameters.length == 1 && parameters.single.type.isMapLikeSource;
  }

  List<Binding> _bindings(
    _Run run, {
    required DartType targetType,
    required List<_Param> params,
    required _Config config,
    required Set<String> visiting,
  }) {
    final targetClass = targetType.element?.classElementOrNull;
    if (targetClass == null) {
      throw UnknownTargetClassError(
        mapperClass: run.context.mapperClass,
        method: run.method,
      );
    }
    _validateInstantiable(run, targetClass);

    final isBuilt = targetType.isBuiltValue;
    final substituted = targetType.substitutedGetterTypes;
    final bindings = <Binding>[];

    for (final target in _targets(targetClass, isBuilt)) {
      final type = substituted?[target.name] ?? target.type;
      final binding = _bind(
        run,
        targetClass: targetClass,
        target: target,
        type: type,
        params: params,
        config: config,
        visiting: visiting,
        isBuilt: isBuilt,
      );
      if (binding != null) {
        bindings.add(binding);
      }
    }

    return bindings;
  }

  void _validateInstantiable(_Run run, ClassElement targetClass) {
    if (targetClass.isSealed ||
        (targetClass.isAbstract && !targetClass.mainConstructor.isFactory)) {
      throw FromMapTargetNotInstantiableError(
        targetClass: targetClass,
        element: run.method,
      );
    }
  }

  List<_Target> _targets(ClassElement targetClass, bool isBuilt) {
    if (isBuilt) {
      return targetClass.getterElements
          .whereType<FieldElement>()
          .where(
              (field) => !field.isStatic && (field.getter?.isAbstract ?? false))
          .where((field) => field.name != null)
          .map((field) => _Target(field.name!, field.type, false))
          .toList(growable: false);
    }

    return targetClass.constructorParameters
        .where((parameter) => parameter.name != null)
        .map((p) => _Target(p.name!, p.type, p.isRequired))
        .toList(growable: false);
  }

  Binding? _bind(
    _Run run, {
    required ClassElement targetClass,
    required _Target target,
    required DartType type,
    required List<_Param> params,
    required _Config config,
    required Set<String> visiting,
    required bool isBuilt,
  }) {
    final name = target.name;
    final targetField = Field.from(
      name: name,
      type: type,
      required: target.required,
      nullable: type.isNullable,
    );
    final placeholder = Field.from(
      name: name,
      type: type,
      required: false,
      nullable: true,
    );

    if (config.ignored.contains(name)) {
      // Built values and optional parameters just omit the property.
      if (isBuilt || !(target.required && type.isNullable)) {
        return null;
      }

      return Binding(source: placeholder, target: targetField, ignored: true);
    }

    if (config.constants.containsKey(name)) {
      return Binding(
        source: placeholder,
        target: targetField,
        constant: config.constants[name],
      );
    }

    if (config.expressions.containsKey(name)) {
      return Binding(
        source: placeholder,
        target: targetField,
        expression: config.expressions[name],
      );
    }

    final sourcePath = config.sources[name];
    final callable = config.callables[name];

    // Multi-argument callable: `source: 'a,b'`.
    if (sourcePath != null && sourcePath.contains(',') && callable != null) {
      final resolved = sourcePath
          .split(',')
          .map((part) => _resolve(run, params, part.trim(), name))
          .toList(growable: false);

      return Binding(
        source: resolved.first.field,
        sources: resolved.map((r) => r.field).toList(growable: false),
        sourceAccessChains:
            resolved.map((r) => r.chain).toList(growable: false),
        target: targetField,
        callableMappingMethod: callable,
      );
    }

    final resolved = _resolve(run, params, sourcePath ?? name, name);
    final source = resolved.field;

    if (callable != null) {
      return Binding(
        source: source,
        target: targetField,
        forceNonNull: config.forceNonNull.contains(name),
        callableMappingMethod: callable,
        accessChain: resolved.chain,
        conditionExpression: config.conditionExpressions[name],
      );
    }

    MappingMethod? extra;
    if (source is MapEntryField) {
      extra = _extraFor(run, type, visiting);
      _validateAgainstValueType(run, source, targetField, extra);
    } else if (!config.ignored.contains(name)) {
      extra = run.extraMappingMethodAnalyzer.analyze(
        FieldsAnalyzerContext(
          mapperAnnotation: run.context.mapperAnnotation,
          mapperUsages: run.context.mapperUsages,
          internalMapperUsages: run.context.internalMapperUsages,
          mapperClass: run.context.mapperClass,
          importAliases: run.context.importAliases,
          source: source,
          target: targetField,
        ),
      );
    }

    final forceNonNull = config.forceNonNull.contains(name);
    final defaultValue = config.defaultValues[name];
    if (isBuilt &&
        source.nullable &&
        !targetField.nullable &&
        !forceNonNull &&
        defaultValue == null &&
        config.conditionExpressions[name] == null) {
      throw TargetFieldRequiresNonOptionalSourceFieldError(
        fieldName: name,
        targetClass: targetClass,
        mapperName: run.context.mapperClass.name!,
        methodName: run.method.name!,
      );
    }

    return Binding(
      source: source,
      target: targetField,
      forceNonNull: forceNonNull,
      extraMappingMethod: extra,
      defaultValue: defaultValue,
      accessChain: resolved.chain,
      conditionExpression: config.conditionExpressions[name],
    );
  }

  // --- Source resolution -----------------------------------------------------

  _Resolved _resolve(
    _Run run,
    List<_Param> params,
    String path,
    String targetName,
  ) {
    final segments = path.split('.');
    final maps = params.where((p) => p.isMap).toList(growable: false);
    final others = params.where((p) => !p.isMap).toList(growable: false);

    // Explicit qualification (multi-source): `param.rest`.
    if (params.length > 1 && segments.length > 1) {
      final qualified =
          params.where((p) => p.name == segments.first).firstOrNull;
      if (qualified != null) {
        final rest = segments.sublist(1);

        return qualified.isMap
            ? _mapSource(run, qualified, rest)
            : _classPath(run, qualified, rest);
      }
    }

    if (segments.length == 1) {
      final name = segments.single;

      final parameter = others.where((p) => p.name == name).firstOrNull;
      if (parameter != null) {
        return _Resolved(
          Field.from(
            name: parameter.name,
            type: parameter.type,
            nullable: parameter.type.isNullable,
          ),
        );
      }

      final owners = others
          .where((p) => _classOf(p)?.getFieldOrGetter(name) != null)
          .toList(growable: false);
      if (owners.length > 1) {
        throw AmbiguousSourceFieldError(
          fieldName: name,
          parameterNames: owners.map((p) => p.name).toList(growable: false),
          element: run.method,
        );
      }
      if (owners.length == 1) {
        final owner = owners.single;
        final type = owner.type.substitutedGetterTypes?[name] ??
            _classOf(owner)!.getFieldOrGetter(name)!.type;

        return _Resolved(
          Field.from(
            name: name,
            type: type,
            nullable: type.isNullable,
            instance: Instance(name: owner.name),
          ),
        );
      }
    } else {
      // Unqualified dot notation: a non-map class parameter owning the first
      // segment wins, otherwise the path walks nested maps.
      final owners = others
          .where((p) => _classOf(p)?.getFieldOrGetter(segments.first) != null)
          .toList(growable: false);
      if (owners.length > 1) {
        throw AmbiguousSourceFieldError(
          fieldName: segments.first,
          targetName: targetName,
          sourcePath: path,
          parameterNames: owners.map((p) => p.name).toList(growable: false),
          element: run.method,
        );
      }
      if (owners.length == 1) {
        return _classPath(run, owners.single, segments);
      }
    }

    return _mapSource(run, maps.first, segments);
  }

  _Resolved _mapSource(_Run run, _Param map, List<String> keys) {
    final valueType = keys.length == 1 ? map.valueType : null;

    return _Resolved(
      MapEntryField(
        name: keys.last,
        type: run.dynamicType,
        instance: Instance(name: map.name),
        keys: keys,
        valueType: valueType,
        nullable: valueType?.isNullable ?? false,
      ),
    );
  }

  _Resolved _classPath(_Run run, _Param param, List<String> segments) {
    var currentType = param.type;
    final chain = <(String, bool)>[];

    for (final segment in segments) {
      final classElement = currentType.element?.classElementOrNull;
      final field = classElement?.getFieldOrGetter(segment);
      if (classElement == null || field == null) {
        throw InvalidGenerationSourceError(
          "Property '$segment' not found on type "
          "'${currentType.getDisplayString()}' while resolving dot notation "
          "path '${param.name}.${segments.join('.')}'.\n"
          "Fix: Check the dot notation path for typos.",
          element: run.method,
        );
      }

      chain.add((segment, currentType.isNullable));
      currentType = currentType.substitutedGetterTypes?[segment] ?? field.type;
    }

    return _Resolved(
      Field.from(
        name: segments.last,
        type: currentType,
        nullable: currentType.isNullable,
        instance: Instance(name: param.name),
      ),
      chain,
    );
  }

  ClassElement? _classOf(_Param param) =>
      param.type.element?.classElementOrNull;

  // --- Nested / converter methods ---------------------------------------------

  /// The innermost element of collections: `List<Map<String, X>>` -> `X`.
  DartType _leaf(DartType type) {
    final generics = type.asGenerics;
    if (type.isIterable && generics != null && generics.isNotEmpty) {
      return _leaf(generics.first);
    }
    if (type.isMap && generics != null && generics.length > 1) {
      return _leaf(generics[1]);
    }

    return type;
  }

  MappingMethod? _extraFor(_Run run, DartType type, Set<String> visiting) {
    final leaf = _leaf(type);
    if (leaf is DynamicType || leaf.isDartCoreObject) {
      return null;
    }

    final declared = run.converters.find(leaf);
    if (declared != null) {
      return declared;
    }

    return needsGeneratedMapping(leaf) ? _generate(run, leaf, visiting) : null;
  }

  MappingMethod _generate(_Run run, DartType leaf, Set<String> visiting) {
    final nonNullLeaf = run.typeSystem.promoteToNonNull(leaf);
    final mapType = run.typeProvider.mapType(
      run.typeProvider.stringType,
      run.typeProvider.dynamicType,
    );
    final mapField = Field.from(name: 'map', type: mapType);
    final context = FieldsAnalyzerContext(
      mapperAnnotation: run.context.mapperAnnotation,
      mapperUsages: run.context.mapperUsages,
      internalMapperUsages: run.context.internalMapperUsages,
      mapperClass: run.context.mapperClass,
      importAliases: run.context.importAliases,
      source: mapField,
      target: Field.from(name: nonNullLeaf.displayString, type: nonNullLeaf),
    );

    final key = mapTypeKey(nonNullLeaf);
    final cached = run.generated[key];
    if (cached != null) {
      return cached;
    }

    // Recursive structures: the method is emitted once, by the outer level.
    final recursive = visiting.contains(key);
    final bindings = recursive
        ? <Binding>[]
        : _bindings(
            run,
            targetType: nonNullLeaf,
            params: [_Param('map', mapType)],
            config: _Config.empty,
            visiting: {...visiting, key},
          );

    final method = GeneratedPrivateMappingMethod(
      context: context,
      returnType: nonNullLeaf,
      parameters: [MappingParameter(field: mapField, isNullable: false)],
      bindings: bindings,
      behavior: MappingBehavior.fromMap,
    );

    // A recursive reference is only a placeholder of the method being built.
    if (!recursive) {
      run.generated[key] = method;
    }

    return method;
  }

  // --- Typed map validation ----------------------------------------------------

  void _validateAgainstValueType(
    _Run run,
    MapEntryField source,
    Field target,
    MappingMethod? extra,
  ) {
    final valueType = source.valueType;
    if (valueType == null || source.keys.length != 1) {
      return;
    }

    if (!_compatible(run, valueType, target.type, extra)) {
      throw IncompatibleMapValueTypeError(
        field: target.name,
        fieldType: target.type.getDisplayString(),
        valueType: valueType.getDisplayString(),
        element: run.method,
      );
    }
  }

  /// The element of an iterable, or the value of a map, when typed.
  DartType? _elementOf(DartType type) {
    final generics = type.asGenerics;
    if (generics == null) {
      return null;
    }
    if (type.isIterable && generics.length == 1) {
      return generics.first;
    }
    if (type.isMap && generics.length == 2) {
      return generics[1];
    }

    return null;
  }

  bool _compatible(
    _Run run,
    DartType value,
    DartType target,
    MappingMethod? extra,
  ) {
    final system = run.typeSystem;
    final v = system.promoteToNonNull(value);
    final t = system.promoteToNonNull(target);

    // Collections of the same kind (iterable to iterable, map to map) are
    // compatible when their keys and their elements (or map values) are.
    final valueElement = _elementOf(v);
    final targetElement = _elementOf(t);
    if (valueElement != null &&
        targetElement != null &&
        v.isIterable == t.isIterable) {
      if (t.isMap && !_compatibleKey(run, v, t)) {
        return false;
      }

      return _compatible(run, valueElement, targetElement, extra);
    }

    final parameter = extra?.firstParameterType;
    if (extra != null && parameter != null) {
      if (parameter.isMapLikeSource) {
        return v.isMapLikeSource || v.isDartCoreObject;
      }
      final p = system.promoteToNonNull(parameter);

      return system.isAssignableTo(v, p) || system.isAssignableTo(p, v);
    }

    return system.isAssignableTo(v, t) ||
        system.isAssignableTo(t, v) ||
        (t.isDartCoreDouble && (v.isDartCoreInt || v.isDartCoreNum)) ||
        (t.isEnum && v.isDartCoreString) ||
        (t.isIterable && v.isIterable) ||
        (t.isMap && v.isMapLikeSource) ||
        (needsGeneratedMapping(t) && v.isMapLikeSource);
  }

  /// Whether the keys of the typed map [value] can be read as the keys of the
  /// map [target]: assignable either way, or a `String` read as an enum.
  bool _compatibleKey(_Run run, DartType value, DartType target) {
    final valueKey = value.asGenerics?.firstOrNull;
    final targetKey = target.asGenerics?.firstOrNull;
    if (valueKey == null || targetKey == null) {
      return true;
    }

    final system = run.typeSystem;
    final v = system.promoteToNonNull(valueKey);
    final t = system.promoteToNonNull(targetKey);

    return system.isAssignableTo(v, t) ||
        system.isAssignableTo(t, v) ||
        (t.isEnum && v.isDartCoreString);
  }
}

class _Target {
  final String name;
  final DartType type;
  final bool required;

  const _Target(this.name, this.type, this.required);
}

/// A source parameter of the mapping method.
class _Param {
  final String name;
  final DartType type;

  const _Param(this.name, this.type);

  bool get isMap => type.isMapLikeSource;

  /// The value type of a typed map, `null` for untyped (raw / `dynamic` /
  /// `Object`) values.
  DartType? get valueType {
    final generics = type.asGenerics;
    if (!isMap || generics == null || generics.length < 2) {
      return null;
    }

    final value = generics[1];

    return value is DynamicType || value.isDartCoreObject ? null : value;
  }
}

class _Resolved {
  final Field field;
  final List<(String, bool)>? chain;

  const _Resolved(this.field, [this.chain]);
}

class _Run {
  final BindingsAnalyzerContext context;
  final MethodElement method;
  final Analyzer<MappingMethod?> extraMappingMethodAnalyzer;

  _Run({
    required this.context,
    required this.method,
    required this.extraMappingMethodAnalyzer,
  });

  /// The nested methods generated so far, by [mapTypeKey].
  final Map<String, MappingMethod> generated = {};

  late final MapConverterLookup converters = MapConverterLookup(
    context: context,
    element: method,
    direction: MapConverterDirection.fromMap,
  );

  LibraryElement get library => context.mapperClass.library;

  TypeProvider get typeProvider => library.typeProvider;

  TypeSystem get typeSystem => library.typeSystem;

  DartType get dynamicType => typeProvider.dynamicType;
}

/// The `@Mapping` configuration of a method, by target name.
class _Config {
  final Map<String, String> sources;
  final Set<String> ignored;
  final Set<String> forceNonNull;
  final Map<String, CallableMappingMethod> callables;
  final Map<String, String> defaultValues;
  final Map<String, String> constants;
  final Map<String, String> expressions;
  final Map<String, String> conditionExpressions;

  const _Config({
    this.sources = const {},
    this.ignored = const {},
    this.forceNonNull = const {},
    this.callables = const {},
    this.defaultValues = const {},
    this.constants = const {},
    this.expressions = const {},
    this.conditionExpressions = const {},
  });

  static const empty = _Config();

  factory _Config.from(BindingsAnalyzerContext context) => _Config(
        sources: context.renamingMapReversed,
        ignored: context.ignoredTargets,
        forceNonNull: context.forceNonNullTargets,
        callables: context.callableMap,
        defaultValues: context.defaultValueMap,
        constants: context.constantMap,
        expressions: context.expressionMap,
        conditionExpressions: context.conditionExpressionMap,
      );

  Set<String> get targets => {
        ...sources.keys,
        ...ignored,
        ...forceNonNull,
        ...callables.keys,
        ...defaultValues.keys,
        ...constants.keys,
        ...expressions.keys,
        ...conditionExpressions.keys,
      };
}
