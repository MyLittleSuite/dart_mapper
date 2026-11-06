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
import 'package:dart_mapper_generator/src/analyzers/contexts/analyzer_context.dart';
import 'package:dart_mapper_generator/src/analyzers/contexts/bindings_analyzer_context.dart';
import 'package:dart_mapper_generator/src/analyzers/contexts/fields_analyzer_context.dart';
import 'package:dart_mapper_generator/src/exceptions/ambiguous_map_converter_error.dart';
import 'package:dart_mapper_generator/src/exceptions/ambiguous_source_field_error.dart';
import 'package:dart_mapper_generator/src/exceptions/incompatible_map_value_error.dart';
import 'package:dart_mapper_generator/src/exceptions/invalid_map_source_parameter_error.dart';
import 'package:dart_mapper_generator/src/extensions/class_element.dart';
import 'package:dart_mapper_generator/src/extensions/dart_type.dart';
import 'package:dart_mapper_generator/src/extensions/element.dart';
import 'package:dart_mapper_generator/src/extensions/mapping_method.dart';
import 'package:dart_mapper_generator/src/misc/map_key_tree.dart';
import 'package:dart_mapper_generator/src/models/binding.dart';
import 'package:dart_mapper_generator/src/models/field/field.dart';
import 'package:dart_mapper_generator/src/models/instance.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/mapping_parameter.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/bases/mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/callable_mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/external_mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/generated_private_mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/internal_mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper_usage.dart';
import 'package:dart_mapper_generator/src/models/mapping_behavior.dart';
import 'package:source_gen/source_gen.dart';

/// Produces the bindings of a class to Map mapping method
/// (`MappingBehavior.toMap`), where every map key plays the role of a
/// target field.
///
/// The keys are the constructor parameters of the source class (the abstract
/// getters for built_value classes). `@Mapping` is honoured as follows:
/// `target` is the key (dot notation builds nested maps), `source` is the
/// property to read (dot notation walks nested classes).
class ToMapBindingsAnalyzer extends Analyzer<List<Binding>> {
  const ToMapBindingsAnalyzer();

  @override
  List<Binding> analyze(AnalyzerContext context) {
    if (context is! BindingsAnalyzerContext) {
      throw ArgumentError('context must be a BindingsAnalyzerContext');
    }

    context.validateMappingCombinations();
    context.validateCommaSeparatedSource();

    final method = context.method;
    final sources = <_Source>[];
    for (final parameter in method.formalParameters) {
      if (parameter.name == null) continue;
      final type = parameter.type;
      if (type.element?.classElementOrNull == null ||
          type.element?.library?.isInSdk == true ||
          type.isMap ||
          type.isIterable ||
          type.isEnum) {
        throw InvalidMapSourceParameterError(
          method: method,
          parameter: parameter,
        );
      }
      sources.add(_Source(parameter.name!, type));
    }

    final returnType = method.returnType;
    final valueType =
        returnType is InterfaceType && returnType.typeArguments.length == 2
            ? returnType.typeArguments[1]
            : context.mapperClass.library.typeProvider.dynamicType;

    final session = _Session(context, method);

    return _ToMapBuilder(
      session: session,
      sources: sources,
      valueType: valueType,
      config: _Config.from(context),
    ).build();
  }
}

class _Source {
  final String name;
  final DartType type;

  const _Source(this.name, this.type);
}

class _Property {
  final String name;
  final DartType type;

  const _Property(this.name, this.type);
}

class _Config {
  final Map<String, List<String>> renamingMap;
  final Map<String, String> renamingMapReversed;
  final Set<String> ignored;
  final Set<String> forceNonNull;
  final Map<String, CallableMappingMethod> callables;
  final Map<String, String> defaults;
  final Map<String, String> constants;
  final Map<String, String> expressions;
  final Map<String, String> conditions;

  const _Config({
    this.renamingMap = const {},
    this.renamingMapReversed = const {},
    this.ignored = const {},
    this.forceNonNull = const {},
    this.callables = const {},
    this.defaults = const {},
    this.constants = const {},
    this.expressions = const {},
    this.conditions = const {},
  });

  factory _Config.from(BindingsAnalyzerContext context) => _Config(
        renamingMap: context.renamingMap,
        renamingMapReversed: context.renamingMapReversed,
        ignored: context.ignoredTargets,
        forceNonNull: context.forceNonNullTargets,
        callables: context.callableMap,
        defaults: context.defaultValueMap,
        constants: context.constantMap,
        expressions: context.expressionMap,
        conditions: context.conditionExpressionMap,
      );
}

class _Pending {
  final int order;
  final int sequence;
  final Binding binding;

  const _Pending(this.order, this.sequence, this.binding);
}

class _Resolved {
  final Field field;
  final List<(String, bool)>? chain;
  final int order;

  const _Resolved(this.field, this.chain, this.order);
}

/// State shared between the builders of a method and of the private methods
/// generated for its nested classes.
class _Session {
  final AnalyzerContext context;
  final Element element;
  final Map<String, GeneratedPrivateMappingMethod> generated = {};
  final Set<String> inProgress = {};

  _Session(this.context, this.element);

  TypeProvider get typeProvider => context.mapperClass.library.typeProvider;

  TypeSystem get typeSystem => context.mapperClass.library.typeSystem;

  DartType get dynamicType => typeProvider.dynamicType;

  DartType get stringType => typeProvider.stringType;

  DartType get stringKeyedDynamicMapType =>
      typeProvider.mapType(stringType, dynamicType);
}

class _ToMapBuilder {
  static const _unorderedOffset = 1 << 20;

  final _Session session;
  final List<_Source> sources;
  final DartType valueType;
  final _Config config;

  _ToMapBuilder({
    required this.session,
    required this.sources,
    required this.valueType,
    this.config = const _Config(),
  });

  TypeSystem get _typeSystem => session.typeSystem;

  bool get _isFree =>
      valueType is DynamicType || valueType.isDartCoreObject == true;

  DartType _nullable(DartType type) => _typeSystem.leastUpperBound(
        type,
        session.typeProvider.nullType,
      );

  bool get _acceptsNull => _typeSystem.isNullable(valueType);

  late final Map<String, List<_Property>> _properties = {
    for (final source in sources) source.name: _propertiesOf(source.type),
  };

  List<Binding> build() {
    final pending = <_Pending>[];
    final bound = <String>{};
    var sequence = 0;

    void add(int order, Binding binding) {
      pending.add(_Pending(order, sequence++, binding));
      bound.add(binding.target.name);
    }

    // Step 0: multi-argument callables ("a.x, b.y").
    for (final entry in config.renamingMapReversed.entries) {
      final key = entry.key;
      if (!entry.value.contains(',')) continue;
      if (bound.contains(key) || config.ignored.contains(key)) continue;
      final callable = config.callables[key];
      if (callable == null) continue;

      final parts = entry.value.split(',').map((p) => p.trim()).toList();
      final resolved = parts.map(_resolve).toList(growable: false);
      _checkCallable(key, callable);

      add(
        _unorderedOffset,
        Binding(
          source: resolved.first.field,
          sources: resolved.map((r) => r.field).toList(growable: false),
          sourceAccessChains:
              resolved.map((r) => r.chain).toList(growable: false),
          target: _target(
            key,
            callable.returnType ?? session.dynamicType,
          ),
          callableMappingMethod: callable,
        ),
      );
    }

    // Step 1: explicit sources (renames, dot notation, computed getters).
    for (final entry in config.renamingMapReversed.entries) {
      final key = entry.key;
      if (entry.value.contains(',')) continue;
      if (bound.contains(key) || config.ignored.contains(key)) continue;

      final resolved = _resolve(entry.value);
      add(resolved.order, _bind(key, resolved.field, resolved.chain));
    }

    // Step 2: constants (no source).
    for (final entry in config.constants.entries) {
      final key = entry.key;
      if (bound.contains(key) || config.ignored.contains(key)) continue;

      add(
        _unorderedOffset,
        Binding(
          source: _placeholder(key),
          target: _target(key, _constantType(entry.value)),
          constant: entry.value,
        ),
      );
    }

    // Step 2.5: expressions (no source).
    for (final entry in config.expressions.entries) {
      final key = entry.key;
      if (bound.contains(key) || config.ignored.contains(key)) continue;

      add(
        _unorderedOffset,
        Binding(
          source: _placeholder(key),
          target: _target(key, session.dynamicType),
          expression: entry.value,
        ),
      );
    }

    // Step 3: every remaining property becomes a key.
    final propertyToSources = <String, List<String>>{};
    for (final source in sources) {
      for (final property in _properties[source.name]!) {
        propertyToSources.putIfAbsent(property.name, () => []).add(source.name);
      }
    }

    for (var s = 0; s < sources.length; s++) {
      final source = sources[s];
      final properties = _properties[source.name]!;
      for (var p = 0; p < properties.length; p++) {
        final property = properties[p];
        final keys =
            config.renamingMap[property.name] ?? <String>[property.name];

        for (final key in keys) {
          if (bound.contains(key)) continue;
          if (config.ignored.contains(key)) {
            bound.add(key);
            continue;
          }

          final owners = propertyToSources[property.name]!;
          if (sources.length > 1 && owners.length > 1) {
            final allQualified = owners.every(
              (owner) =>
                  config.renamingMap.containsKey('$owner.${property.name}'),
            );
            if (allQualified) continue;

            throw AmbiguousSourceFieldError(
              fieldName: property.name,
              parameterNames: owners,
              element: session.element,
            );
          }

          add(
            s * 1000 + p,
            _bind(
              key,
              Field.from(
                name: property.name,
                type: property.type,
                nullable: property.type.isNullable,
                instance: Instance(name: source.name),
              ),
              null,
            ),
          );
        }
      }
    }

    pending.sort((a, b) {
      final byOrder = a.order.compareTo(b.order);
      return byOrder != 0 ? byOrder : a.sequence.compareTo(b.sequence);
    });

    // Fails early when nested keys conflict.
    buildMapKeyTree(
      pending.map((p) => (p.binding.target.name, p.binding)),
      element: session.element,
    );

    return pending.map((p) => p.binding).toList(growable: false);
  }

  // --------------------------------------------------------------------------
  // Properties and source resolution
  // --------------------------------------------------------------------------

  List<_Property> _propertiesOf(DartType type) {
    final element = type.element?.classElementOrNull;
    if (element == null) return const [];

    final substituted = type.substitutedGetterTypes;
    final isBuilt = element.allSupertypes.any((t) => t.isLibraryBuilt);

    if (isBuilt) {
      return element.fields
          .where(
            (field) =>
                !field.isStatic &&
                field.name != null &&
                field.getter?.isAbstract == true,
          )
          .map(
            (field) => _Property(
              field.name!,
              substituted?[field.name!] ?? field.type,
            ),
          )
          .toList(growable: false);
    }

    return element.constructorParameters
        .where((parameter) => parameter.name != null)
        .map(
          (parameter) => _Property(
            parameter.name!,
            substituted?[parameter.name!] ?? parameter.type,
          ),
        )
        .toList(growable: false);
  }

  _Resolved _resolve(String expression) {
    final segments = expression.split('.');
    _Source source;
    List<String> traversal;

    if (sources.length > 1) {
      if (segments.length > 1) {
        final qualified =
            sources.where((s) => s.name == segments.first).firstOrNull;
        if (qualified == null) {
          throw InvalidGenerationSourceError(
            "Source parameter '${segments.first}' not found in method "
            "'${session.element.name}'.\n"
            "Available parameters: ${sources.map((s) => s.name).join(', ')}.\n"
            "Fix: Check dot notation source prefix matches a method parameter name.",
            element: session.element,
          );
        }
        source = qualified;
        traversal = segments.sublist(1);
      } else {
        final owners = sources
            .where(
              (s) =>
                  s.type.element?.classElementOrNull
                      ?.getFieldOrGetter(segments.first) !=
                  null,
            )
            .toList(growable: false);
        if (owners.isEmpty) {
          throw InvalidGenerationSourceError(
            "Property '${segments.first}' not found in any source parameter "
            "of method '${session.element.name}'.\n"
            "Fix: Check the @Mapping source for typos.",
            element: session.element,
          );
        }
        if (owners.length > 1) {
          throw AmbiguousSourceFieldError(
            fieldName: segments.first,
            parameterNames: owners.map((s) => s.name).toList(growable: false),
            element: session.element,
          );
        }
        source = owners.single;
        traversal = segments;
      }
    } else {
      source = sources.single;
      traversal = segments;
    }

    var current = source.type;
    final chain = <(String, bool)>[];
    for (final segment in traversal) {
      final classElement = current.element?.classElementOrNull;
      if (classElement == null) {
        throw InvalidGenerationSourceError(
          "Cannot traverse '$segment' on type '${current.getDisplayString()}' "
          "— type is not a class.\n"
          "Check that each segment in the dot notation path refers to a valid class property.",
          element: session.element,
        );
      }

      final field = classElement.getFieldOrGetter(segment);
      if (field == null) {
        throw InvalidGenerationSourceError(
          "Property '$segment' not found on type '${current.getDisplayString()}' "
          "while resolving dot notation path.\n"
          "Available properties: ${classElement.getterElements.map((e) => e.name).join(', ')}.\n"
          "Fix: Check the dot notation path for typos.",
          element: session.element,
        );
      }

      chain.add((segment, current.isNullable));
      current = current.substitutedGetterTypes?[segment] ?? field.type;
    }

    final properties = _properties[source.name] ?? const [];
    final index = properties.indexWhere((p) => p.name == traversal.first);
    final sourceIndex = sources.indexOf(source);
    final order = index < 0 ? _unorderedOffset : sourceIndex * 1000 + index;

    return _Resolved(
      Field.from(
        name: traversal.last,
        type: current,
        nullable: current.isNullable,
        instance: Instance(name: source.name),
      ),
      traversal.length > 1 ? chain : null,
      order,
    );
  }

  // --------------------------------------------------------------------------
  // Binding creation
  // --------------------------------------------------------------------------

  Field _placeholder(String key) => Field.from(
        name: key,
        type: session.dynamicType,
        nullable: true,
      );

  Field _target(String key, DartType wire) => Field.from(
        name: key,
        type: wire,
        nullable: _acceptsNull,
      );

  /// The type used to decide how a constant is rendered: a string literal
  /// or the verbatim Dart source.
  DartType _constantType(String constant) {
    if (!_isFree) return valueType;

    final trimmed = constant.trim();
    final isCode = trimmed == 'true' ||
        trimmed == 'false' ||
        trimmed == 'null' ||
        num.tryParse(trimmed) != null ||
        trimmed.startsWith("'") ||
        trimmed.startsWith('"') ||
        trimmed.startsWith('[') ||
        trimmed.startsWith('{') ||
        trimmed.startsWith('<') ||
        trimmed.startsWith('const ');

    return isCode ? session.typeProvider.intType : session.stringType;
  }

  void _checkCallable(String key, CallableMappingMethod callable) {
    final returnType = callable.returnType;
    if (returnType != null &&
        !_typeSystem.isAssignableTo(returnType, valueType)) {
      throw _incompatible(key, returnType);
    }
  }

  IncompatibleMapValueError _incompatible(String key, DartType fieldType) =>
      IncompatibleMapValueError(
        key: key,
        fieldType: fieldType.getDisplayString(),
        valueType: valueType.getDisplayString(),
        mapType: 'Map<String, ${valueType.getDisplayString()}>',
        element: session.element,
      );

  Binding _bind(String key, Field source, List<(String, bool)>? chain) {
    final callable = config.callables[key];
    final forceNonNull = config.forceNonNull.contains(key);
    final defaultValue = config.defaults[key];
    final condition = config.conditions[key];

    if (callable != null) {
      _checkCallable(key, callable);

      return Binding(
        source: source,
        target: _target(key, callable.returnType ?? session.dynamicType),
        forceNonNull: forceNonNull,
        callableMappingMethod: callable,
        accessChain: chain,
      );
    }

    if (condition != null && !_acceptsNull && defaultValue == null) {
      throw InvalidGenerationSourceError(
        "conditionExpression on non-nullable map value '$key': "
        "requires a defaultValue or a nullable map value type.\n"
        "Fix: Add defaultValue: '...' to the @Mapping annotation, or make the map value type nullable.",
        element: session.element,
      );
    }

    var type = source.type;
    if (forceNonNull || defaultValue != null) {
      type = _typeSystem.promoteToNonNull(type);
    } else if (chain?.any((e) => e.$2) == true) {
      type = _nullable(type);
    }

    MappingMethod? extra = _findConverter(type);
    if (extra == null) {
      final leaf = _leafOf(type);
      if (leaf != type) {
        extra = _findConverter(leaf);
      }
    }

    final passThrough = extra == null &&
        !_isFree &&
        _typeSystem.isAssignableTo(type, valueType);

    if (extra == null && !passThrough) {
      final leaf = _leafOf(type);
      if (_isCustomClass(leaf)) {
        extra = _privateMethodFor(leaf);
      }
    }

    final wire = passThrough ? type : _wire(type, extra);
    if (!_typeSystem.isAssignableTo(wire, valueType)) {
      throw _incompatible(key, source.type);
    }

    return Binding(
      source: source,
      target: _target(key, wire),
      forceNonNull: forceNonNull,
      extraMappingMethod: extra,
      defaultValue: defaultValue,
      conditionExpression: condition,
      accessChain: chain,
    );
  }

  // --------------------------------------------------------------------------
  // Type helpers
  // --------------------------------------------------------------------------

  /// Unwraps iterables and maps down to the type holding the actual item.
  DartType _leafOf(DartType type) {
    final plain = _typeSystem.promoteToNonNull(type);
    if (plain.isIterable) {
      final item = plain.asGenerics?.firstOrNull;
      return item == null ? plain : _leafOf(item);
    }
    if (plain.isMap) {
      final value = plain.asGenerics?.elementAtOrNull(1);
      return value == null ? plain : _leafOf(value);
    }

    return plain;
  }

  /// Whether [type] is a user class that has to be converted to a nested map.
  bool _isCustomClass(DartType type) {
    final plain = _typeSystem.promoteToNonNull(type);
    final element = plain.element;

    return plain is InterfaceType &&
        element is ClassElement &&
        element.library.isInSdk == false &&
        !plain.isEnum &&
        !plain.isIterable &&
        !plain.isMap &&
        !plain.isPrimitive &&
        !plain.isLibraryBuilt;
  }

  bool _isWholeMatch(MappingMethod method, DartType type) {
    final parameter = method.firstParameterType;
    return parameter != null &&
        parameter.same(
          type,
          aliases: session.context.importAliases,
          useNullability: false,
        );
  }

  /// The type stored in the map once [type] is converted using [extra].
  DartType _wire(DartType type, MappingMethod? extra) {
    final plain = _typeSystem.promoteToNonNull(type);
    final nullable = type.isNullable;

    DartType result;
    if (extra != null && _isWholeMatch(extra, plain)) {
      result = extra.returnType ?? session.dynamicType;
      if (nullable) result = _nullable(result);
      return result;
    }

    if (plain.isEnum) {
      result = session.stringType;
    } else if (plain.isIterable) {
      final item = plain.asGenerics?.firstOrNull;
      if (item == null) {
        result = plain;
      } else {
        final wireItem = _wire(item, extra);
        final changed = wireItem != item;
        if (changed) {
          result = session.typeProvider.listType(wireItem);
        } else if (plain.isBuiltList) {
          result = session.typeProvider.listType(item);
        } else if (plain.isBuiltSet) {
          result = session.typeProvider.setType(item);
        } else {
          result = plain;
        }
      }
    } else if (plain.isMap) {
      final generics = plain.asGenerics;
      if (generics == null || generics.length != 2) {
        result = plain;
      } else {
        final wireKey = generics[0].isEnum ? session.stringType : generics[0];
        final wireValue = _wire(generics[1], extra);
        final changed = wireKey != generics[0] || wireValue != generics[1];
        result = changed || plain.isBuiltMap
            ? session.typeProvider.mapType(wireKey, wireValue)
            : plain;
      }
    } else if (extra != null && _isCustomClass(plain)) {
      result = extra.returnType ?? session.stringKeyedDynamicMapType;
    } else {
      result = plain;
    }

    return nullable ? _nullable(result) : result;
  }

  // --------------------------------------------------------------------------
  // Converters (declared methods, `uses`)
  // --------------------------------------------------------------------------

  static bool _isPlainPrimitive(DartType type) =>
      type.isDartCoreBool ||
      type.isDartCoreInt ||
      type.isDartCoreDouble ||
      type.isDartCoreNum ||
      type.isDartCoreString;

  bool _isWireType(DartType type) {
    if (type is DynamicType || type.isDartCoreObject) return true;
    if (_isPlainPrimitive(type)) return true;
    if (type.isDartCoreMap) return true;
    if (type.isDartCoreList || type.isDartCoreSet || type.isDartCoreIterable) {
      final item = (type as InterfaceType).typeArguments.firstOrNull;
      return item == null || _isWireType(item);
    }

    return false;
  }

  /// Looks for a method converting [type] into a map value: first among the
  /// methods declared in the mapper, then in the `uses` mappers.
  MappingMethod? _findConverter(DartType type) {
    final plain = _typeSystem.promoteToNonNull(type);
    if (_isPlainPrimitive(plain) || plain.isMap || plain.isIterable) {
      return null;
    }

    final semantic = _isCustomClass(plain) || plain.isEnum;

    bool accepts(MapperUsage usage) {
      if (usage.parameters.length != 1) return false;
      final parameter = usage.parameters.single.field.type;
      if (!parameter.same(
        plain,
        aliases: session.context.importAliases,
        useNullability: false,
      )) {
        return false;
      }
      final returnType = usage.returnType;
      if (returnType.same(
        plain,
        aliases: session.context.importAliases,
        useNullability: false,
      )) {
        return false;
      }
      if (_isFree) {
        return !semantic || _isWireType(returnType);
      }

      return _typeSystem.isAssignableTo(returnType, valueType);
    }

    for (final internally in const [true, false]) {
      final usages = (internally
              ? session.context.internalMapperUsages
              : session.context.mapperUsages)
          .where(accepts)
          .toList(growable: false);

      if (usages.length > 1) {
        throw AmbiguousMapConverterError(
          fieldType: plain.getDisplayString(),
          candidates: usages
              .map((u) => '${u.mapperName}.${u.functionName}')
              .toList(growable: false),
          element: session.element,
        );
      }
      if (usages.length == 1) {
        return internally
            ? InternalMappingMethod(mapperUsage: usages.single)
            : ExternalMappingMethod(mapperUsage: usages.single);
      }
    }

    return null;
  }

  // --------------------------------------------------------------------------
  // Generated private methods for nested classes
  // --------------------------------------------------------------------------

  MappingMethod _privateMethodFor(DartType type) {
    final plain = _typeSystem.promoteToNonNull(type);
    final key = plain.getDisplayString();

    final cached = session.generated[key];
    if (cached != null) return cached;

    if (!session.inProgress.add(key)) {
      throw InvalidGenerationSourceError(
        "Type '$key' references itself and cannot be converted to a nested "
        "map automatically.\n"
        "Fix: Declare a method 'Map<String, dynamic> toMap($key value)' in "
        "the mapper (or in a mapper listed in 'uses') to handle it.",
        element: session.element,
      );
    }

    try {
      final parameter = Field.from(name: plain.parameterName, type: plain);
      final bindings = _ToMapBuilder(
        session: session,
        sources: [_Source(parameter.name, plain)],
        valueType: session.dynamicType,
      ).build();

      final method = GeneratedPrivateMappingMethod(
        context: FieldsAnalyzerContext(
          mapperAnnotation: session.context.mapperAnnotation,
          mapperUsages: session.context.mapperUsages,
          internalMapperUsages: session.context.internalMapperUsages,
          mapperClass: session.context.mapperClass,
          importAliases: session.context.importAliases,
          source: parameter,
          target: Field.from(
            name: 'map',
            type: session.stringKeyedDynamicMapType,
          ),
        ),
        returnType: session.stringKeyedDynamicMapType,
        parameters: [MappingParameter(field: parameter, isNullable: false)],
        bindings: bindings,
        behavior: MappingBehavior.toMap,
      );
      session.generated[key] = method;

      return method;
    } finally {
      session.inProgress.remove(key);
    }
  }
}
