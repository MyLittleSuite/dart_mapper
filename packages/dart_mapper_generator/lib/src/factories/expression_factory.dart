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
import 'package:dart_mapper_generator/src/models/mapper/mapping/method/mapping_method.dart';

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
  final MappingMethod? extraMappingMethod;
  @override
  final Map<Uri, String>? importAliases;

  const ExpressionContext({
    required this.field,
    required this.origin,
    required this.counterpartField,
    required this.currentMethod,
    this.ignored = false,
    this.extraMappingMethod,
    this.importAliases,
  });
}

abstract class ExpressionFactory {
  const ExpressionFactory();

  Expression create(ExpressionContext context);

  Expression basic(ExpressionContext context) {
    if (!context.field.nullable && context.ignored) {
      throw ArgumentError(
        'Field ${context.field.name} is not nullable and ignored, mapping function ${context.currentMethod.name}.',
      );
    }

    if (context.field.nullable && context.ignored) {
      return literal(null);
    }

    final result = context.field.instance != null
        ? refer(context.field.instance!.name).property(context.field.name)
        : refer(context.field.name);

    return _transformation(context, result);
  }

  Expression _transformation(ExpressionContext context, Expression basic) {
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

    if (counterpart.type.isDateTime) {
      return basic.stringToDateTime(nullable: field.nullable);
    } else if (counterpart.type.isDartCoreInt) {
      return basic.stringToInt(nullable: field.nullable);
    } else if (counterpart.type.isDartCoreDouble) {
      return basic.stringToDouble(nullable: field.nullable);
    } else if (counterpart.type.isDartCoreNum) {
      return basic.stringToNum(nullable: field.nullable);
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
