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

import 'package:analyzer/dart/element/element.dart';
import 'package:dart_mapper_generator/src/exceptions/no_constructors_available_error.dart';

extension ClassElementExtension on ClassElement {
  static const _ignoreGetters = {
    'copyWith',
    'toString',
    'hashCode',
    'runtimeType',
  };

  ConstructorElement get primaryConstructor {
    final constructor = (constructors
          ..sort(
            (a, b) => a.parameters.length.compareTo(b.parameters.length) * -1,
          ))
        .firstOrNull;
    if (constructor == null) {
      throw NoConstructorsAvailableError(this);
    }

    return constructor;
  }

  List<VariableElement> get constructorParameters =>
      primaryConstructor.parameters;

  List<VariableElement> get getters {
    final allSuperclasses = allSupertypes
        .where((element) => !element.isDartCoreObject)
        .map((element) => element.element)
        .toList(growable: false);

    return [
      ...fields,
      ...allSuperclasses
          .expand((element) => element.fields)
          .where((field) => !field.isStatic && !field.isConst),
    ]
        .where((element) => !_ignoreGetters.contains(element.name))
        .toList(growable: false);
  }

  VariableElement? getFieldOrGetter(String name) {
    final field = fields.where((element) => element.name == name).firstOrNull;
    if (field != null) {
      return field;
    }

    final getter = getters.where((element) => element.name == name).firstOrNull;
    if (getter != null) {
      return getter;
    }

    return null;
  }
}
