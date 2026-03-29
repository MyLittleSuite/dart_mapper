/*
 * Copyright (c) 2024 MyLittleSuite
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

import 'package:code_builder/code_builder.dart' hide Field;
import 'package:dart_mapper_generator/src/extensions/dart_type.dart';
import 'package:dart_mapper_generator/src/extensions/expression.dart';
import 'package:dart_mapper_generator/src/mixins/aliases_mixin.dart';
import 'package:dart_mapper_generator/src/models/field/field.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/bases/mapping_method.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/callable_mapping_method.dart';

enum FieldOrigin {
  source,
  target,
}

class ExpressionContext with AliasesMixin {
  final Field field;
  final FieldOrigin origin;
  final Field counterpartField;
  final MappingMethod currentMethod;
  final bool ignored;
  final bool forceNonNull;
  final CallableMappingMethod? expressionMappingMethod;
  final MappingMethod? extraMappingMethod;
  @override
  final Map<Uri, String>? importAliases;
  final String? defaultValue;
  final String? constant;
  final String? expression;
  final String? conditionExpression;
  final List<(String segment, bool nullable)>? accessChain;
  final List<Field>? sources;
  final List<List<(String, bool)>?>? sourceAccessChains;

  const ExpressionContext({
    required this.field,
    required this.origin,
    required this.counterpartField,
    required this.currentMethod,
    this.ignored = false,
    this.forceNonNull = false,
    this.expressionMappingMethod,
    this.extraMappingMethod,
    this.importAliases,
    this.defaultValue,
    this.constant,
    this.expression,
    this.conditionExpression,
    this.accessChain,
    this.sources,
    this.sourceAccessChains,
  });
}

abstract class ExpressionFactory {
  const ExpressionFactory();

  Expression create(ExpressionContext context);

  Expression basic(ExpressionContext context) {
    // Expression handling: highest priority — emit verbatim Dart expression.
    if (context.expression != null) {
      return CodeExpression(Code(resolveExpression(context.expression!)));
    }

    // Constant handling: next priority — return the constant value verbatim
    // with no source reference at all.
    if (context.constant != null) {
      if (context.counterpartField.type.isDartCoreString) {
        return literalString(context.constant!);
      }
      return CodeExpression(Code(context.constant!));
    }

    if (!context.forceNonNull && !context.field.nullable && context.ignored) {
      throw ArgumentError(
        'Field ${context.field.name} is not nullable and ignored, mapping function ${context.currentMethod.name}.',
      );
    }

    if (context.field.nullable && context.ignored) {
      return literal(null);
    }

    // Access chain handling: build chain using property()/nullSafeProperty().
    Expression result;
    if (context.accessChain != null && context.accessChain!.isNotEmpty) {
      result = refer(context.field.instance!.name);
      for (final (segment, parentIsNullable) in context.accessChain!) {
        result = parentIsNullable
            ? result.nullSafeProperty(segment)
            : result.property(segment);
      }
    } else {
      result = context.field.instance != null
          ? refer(context.field.instance!.name).property(context.field.name)
          : refer(context.field.name);
    }

    if (context.forceNonNull == true) {
      result = result.nullChecked;
    }

    Expression finalExpr;
    if (context.expressionMappingMethod != null) {
      if (context.sources != null && context.sources!.isNotEmpty) {
        // Multi-arg callable: emit callable(source.a, source.b, ...)
        final args = <Expression>[];
        for (var i = 0; i < context.sources!.length; i++) {
          final src = context.sources![i];
          final chain = context.sourceAccessChains?[i];
          Expression expr;
          if (chain != null && chain.isNotEmpty) {
            expr = refer(src.instance!.name);
            for (final (segment, parentIsNullable) in chain) {
              expr = parentIsNullable
                  ? expr.nullSafeProperty(segment)
                  : expr.property(segment);
            }
          } else {
            expr = src.instance != null
                ? refer(src.instance!.name).property(src.name)
                : refer(src.name);
          }
          args.add(expr);
        }
        finalExpr = refer(context.expressionMappingMethod!.name).call(args);
      } else {
        // Single-arg callable (existing behaviour — unchanged).
        finalExpr = refer(context.expressionMappingMethod!.name).call([result]);
      }
    } else {
      finalExpr = _transformation(context, basic: result);
    }

    // defaultValue handling: wrap with ?? after callable/transformation.
    if (context.defaultValue != null) {
      final defaultExpr = context.counterpartField.type.isDartCoreString
          ? literalString(context.defaultValue!)
          : CodeExpression(Code(context.defaultValue!));
      finalExpr = finalExpr.ifNullThen(defaultExpr);
    }

    return finalExpr;
  }

  Expression _transformation(
    ExpressionContext context, {
    required Expression basic,
  }) {
    final field = context.field;
    final counterpart = context.counterpartField;

    if (field is PrimitiveField && counterpart is PrimitiveField) {
      if (field.type.isDartCoreString) {
        return _transformationFromString(context, basic);
      } else if (field.type.isDateTime) {
        return _transformationFromDateTime(context, basic);
      } else if (field.type.isDartCoreNum) {
        return _transformationFromNum(context, basic);
      } else if (field.type.isDartCoreDouble) {
        return _transformationFromDouble(context, basic);
      } else if (field.type.isDartCoreInt) {
        return _transformationFromInt(context, basic);
      }
    }

    return basic;
  }

  Expression _transformationFromString(
    ExpressionContext context,
    Expression basic,
  ) {
    final field = context.field;
    final counterpart = context.counterpartField;
    final fallback = field.nullable ? literal('') : null;

    if (counterpart.type.isDateTime) {
      return basic.stringToDateTime(
          nullable: field.nullable, fallback: fallback);
    } else if (counterpart.type.isDartCoreInt) {
      return basic.stringToInt(nullable: field.nullable, fallback: fallback);
    } else if (counterpart.type.isDartCoreDouble) {
      return basic.stringToDouble(nullable: field.nullable, fallback: fallback);
    } else if (counterpart.type.isDartCoreNum) {
      return basic.stringToNum(nullable: field.nullable, fallback: fallback);
    }

    return basic;
  }

  Expression _transformationFromDateTime(
    ExpressionContext context,
    Expression basic,
  ) {
    final field = context.field;
    final counterpart = context.counterpartField;

    if (counterpart.type.isDartCoreString) {
      return basic.dateTimeToIsoString(nullable: field.nullable);
    }

    return basic;
  }

  Expression _transformationFromNum(
    ExpressionContext context,
    Expression basic,
  ) {
    final field = context.field;
    final counterpart = context.counterpartField;

    if (counterpart.type.isDartCoreString) {
      return basic.propertyToString(nullable: field.nullable);
    } else if (counterpart.type.isDartCoreInt) {
      return basic.propertyToInt(nullable: field.nullable);
    } else if (counterpart.type.isDartCoreDouble) {
      return basic.propertyToDouble(nullable: field.nullable);
    }

    return basic;
  }

  Expression _transformationFromDouble(
    ExpressionContext context,
    Expression basic,
  ) {
    final field = context.field;
    final counterpart = context.counterpartField;

    if (counterpart.type.isDartCoreString) {
      return basic.propertyToString(nullable: field.nullable);
    }

    return basic;
  }

  Expression _transformationFromInt(
    ExpressionContext context,
    Expression basic,
  ) {
    final field = context.field;
    final counterpart = context.counterpartField;

    if (counterpart.type.isDartCoreString) {
      return basic.propertyToString(nullable: field.nullable);
    }

    return basic;
  }

}

/// Detects string interpolation syntax (`${...}`) in [expression] and
/// auto-wraps the **entire expression** in a string literal when it isn't
/// already one. Use for `expression:` fields where the whole value is a
/// string — e.g. `"\${source.first} \${source.last}"` produces
/// `'${source.first} ${source.last}'` in generated code.
String resolveExpression(String expression) {
  if (expression.startsWith("'") || expression.startsWith('"')) {
    return expression;
  }

  final hasInterpolation = expression.contains(r'${') ||
      RegExp(r'\$[a-zA-Z_]').hasMatch(expression);

  if (!hasInterpolation) return expression;

  final hasSingle = expression.contains("'");
  final hasDouble = expression.contains('"');

  String quote;
  if (!hasSingle) {
    // No single quotes — wrap with single quotes, no escaping needed.
    quote = "'";
  } else if (!hasDouble) {
    // Has single quotes but no double quotes — wrap with double quotes.
    quote = '"';
  } else {
    // Both quote types present — pick single quote and escape inner content.
    // Escape backslashes first, then escape single quotes.
    quote = "'";
    expression = expression
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'");
  }
  return '$quote$expression$quote';
}

/// Detects bare `${...}` tokens and `$identifier` tokens in [expression] and
/// wraps **each token individually** in single quotes. Use for
/// `conditionExpression:` fields where only parts of the expression are
/// strings — e.g. `r"${source.label}.isNotEmpty"` produces
/// `'${source.label}'.isNotEmpty`, and `r"$label.isNotEmpty"` produces
/// `'$label'.isNotEmpty`.
///
/// Tokens already preceded by a quote character are left untouched to avoid
/// double-wrapping.
String resolveConditionExpression(String expression) {
  final hasInterpolation = expression.contains(r'${') ||
      RegExp(r'\$[A-Za-z_]').hasMatch(expression);
  if (!hasInterpolation) return expression;

  return expression.replaceAllMapped(
    RegExp(r"\$\{[^}]+\}|\$[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*"),
    (match) {
      final start = match.start;
      if (start > 0 && (expression[start - 1] == "'" || expression[start - 1] == '"')) {
        return match.group(0)!;
      }
      return "'${match.group(0)}'";
    },
  );
}
