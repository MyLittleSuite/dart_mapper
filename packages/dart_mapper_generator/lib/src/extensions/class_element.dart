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
import 'package:dart_mapper_generator/src/exceptions/no_constructors_available_error.dart';

extension ClassElementExtension on ClassElement {
  static const _ignoreGetters = {
    'copyWith',
    'toString',
    'hashCode',
    'runtimeType',
  };

  /// The constructor the generated code calls to build this class.
  ///
  /// In order of priority:
  /// 1. for an abstract class, factories before generative constructors,
  ///    which cannot be called on it;
  /// 2. public constructors before private ones, so a private constructor
  ///    (`Foo._()`) is picked only when the class has no public one;
  /// 3. the constructor with the most parameters;
  /// 4. the unnamed constructor before the named ones;
  /// 5. the name, so that the choice never depends on the order in which the
  ///    constructors are declared.
  ///
  /// Whether a private constructor can be called depends on the library of
  /// the mapper: callers that know it check it with [isAccessibleFrom].
  ConstructorElement get mainConstructor {
    final constructor =
        ([...constructors]..sort(_compareConstructors)).firstOrNull;
    if (constructor == null) {
      throw NoConstructorsAvailableError(this);
    }

    return constructor;
  }

  int _compareConstructors(ConstructorElement a, ConstructorElement b) {
    int rank(bool preferA, bool preferB) =>
        preferA == preferB ? 0 : (preferA ? -1 : 1);

    if (isAbstract) {
      final byFactory = rank(a.isFactory, b.isFactory);
      if (byFactory != 0) {
        return byFactory;
      }
    }

    final byVisibility = rank(!a.isPrivate, !b.isPrivate);
    if (byVisibility != 0) {
      return byVisibility;
    }

    final byArity =
        b.formalParameters.length.compareTo(a.formalParameters.length);
    if (byArity != 0) {
      return byArity;
    }

    final unnamed = unnamedConstructor;
    final byUnnamed = rank(a == unnamed, b == unnamed);
    if (byUnnamed != 0) {
      return byUnnamed;
    }

    return (a.name ?? '').compareTo(b.name ?? '');
  }

  /// Whether the code generated in [library] can call [constructor] of this
  /// class: a private constructor, or any constructor of a private class, can
  /// only be called from the library that declares it.
  bool isAccessibleFrom(
    ConstructorElement constructor,
    LibraryElement library,
  ) =>
      (!constructor.isPrivate && !isPrivate) || constructor.library == library;

  List<FormalParameterElement> get constructorParameters =>
      mainConstructor.formalParameters;

  List<VariableElement> get getterElements {
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

    final getter =
        getterElements.where((element) => element.name == name).firstOrNull;
    if (getter != null) {
      return getter;
    }

    return null;
  }
}
