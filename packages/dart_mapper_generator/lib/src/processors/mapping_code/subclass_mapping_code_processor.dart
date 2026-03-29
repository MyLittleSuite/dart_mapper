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

import 'package:code_builder/code_builder.dart';
import 'package:dart_mapper_generator/src/extensions/dart_type.dart';
import 'package:dart_mapper_generator/src/misc/expressions.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/subclass_mapping_method.dart';
import 'package:dart_mapper_generator/src/processors/component_processor.dart';

/// Generates the body of a @SubclassMapping dispatch method.
///
/// Output example (needsWildcard: true):
/// ```dart
/// return switch (source) {
///   Dog dog => toDogDto(dog),
///   Cat cat => toCatDto(cat),
///   _ => throw ArgumentError('Unexpected subtype: ${source.runtimeType}'),
/// };
/// ```
class SubclassMappingCodeProcessor extends ComponentProcessor<Code> {
  const SubclassMappingCodeProcessor();

  @override
  Code process(ProcessorContext context) {
    if (context is! ProcessorMethodContext) {
      throw ArgumentError(
        'Invalid context type. Expected ProcessorMethodContext.',
      );
    }

    final method = context.currentMethod;
    if (method is! SubclassMappingMethod) {
      throw ArgumentError(
        'SubclassMappingCodeProcessor requires a SubclassMappingMethod. '
        'Got: ${method.runtimeType}',
      );
    }

    // The dispatch method has exactly one parameter — the base-type source.
    final sourceParamName = method.parameters.first.field.name;

    // Build type-pattern switch arms.
    // Per RESEARCH.md Pattern 3: use CodeExpression(Code('TypeName varName'))
    // for the pattern since code_builder has no dedicated type-pattern AST node.
    final cases = method.dispatchPairs.map((pair) {
      final resolvedTypeName = context.resolveType(
        pair.sourceType,
        withNullability: false,
      );
      // Derive a valid Dart identifier for the bound variable.
      // DartTypeExtension.parameterName applies toSnakeCase().toCamelCase(lower: true),
      // but may produce invalid identifiers for types with $ chars.
      final varName = _sanitizeVarName(pair.sourceType.parameterName);

      final typePattern = CodeExpression(Code('$resolvedTypeName $varName'));
      final delegateCall = refer(pair.delegateMethod).call([refer(varName)]);
      return (typePattern, delegateCall);
    });

    // Wildcard arm: _ => throw ArgumentError('Unexpected subtype: ${source.runtimeType}')
    // Uses string interpolation; the source param name is substituted literally.
    final wildcardError = method.needsWildcard
        ? CodeExpression(
            Code(
              "throw ArgumentError('Unexpected subtype: \${$sourceParamName.runtimeType}')",
            ),
          )
        : null;

    return Block(
      (b) => b.addExpression(
        returnSwitch(
          refer(sourceParamName),
          cases: cases,
          otherwise: wildcardError,
        ).returned,
      ),
    );
  }

  /// Sanitizes a raw variable name to produce a valid Dart identifier.
  ///
  /// Replaces all non-alphanumeric characters with underscores, trims leading/
  /// trailing underscores, and lowercases the first character. This handles
  /// GQL-style type names with $ characters (e.g.,
  /// Mutation$CreateTodo$createTodoOfMine$data$$ProductTemplateDto).
  /// Appends `$` if the resulting identifier collides with a Dart reserved word.
  String _sanitizeVarName(String raw) {
    const dartReservedWords = {
      'assert', 'break', 'case', 'catch', 'class', 'const', 'continue',
      'default', 'do', 'else', 'enum', 'extends', 'false', 'final',
      'finally', 'for', 'if', 'in', 'is', 'new', 'null', 'rethrow',
      'return', 'super', 'switch', 'this', 'throw', 'true', 'try',
      'var', 'void', 'while', 'with',
    };
    final sanitized = raw.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final trimmed = sanitized.replaceAll(RegExp(r'^_+|_+$'), '');
    if (trimmed.isEmpty) return 'source';
    final candidate = trimmed[0].toLowerCase() + trimmed.substring(1);
    return dartReservedWords.contains(candidate) ? '$candidate\$' : candidate;
  }
}
