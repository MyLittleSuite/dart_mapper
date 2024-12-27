/*
 *
 *  Copyright (c) 2024 MyLittleSuite
 *
 *  Permission is hereby granted, free of charge, to any person
 *  obtaining a copy of this software and associated documentation
 *  files (the "Software"), to deal in the Software without
 *  restriction, including without limitation the rights to use,
 *  copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the
 *  Software is furnished to do so, subject to the following
 *  conditions:
 *
 *  The above copyright notice and this permission notice shall be
 *  included in all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 *  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 *  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 *  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 *  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 *  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 *  OTHER DEALINGS IN THE SOFTWARE.
 *
 */

import 'package:dart_mapper/dart_mapper.dart';

part 'expression_mapper.g.dart';

class ExpressionModel {
  final int noDefaultIntField;
  final int? defaultIntField;
  final bool noDefaultBoolField;
  final bool? defaultBoolField;
  final String noDefaultStringField;
  final String? defaultStringField;
  final List<String> noDefaultListField;
  final List<String>? defaultListField;
  final Set<String> noDefaultSetField;
  final Set<String>? defaultSetField;
  final Iterable<String> noDefaultIterableField;
  final Iterable<String>? defaultIterableField;

  const ExpressionModel({
    required this.noDefaultIntField,
    required this.defaultIntField,
    required this.noDefaultBoolField,
    required this.defaultBoolField,
    required this.noDefaultStringField,
    required this.defaultStringField,
    required this.noDefaultListField,
    required this.defaultListField,
    required this.noDefaultSetField,
    required this.defaultSetField,
    required this.noDefaultIterableField,
    required this.defaultIterableField,
  });
}

class AnotherExpressionModel {
  final int noDefaultIntField;
  final int defaultIntField;
  final bool noDefaultBoolField;
  final bool defaultBoolField;
  final String noDefaultStringField;
  final String defaultStringField;
  final String anotherStringField;
  final List<String> noDefaultListField;
  final List<String> defaultListField;
  final Set<String> noDefaultSetField;
  final Set<String>? defaultSetField;
  final Iterable<String> noDefaultIterableField;
  final Iterable<String>? defaultIterableField;

  const AnotherExpressionModel({
    required this.noDefaultIntField,
    required this.defaultIntField,
    required this.noDefaultBoolField,
    required this.defaultBoolField,
    required this.noDefaultStringField,
    required this.defaultStringField,
    required this.anotherStringField,
    required this.noDefaultListField,
    required this.defaultListField,
    required this.noDefaultSetField,
    required this.defaultSetField,
    required this.noDefaultIterableField,
    required this.defaultIterableField,
  });
}

@Mapper()
abstract class ExpressionMapper {
  const ExpressionMapper();

  @Mapping(target: 'defaultIntField', defaultValue: -1)
  @Mapping(target: 'defaultBoolField', defaultValue: true)
  @Mapping(target: 'defaultStringField', defaultValue: 'default')
  @Mapping(target: 'defaultDateTimeField', defaultValue: null)
  @Mapping(target: 'anotherStringField', defaultValue: 'anotherDefault')
  @Mapping(target: 'defaultListField', defaultValue: [])
  @Mapping(target: 'defaultSetField', defaultValue: {})
  @Mapping(target: 'defaultMapField', defaultValue: {})
  @Mapping(target: 'defaultIterableField', defaultValue: [])
  AnotherExpressionModel toAnotherExpressionModel(ExpressionModel response);
}
