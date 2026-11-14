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
import 'package:dart_mapper_generator/src/exceptions/inaccessible_constructor_error.dart';
import 'package:dart_mapper_generator/src/exceptions/invalid_nested_target_error.dart';
import 'package:dart_mapper_generator/src/extensions/class_element.dart';
import 'package:dart_mapper_generator/src/extensions/dart_type.dart';
import 'package:dart_mapper_generator/src/extensions/element.dart';
import 'package:dart_mapper_generator/src/models/binding.dart';
import 'package:dart_mapper_generator/src/models/field/field.dart';

/// A constructor parameter of the target class, or of a class nested in it
/// (reached through a dotted target such as `address.street`).
class TargetParam {
  /// The path of the parameter from the target class (`address.street`).
  final String path;
  final DartType type;
  final bool isRequired;

  const TargetParam({
    required this.path,
    required this.type,
    required this.isRequired,
  });
}

/// The segments before the last one of [target]: `a.b.c` -> `a`, `a.b`.
Iterable<String> nestedTargetPrefixes(String target) sync* {
  final segments = target.split('.');
  for (var i = 1; i < segments.length; i++) {
    yield segments.sublist(0, i).join('.');
  }
}

/// The first segment of every dotted target: `address.street` -> `address`.
Set<String> nestedTargetRoots(Iterable<String> targets) => targets
    .where((target) => target.contains('.'))
    .map((target) => target.split('.').first)
    .toSet();

/// Rejects dotted targets with an empty segment (`a..b`, `.a`, `a.`) and
/// targets mapped as a whole value that are also the prefix of other targets
/// (`address` and `address.street`).
void validateNestedTargetPaths(
  Iterable<String> targets, {
  Element? element,
}) {
  final all = targets.toSet();
  final prefixes = <String>{};

  for (final target in all.where((target) => target.contains('.'))) {
    if (target.split('.').any((segment) => segment.isEmpty)) {
      throw InvalidNestedTargetError(
        target: target,
        description: 'it contains an empty segment',
        element: element,
      );
    }
    prefixes.addAll(nestedTargetPrefixes(target));
  }

  for (final prefix in prefixes) {
    if (all.contains(prefix)) {
      throw InvalidNestedTargetError(
        target: prefix,
        description: "it is mapped as a whole value but it is also the "
            "prefix of nested targets",
        element: element,
      );
    }
  }
}

/// Whether a value of [type] can be built field by field from nested targets.
bool isBuildableNestedType(DartType type) =>
    type.element?.classElementOrNull != null &&
    !type.isPrimitive &&
    !type.isIterable &&
    !type.isMap &&
    !type.isEnum &&
    type is! DynamicType;

/// The parameters of the main constructor of [targetType], by path, extended
/// with the parameters of every class nested in it that is reached by a dotted
/// entry of [targets] (`address.street` adds the parameters of the type of
/// `address`, under the `address.` prefix).
///
/// Throws [InvalidNestedTargetError] when a dotted target cannot be resolved
/// or when its class cannot be built.
///
/// When [library] (the library of the mapper) is given, a nested class whose
/// constructor is private to another library, or that the library cannot name
/// (not imported, hidden), is rejected too: the generated code could not
/// instantiate it. [importAliases] gives the import prefix of each library.
Map<String, TargetParam> resolveTargetParams(
  DartType targetType,
  Iterable<String> targets, {
  Element? element,
  LibraryElement? library,
  Map<Uri, String>? importAliases,
}) {
  final targetClass = targetType.element?.classElementOrNull;
  if (targetClass == null) {
    return const {};
  }
  if (library != null) {
    validateConstructorAccessible(
      targetClass,
      library: library,
      element: element,
    );
  }

  final result = <String, TargetParam>{
    ..._parametersOf(targetClass, targetType, ''),
  };

  final dotted = targets.where((target) => target.contains('.')).toList()
    ..sort();
  if (dotted.isEmpty) {
    return result;
  }
  validateNestedTargetPaths(targets, element: element);

  // Containers are expanded parents first (`a` before `a.b`).
  final containers = {
    for (final target in dotted) ...nestedTargetPrefixes(target),
  }.toList()
    ..sort((a, b) => a.split('.').length.compareTo(b.split('.').length));

  for (final container in containers) {
    final param = result[container];
    final parent = container.contains('.')
        ? container.substring(0, container.lastIndexOf('.'))
        : null;
    if (param == null) {
      final owner = parent == null
          ? targetClass.displayName
          : result[parent]!.type.getDisplayString();
      final available = result.values
          .where((p) => _parentOf(p.path) == parent)
          .map((p) => _lastSegment(p.path))
          .join(', ');
      throw InvalidNestedTargetError(
        target: dotted.firstWhere((t) => t.startsWith('$container.')),
        description: "'${_lastSegment(container)}' is not a constructor "
            "parameter of '$owner' (available: $available)",
        element: element,
      );
    }

    final nestedClass = param.type.element?.classElementOrNull;
    if (!isBuildableNestedType(param.type) || nestedClass == null) {
      throw InvalidNestedTargetError(
        target: container,
        description: "'${_lastSegment(container)}' is of type "
            "'${param.type.getDisplayString()}', which is not a class that "
            "can be built from nested targets",
        element: element,
      );
    }
    if (param.type.isBuiltValue) {
      throw InvalidNestedTargetError(
        target: container,
        description: "'${param.type.getDisplayString()}' is a built_value "
            "class, nested targets cannot build it",
        element: element,
      );
    }
    if (nestedClass.isSealed ||
        (nestedClass.isAbstract && !nestedClass.mainConstructor.isFactory)) {
      throw InvalidNestedTargetError(
        target: container,
        description: "'${nestedClass.displayName}' is abstract or sealed and "
            "cannot be instantiated",
        element: element,
      );
    }

    if (library != null) {
      _validateAccessible(
        nestedClass,
        library: library,
        importAliases: importAliases,
        target: container,
        element: element,
      );
    }

    result.addAll(_parametersOf(nestedClass, param.type, '$container.'));
  }

  for (final target in dotted) {
    if (!result.containsKey(target)) {
      final container = target.substring(0, target.lastIndexOf('.'));
      final available = result.values
          .where((p) => _parentOf(p.path) == container)
          .map((p) => _lastSegment(p.path))
          .join(', ');
      throw InvalidNestedTargetError(
        target: target,
        description: "'${_lastSegment(target)}' is not a constructor "
            "parameter of '${result[container]!.type.getDisplayString()}' "
            "(available: $available)",
        element: element,
      );
    }
  }

  return result;
}

/// Throws [InaccessibleConstructorError] when the constructor the generated
/// code would call to build [targetClass] cannot be called from [library].
void validateConstructorAccessible(
  ClassElement targetClass, {
  required LibraryElement library,
  Element? element,
}) {
  final constructor = targetClass.mainConstructor;
  if (!targetClass.isAccessibleFrom(constructor, library)) {
    throw InaccessibleConstructorError(
      targetClass: targetClass,
      constructor: constructor,
      element: element,
    );
  }
}

void _validateAccessible(
  ClassElement nestedClass, {
  required LibraryElement library,
  required Map<Uri, String>? importAliases,
  required String target,
  required Element? element,
}) {
  final constructor = nestedClass.mainConstructor;
  if (!nestedClass.isAccessibleFrom(constructor, library)) {
    throw InvalidNestedTargetError(
      target: target,
      description: "the constructor '${constructor.displayName}' of "
          "'${nestedClass.displayName}' is private to its library, so the "
          "mapper cannot call it",
      fix: 'Expose a public constructor on the nested class, or build the '
          'value with callable.',
      element: element,
    );
  }

  if (!_isNameable(library, nestedClass, importAliases)) {
    throw InvalidNestedTargetError(
      target: target,
      description: "'${nestedClass.displayName}' is not imported by the "
          "mapper's library, so the generated code cannot name it",
      fix: "Import the library declaring '${nestedClass.displayName}' in the "
          "file of the mapper (and do not hide it).",
      element: element,
    );
  }
}

/// Whether [element] can be named in [library], directly or through the
/// prefix it is imported with.
bool _isNameable(
  LibraryElement library,
  ClassElement element,
  Map<Uri, String>? importAliases,
) {
  final name = element.name;
  if (name == null) {
    return false;
  }

  final scope = library.firstFragment.scope;
  if (scope.lookup(name).getter == element) {
    return true;
  }

  final prefix = importAliases?[element.library.firstFragment.source.uri];
  if (prefix != null) {
    final prefixElement = scope.lookup(prefix).getter;
    if (prefixElement is PrefixElement) {
      return prefixElement.scope.lookup(name).getter == element;
    }
  }

  return false;
}

/// The types of the parameters of the main constructor of [cls], resolved
/// against the type arguments of [type] (`T value` of `Box<Address>` is
/// `Address`). Unlike the types of the getters, they cover parameters that
/// are not stored in a field of the same name.
Map<String, DartType> constructorParameterTypes(
  DartType type,
  ClassElement cls,
) {
  final main = cls.mainConstructor;
  final declared = {
    for (final parameter in main.formalParameters)
      if (parameter.name != null) parameter.name!: parameter.type,
  };
  if (type is! InterfaceType || type.typeArguments.isEmpty) {
    return declared;
  }

  final substituted =
      type.constructors.where((c) => c.name == main.name).firstOrNull;
  if (substituted == null) {
    return declared;
  }

  return {
    for (final parameter in substituted.formalParameters)
      if (parameter.name != null) parameter.name!: parameter.type,
  };
}

Map<String, TargetParam> _parametersOf(
  ClassElement targetClass,
  DartType targetType,
  String prefix,
) {
  final types = constructorParameterTypes(targetType, targetClass);

  return {
    for (final parameter in targetClass.constructorParameters)
      if (parameter.name != null)
        '$prefix${parameter.name}': TargetParam(
          path: '$prefix${parameter.name}',
          type: types[parameter.name!] ?? parameter.type,
          isRequired: parameter.isRequired,
        ),
  };
}

String? _parentOf(String path) =>
    path.contains('.') ? path.substring(0, path.lastIndexOf('.')) : null;

String _lastSegment(String path) => path.split('.').last;

/// Groups [bindings] whose target is a path (`address.street`) into one
/// binding per nested object, holding the bindings of its properties.
///
/// [parentField] gives the field describing the nested object at a path
/// (`address`). Bindings are expected to be named after their full path and
/// are renamed after their last segment. A nested object named by
/// [configuredTargets] is kept even when none of its properties got a
/// binding, so that the properties it is missing are reported.
List<Binding> groupNestedBindings(
  List<Binding> bindings, {
  required Field Function(String path) parentField,
  Iterable<String> configuredTargets = const [],
  String prefix = '',
}) {
  final plain = <Binding>[];
  final groups = <String, List<Binding>>{};

  for (final binding in bindings) {
    final relative = binding.target.name.substring(prefix.length);
    final dot = relative.indexOf('.');
    if (dot < 0) {
      plain.add(binding.withTarget(_renamed(binding.target, relative)));
    } else {
      groups
          .putIfAbsent('$prefix${relative.substring(0, dot)}', () => [])
          .add(binding);
    }
  }

  for (final target in configuredTargets) {
    if (!target.startsWith(prefix)) {
      continue;
    }
    final relative = target.substring(prefix.length);
    final dot = relative.indexOf('.');
    if (dot > 0) {
      groups.putIfAbsent('$prefix${relative.substring(0, dot)}', () => []);
    }
  }

  return [
    ...plain,
    for (final entry in groups.entries)
      () {
        final parent = parentField(entry.key);
        final relative = entry.key.substring(prefix.length);

        return Binding(
          source: Field.from(
            name: relative,
            type: parent.type,
            nullable: true,
          ),
          target: _renamed(parent, relative),
          nestedBindings: groupNestedBindings(
            entry.value,
            parentField: parentField,
            configuredTargets: configuredTargets,
            prefix: '${entry.key}.',
          ),
        );
      }(),
  ];
}

Field _renamed(Field field, String name) => Field.from(
      name: name,
      type: field.type,
      instance: field.instance,
      required: field.required,
      nullable: field.nullable,
    );
