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
import 'package:dart_mapper_generator/src/models/field/field.dart';
import 'package:dart_mapper_generator/src/models/mapper/mapping/mapping_method.dart';

enum BindingExpressionType {
  source,
  target,
}

class Binding {
  final Field source;
  final Field target;
  final bool ignored;
  final MappingMethod? extraMappingMethod;

  Binding({
    required this.source,
    required this.target,
    this.ignored = false,
    this.extraMappingMethod,
  }) /* : assert(target.required && ignored,
            'Target field \'${target.name}\' must be required') TODO:*/
  ;

  Iterable<MappingMethod> get mappingMethods sync* {
    if (extraMappingMethod != null) {
      yield extraMappingMethod!;

      yield* extraMappingMethod!.bindings
          .expand((binding) => binding.mappingMethods);
    }
  }

  Expression expression(BindingExpressionType type) {
    switch (type) {
      case BindingExpressionType.source:
        return _expression(source);
      case BindingExpressionType.target:
        return _expression(target);
    }
  }

  Expression _expression(Field field) {
    final basicExpression = _basicExpression(field);

    if (field is MapField) {
      return basicExpression.property('map').call([
        CodeExpression(
          Code(
            extraMappingMethod?.name ?? '(key, value) => MapEntry(key, value)',
          ),
        ),
      ]);
    } else if (field is IterableField) {
      final cloneExpression = basicExpression.property('map').call([
        CodeExpression(Code(extraMappingMethod?.name ?? '(item) => item')),
      ]);

      if (field.type.isDartCoreList) {
        return cloneExpression
            .property('toList')
            .call([], {'growable': literalFalse});
      } else if (field.type.isDartCoreSet) {
        return cloneExpression.property('toSet').call([]);
      } else if (field.type.isDartCoreIterable) {
        return cloneExpression;
      }
    } else if (field is NestedField && extraMappingMethod != null) {
      // {extraMappingMethod.name}(source)
      return CodeExpression(Code(extraMappingMethod!.name)).call([
        basicExpression,
      ]);
    }

    return basicExpression;
  }

  Expression _basicExpression(Field field) {
    if (field.instance != null) {
      return refer(field.instance!.name).property(field.name);
    }

    return refer(field.name);
  }

  @override
  String toString() => 'Binding{'
      'source: $source, '
      'target: $target, '
      'ignored: $ignored, '
      'extraMappingMethod: $extraMappingMethod'
      '}';
}
