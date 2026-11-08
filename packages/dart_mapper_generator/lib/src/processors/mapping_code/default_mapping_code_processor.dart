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
import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart' show InvalidGenerationSourceError;
import 'package:dart_mapper_generator/src/exceptions/no_relation_found_error.dart';
import 'package:dart_mapper_generator/src/exceptions/target_field_requires_non_optional_source_field_error.dart';
import 'package:dart_mapper_generator/src/exceptions/unknown_return_type_error.dart';
import 'package:dart_mapper_generator/src/extensions/class_element.dart';
import 'package:dart_mapper_generator/src/extensions/element.dart';
import 'package:dart_mapper_generator/src/factories/expression_factory.dart';
import 'package:dart_mapper_generator/src/misc/blocks.dart';
import 'package:dart_mapper_generator/src/models/binding.dart';
import 'package:dart_mapper_generator/src/models/mapping_behavior.dart';
import 'package:dart_mapper_generator/src/processors/component_processor.dart';
import 'package:dart_mapper_generator/src/strategies/strategy_dispatcher.dart';

class DefaultMappingCodeProcessor extends ComponentProcessor<Code> {
  final StrategyDispatcher<MappingBehavior, ExpressionFactory>
      expressionStrategyDispatcher;

  const DefaultMappingCodeProcessor({
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
    final targetClass = method.returnType?.element?.classElementOrNull;
    if (targetClass == null) {
      throw UnknownReturnTypeError(
        mapperClass: context.mapperClass,
        method: method,
      );
    }

    final instance = _instantiate(context, targetClass, method.bindings);

    return Block(
      (builder) {
        if (method.optionalReturn) {
          for (final parameter in method.parameters) {
            builder.statements.addAll(
              earlyReturnIfNull(parameter.field.name).statements,
            );
          }
        }



        builder.addExpression(instance.returned);
      },
    );
  }

  /// The instantiation of [targetClass] with the values of [bindings], one for
  /// each constructor parameter. Nested objects built from dotted targets are
  /// instantiated recursively; [path] is the path of [targetClass] from the
  /// target of the method (`address`), empty for the target itself.
  Expression _instantiate(
    ProcessorMethodContext context,
    ClassElement targetClass,
    List<Binding> bindings, {
    String path = '',
  }) {
    final targetConstructor = targetClass.mainConstructor;

    // One slot per positional parameter: an unmapped optional one is filled
    // with its default when a later one is passed.
    final positionalParameters = <FormalParameterElement>[];
    final positionalArguments = <Expression?>[];
    final namedArguments = <String, Expression>{};

    for (final parameter in targetConstructor.formalParameters) {
      if (parameter.name == null) {
        continue;
      }

      final argument = _argument(
        context,
        targetClass,
        parameter,
        bindings.where((b) => b.target.name == parameter.name).firstOrNull,
        path: path,
      );

      if (parameter.isNamed) {
        if (argument != null) {
          namedArguments[parameter.name!] = argument;
        }
      } else {
        positionalParameters.add(parameter);
        positionalArguments.add(argument);
      }
    }

    final last = positionalArguments.lastIndexWhere((e) => e != null);
    final positional = [
      for (var i = 0; i <= last; i++)
        positionalArguments[i] ??
            _defaultValue(
              context,
              targetClass,
              positionalParameters[i],
              path: path,
            ),
    ];

    return refer(context.resolveConstructor(targetConstructor))
        .newInstance(positional, namedArguments);
  }

  /// The value that stands for the default of the skipped optional positional
  /// [parameter], written in the generated code.
  ///
  /// The code of the default cannot be copied: it is resolved in the scope of
  /// the library declaring the constructor, which may not be the one of the
  /// mapper (a private constant, a class that is not imported). Its value is
  /// written instead, when it is a literal.
  Expression _defaultValue(
    ProcessorMethodContext context,
    ClassElement targetClass,
    FormalParameterElement parameter, {
    required String path,
  }) {
    final code = parameter.defaultValueCode;
    if (code == null) {
      return literalNull;
    }

    final value = parameter.computeConstantValue();
    if (value != null) {
      if (value.isNull) {
        return literalNull;
      }
      final literalValue = value.toBoolValue() ??
          value.toIntValue() ??
          value.toDoubleValue() ??
          value.toStringValue();
      if (literalValue != null) {
        return literal(literalValue);
      }
    }

    final fullPath = path.isEmpty ? parameter.name! : '$path.${parameter.name}';
    throw InvalidGenerationSourceError(
      "Cannot skip the optional positional parameter '$fullPath' of "
      "'${targetClass.displayName}' in "
      "'${context.mapperClass.name}.${context.currentMethod.name}': a later "
      "parameter is mapped and its default value '$code' cannot be copied "
      "into the generated code.\n"
      "Fix: Map '$fullPath' explicitly with @Mapping(target: '$fullPath', "
      "source: ..., constant: ... or expression: ...).",
      element: targetClass,
    );
  }

  /// The value passed for [parameter], `null` when it is left out.
  Expression? _argument(
    ProcessorMethodContext context,
    ClassElement targetClass,
    FormalParameterElement parameter,
    Binding? binding, {
    required String path,
  }) {
    final method = context.currentMethod;
    final name = parameter.name!;
    final fullPath = path.isEmpty ? name : '$path.$name';

    if (parameter.isRequired && binding == null) {
      throw NoRelationFoundError(
        parameter: parameter,
        mapperClass: context.mapperClass,
        method: method,
        targetClass: targetClass,
        targetPath: fullPath,
      );
    }

    final nestedBindings = binding?.nestedBindings;
    if (binding != null && nestedBindings != null) {
      final nestedClass = binding.target.type.element?.classElementOrNull;
      if (nestedClass == null) {
        throw UnknownReturnTypeError(
          mapperClass: context.mapperClass,
          method: method,
        );
      }

      return _instantiate(context, nestedClass, nestedBindings, path: fullPath);
    }

    // An ignored optional parameter is left out when passing `null` would be
    // wrong: it has a default value to keep (even for a nullable parameter),
    // or its source is not nullable. Otherwise `null` is its default anyway.
    if (binding != null &&
        binding.ignored &&
        binding.constant == null &&
        binding.expression == null &&
        parameter.isOptional &&
        (parameter.defaultValueCode != null || !binding.source.nullable)) {
      return null;
    }

    if (binding?.forceNonNull == false &&
        !parameter.isOptional &&
        binding?.source.nullable == true &&
        binding?.target.nullable == false &&
        binding?.defaultValue == null &&
        binding?.constant == null &&
        binding?.expression == null &&
        binding?.conditionExpression == null &&
        binding?.callableMappingMethod == null) {
      throw TargetFieldRequiresNonOptionalSourceFieldError(
        fieldName: name,
        targetClass: targetClass,
        mapperName: context.mapperClass.name,
        methodName: method.name,
      );
    }

    if (binding == null) {
      return null;
    }

    var sourceExpression =
        expressionStrategyDispatcher.get(method.behavior).create(
              ExpressionContext(
                field: binding.source,
                origin: FieldOrigin.source,
                counterpartField: binding.target,
                ignored: binding.ignored,
                forceNonNull: binding.forceNonNull,
                currentMethod: method,
                expressionMappingMethod: binding.callableMappingMethod,
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

    // Ternary wrapping for conditionExpression (D-07)
    if (binding.conditionExpression != null) {
      if (!binding.target.nullable && binding.defaultValue == null) {
        throw InvalidGenerationSourceError(
          "conditionExpression on non-nullable target '${binding.target.name}': "
          "requires a defaultValue or a nullable target type.\n"
          "Fix: Add defaultValue: '...' to the @Mapping annotation, or make the target field nullable.",
          element: targetClass,
        );
      }
      final condition = CodeExpression(
        Code(resolveConditionExpression(binding.conditionExpression!)),
      );
      final falseExpr = binding.defaultValue != null
          ? (binding.target.type.isDartCoreString
              ? literalString(binding.defaultValue!)
              : CodeExpression(Code(binding.defaultValue!)))
          : literalNull;
      sourceExpression = condition.conditional(sourceExpression, falseExpr);
    }

    return sourceExpression;
  }
}
