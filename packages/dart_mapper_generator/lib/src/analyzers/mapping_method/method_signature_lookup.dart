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
import 'package:analyzer/dart/element/type_system.dart';
import 'package:dart_mapper_generator/src/analyzers/contexts/method_analyzer_context.dart';
import 'package:dart_mapper_generator/src/exceptions/ambiguous_mapping_method_error.dart';
import 'package:dart_mapper_generator/src/exceptions/no_matching_mapping_method_error.dart';
import 'package:dart_mapper_generator/src/exceptions/unknown_qualified_method_error.dart';
import 'package:dart_mapper_generator/src/mixins/aliases_mixin.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/bases/mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/external_mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/internal_mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper_usage.dart';

/// One resolved source handed to [MethodSignatureLookup.find].
class SourceArgument {
  /// The type of the source, nullability included.
  final DartType type;

  /// Whether the source may be null although [type] is not, because a link
  /// of its dot-notation path is nullable (`a?.b`).
  final bool nullableChain;

  /// Whether the type is not known statically (the value of an untyped Map):
  /// the argument matches any parameter and is cast by the caller.
  final bool untyped;

  /// How the source is written in the error messages (`from.orderField`).
  final String description;

  const SourceArgument({
    required this.type,
    required this.description,
    this.nullableChain = false,
    this.untyped = false,
  });
}

/// Finds the mapper method that combines the sources of a comma-separated
/// `source` into a target (or that is selected by `qualifiedBy`).
///
/// The candidates are the methods of the mappers listed in `uses`, then the
/// methods of the mapper itself; the method being generated is never one of
/// them. A candidate matches when:
///  - it has as many parameters as there are arguments;
///  - each argument is assignable to the parameter at the same position, with
///    strict nullability (a nullable argument needs a nullable parameter);
///  - its return type is assignable to the target type (any return type when
///    the target type is null or `dynamic`).
///
/// ```dart
/// final method = MethodSignatureLookup(context).find(
///   target: 'ordering',
///   arguments: [SourceArgument(type: stringNullable, description: 'from.a')],
///   targetType: orderingType,
///   qualifiedBy: context.qualifiedByMap['ordering'],
/// );
/// // ExternalMappingMethod (orderingMapper.from) or InternalMappingMethod
/// ```
///
/// Mapper methods that are not matched by uses are searched only when no
/// `uses` candidate matches, so a `uses` method wins over an own one.
class MethodSignatureLookup with AliasesMixin {
  final MethodAnalyzerContext context;

  MethodSignatureLookup(this.context);

  @override
  Map<Uri, String> get importAliases => context.importAliases;

  /// The [ExternalMappingMethod] or [InternalMappingMethod] to call for the
  /// [arguments] of the mapping of [target].
  ///
  /// Throws [UnknownQualifiedMethodError] when [qualifiedBy] names no method,
  /// [NoMatchingMappingMethodError] when no candidate (or the qualified one)
  /// fits the signature and [AmbiguousMappingMethodError] when several do.
  MappingMethod find({
    required String target,
    required List<SourceArgument> arguments,
    DartType? targetType,
    String? qualifiedBy,
  }) {
    final element = context.method;
    final typeSystem = context.mapperClass.library.typeSystem;
    final effectiveTarget =
        targetType == null || targetType is DynamicType ? null : targetType;

    final external = _candidates(context.mapperUsages, external: true);
    final internal = _candidates(context.internalMapperUsages, external: false);
    var candidates = [...external, ...internal];

    if (qualifiedBy != null) {
      final qualified = candidates
          .where((candidate) => _isQualified(candidate, qualifiedBy))
          .toList(growable: false);
      if (qualified.isEmpty) {
        throw UnknownQualifiedMethodError(
          target: target,
          qualifiedBy: qualifiedBy,
          available: {
            for (final candidate in candidates) _label(candidate),
          }.toList(growable: false),
          element: element,
        );
      }
      candidates = qualified;
    }

    final rejected = <String, String>{};
    final matches = <_Candidate>[];
    for (final candidate in candidates) {
      final reason = _mismatch(
        typeSystem,
        candidate.usage,
        arguments,
        effectiveTarget,
      );
      if (reason == null) {
        matches.add(candidate);
      } else {
        rejected[_signature(candidate)] = reason;
      }
    }

    if (matches.isEmpty) {
      throw NoMatchingMappingMethodError(
        target: target,
        arguments: [
          for (final argument in arguments)
            '${_typeName(argument.type, argument.nullableChain)} '
                '${argument.description}',
        ],
        targetType: effectiveTarget == null ? null : _typeName(effectiveTarget),
        rejected: rejected,
        element: element,
      );
    }

    // `uses` mappers come first: an own method is a candidate only when no
    // used mapper matches.
    final chosen = matches.any((match) => match.external)
        ? matches.where((match) => match.external).toList(growable: false)
        : matches;
    if (chosen.length > 1) {
      throw AmbiguousMappingMethodError(
        target: target,
        candidates: chosen.map(_signature).toList(growable: false),
        element: element,
      );
    }

    final usage = chosen.single.usage;
    return chosen.single.external
        ? ExternalMappingMethod(mapperUsage: usage)
        : InternalMappingMethod(mapperUsage: usage);
  }

  Iterable<_Candidate> _candidates(
    Set<MapperUsage> usages, {
    required bool external,
  }) =>
      usages
          .where(
            (usage) =>
                external ||
                // The method being generated is never a candidate.
                usage.functionName != context.method.name,
          )
          .map((usage) => _Candidate(usage, external: external));

  bool _isQualified(_Candidate candidate, String qualifiedBy) {
    final dot = qualifiedBy.indexOf('.');
    final mapper = dot < 0 ? null : qualifiedBy.substring(0, dot).trim();
    final method =
        (dot < 0 ? qualifiedBy : qualifiedBy.substring(dot + 1)).trim();

    return candidate.usage.functionName == method &&
        (mapper == null || candidate.mapperClassName == mapper);
  }

  /// Why [usage] does not accept [arguments] / return [target], or null.
  String? _mismatch(
    TypeSystem typeSystem,
    MapperUsage usage,
    List<SourceArgument> arguments,
    DartType? target,
  ) {
    final parameters = usage.parameters;
    if (parameters.length != arguments.length) {
      return 'takes ${parameters.length} parameter(s), '
          '${arguments.length} source(s) given';
    }

    for (var i = 0; i < arguments.length; i++) {
      final argument = arguments[i];
      final parameterType = parameters[i].field.type;
      if (argument.untyped) {
        continue;
      }

      final type = argument.nullableChain
          ? typeSystem.leastUpperBound(
              argument.type,
              context.mapperClass.library.typeProvider.nullType,
            )
          : argument.type;
      if (typeSystem.isAssignableTo(type, parameterType)) {
        continue;
      }

      final description = '`${argument.description}`';
      if (typeSystem.isAssignableTo(
        typeSystem.promoteToNonNull(type),
        parameterType,
      )) {
        return 'argument ${i + 1} ($description) may be null '
            '(${_typeName(argument.type, argument.nullableChain)}) but '
            'parameter ${i + 1} is ${_typeName(parameterType)}';
      }

      return 'argument ${i + 1} ($description) is '
          '${_typeName(argument.type, argument.nullableChain)}, not '
          'assignable to parameter ${i + 1} (${_typeName(parameterType)})';
    }

    if (target != null &&
        !typeSystem.isAssignableTo(usage.returnType, target)) {
      return 'returns ${_typeName(usage.returnType)}, not assignable to '
          'the target ${_typeName(target)}';
    }

    return null;
  }

  String _typeName(DartType type, [bool nullable = false]) {
    final name = type.getDisplayString();

    return nullable && !name.endsWith('?') ? '$name?' : name;
  }

  String _label(_Candidate candidate) =>
      '${candidate.mapperClassName}.${candidate.usage.functionName}';

  String _signature(_Candidate candidate) {
    final usage = candidate.usage;
    final parameters = usage.parameters
        .map((p) => '${_typeName(p.field.type)} ${p.field.name}')
        .join(', ');

    return '${_label(candidate)}($parameters)';
  }
}

class _Candidate {
  final MapperUsage usage;
  final bool external;

  _Candidate(this.usage, {required this.external});

  String get mapperClassName =>
      usage.mapperType.element?.displayName ?? usage.mapperName;
}
