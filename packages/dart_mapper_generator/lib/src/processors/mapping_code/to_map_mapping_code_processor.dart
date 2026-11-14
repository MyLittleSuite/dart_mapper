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

import 'package:code_builder/code_builder.dart';
import 'package:dart_mapper_generator/src/factories/expression_factory.dart';
import 'package:dart_mapper_generator/src/misc/blocks.dart';
import 'package:dart_mapper_generator/src/misc/map_key_tree.dart';
import 'package:dart_mapper_generator/src/models/binding.dart';
import 'package:dart_mapper_generator/src/models/mapping_behavior.dart';
import 'package:dart_mapper_generator/src/processors/component_processor.dart';
import 'package:dart_mapper_generator/src/strategies/strategy_dispatcher.dart';

/// Generates the body of a class to Map mapping method: a map literal whose
/// entries are the bindings (nested maps for targets using dot notation).
class ToMapMappingCodeProcessor extends ComponentProcessor<Code> {
  final StrategyDispatcher<MappingBehavior, ExpressionFactory>
      expressionStrategyDispatcher;

  const ToMapMappingCodeProcessor({
    required this.expressionStrategyDispatcher,
  });

  @override
  Code process(ProcessorContext context) {
    if (context is! ProcessorMethodContext) {
      throw ArgumentError(
        'Invalid context type. Expected ProcessorMethodContext.',
      );
    }

    final method = context.currentMethod;
    final tree = buildMapKeyTree(
      method.bindings.map(
        (binding) => (
          binding.target.name,
          _createValue(context, binding),
        ),
      ),
    );

    return Block(
      (builder) {
        if (method.optionalReturn) {
          for (final parameter in method.parameters) {
            builder.statements.addAll(
              earlyReturnIfNull(parameter.field.name).statements,
            );
          }
        }

        builder.addExpression(_literal(tree).returned);
      },
    );
  }

  Expression _literal(MapKeyBranch<Expression> branch) => literalMap({
        for (final entry in branch.children.entries)
          literalString(entry.key): switch (entry.value) {
            MapKeyLeaf(:final value) => value,
            MapKeyBranch() => _literal(entry.value as MapKeyBranch<Expression>),
          },
      });

  Expression _createValue(ProcessorMethodContext context, Binding binding) {
    final method = context.currentMethod;

    var value = expressionStrategyDispatcher.get(method.behavior).create(
          ExpressionContext(
            field: binding.source,
            origin: FieldOrigin.source,
            counterpartField: binding.target,
            ignored: binding.ignored,
            forceNonNull: binding.forceNonNull,
            currentMethod: method,
            expressionMappingMethod: binding.expressionMappingMethod,
            extraMappingMethod: binding.extraMappingMethod,
            importAliases: context.importAliases,
            defaultValue: binding.defaultValue,
            constant: binding.constant,
            expression: binding.expression,
            conditionExpression: binding.conditionExpression,
            accessChain: binding.accessChain,
            sources: binding.sources,
            sourceAccessChains: binding.sourceAccessChains,
          ),
        );

    if (binding.conditionExpression != null) {
      final condition = CodeExpression(
        Code(resolveConditionExpression(binding.conditionExpression!)),
      );
      final falseExpr = binding.defaultValue != null
          ? (binding.target.type.isDartCoreString
              ? literalString(binding.defaultValue!)
              : CodeExpression(Code(binding.defaultValue!)))
          : literalNull;
      value = condition.conditional(value, falseExpr);
    }

    return value;
  }
}
