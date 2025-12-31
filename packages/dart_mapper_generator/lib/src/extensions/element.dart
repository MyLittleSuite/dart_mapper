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
import 'package:dart_mapper_generator/src/extensions/dart_type.dart';

extension ElementExtension on Element {
  ClassElement get classElement {
    if (this is! ClassElement) {
      throw UnsupportedError(
        '$displayName is not a class. This is a ${runtimeType.toString()}.',
      );
    }

    return this as ClassElement;
  }

  ClassElement? get classElementOrNull {
    try {
      return classElement;
    } catch (_) {
      return null;
    }
  }

  InterfaceElement get interfaceElement {
    if (this is! InterfaceElement) {
      throw UnsupportedError(
        '$displayName is not an interface. This is a ${runtimeType.toString()}.',
      );
    }

    return this as InterfaceElement;
  }

  InterfaceElement? get interfaceElementOrNull {
    try {
      return interfaceElement;
    } catch (_) {
      return null;
    }
  }

  bool get isRequired => switch (this) {
        FormalParameterElement(:final isRequired) => isRequired,
        _ => false,
      };

  bool get isNullable => switch (this) {
        FormalParameterElement(:final isOptional, :final type) =>
          isOptional || type.isNullable,
        FieldElement(:final type) => type.isNullable,
        InterfaceElement(:final thisType) => thisType.isNullable,
        _ => false,
      };
}
