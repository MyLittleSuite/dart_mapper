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

import 'package:dart_mapper/dart_mapper.dart';

part 'parent_child.g.dart';

class ParentTarget {
  final ChildTarget childTarget;
  final List<ChildTarget> childrenTarget;
  final List<AnotherChildTarget> anotherChildrenTarget;
  final ChildTarget? nullableChildTarget;
  final List<ChildTarget?> nullableChildrenTarget;
  final List<AnotherChildTarget>? nullableAnotherChildrenTarget;
  final String parentProperty;
  final String? ignoredProperty;

  ParentTarget(
    this.childTarget,
    this.childrenTarget,
    this.anotherChildrenTarget,
    this.parentProperty,
    this.ignoredProperty, {
    this.nullableChildTarget,
    this.nullableChildrenTarget = const [],
    this.nullableAnotherChildrenTarget,
  });
}

class ChildTarget {
  final String property;
  final String? ignoredProperty;

  ChildTarget(this.property, this.ignoredProperty);
}

class AnotherChildTarget {
  final String property;

  AnotherChildTarget(this.property);
}

class ParentSource {
  final ChildSource childSource;
  final List<ChildSource> childrenSource;
  final List<AnotherChildSource> anotherChildrenSource;
  final ChildSource? nullableChildSource;
  final List<ChildSource?> nullableChildrenSource;
  final List<AnotherChildSource>? nullableAnotherChildrenSource;
  final String parentProperty;
  final String? ignoredProperty;

  ParentSource(
    this.childSource,
    this.childrenSource,
    this.anotherChildrenSource,
    this.parentProperty,
    this.ignoredProperty, {
    this.nullableChildSource,
    this.nullableChildrenSource = const [],
    this.nullableAnotherChildrenSource,
  });
}

class ChildSource {
  final String property;
  final String? ignoredProperty;

  ChildSource(this.property, this.ignoredProperty);
}

class AnotherChildSource {
  final String property;

  AnotherChildSource(this.property);
}

@Mapper()
abstract class ChildMapper {
  ChildTarget toChildTarget(ChildSource model);

  ChildTarget? toChildTargetNullable(ChildSource? model);

  AnotherChildTarget toAnotherChildTarget(AnotherChildSource model);

  List<AnotherChildTarget> toAnotherChildTargets(
    List<AnotherChildSource> models,
  ) =>
      models.map(toAnotherChildTarget).toList(growable: true);
}

@Mapper(uses: {ChildMapper})
abstract class ParentMapper {
  const ParentMapper();

  @Mapping(target: 'childTarget', source: 'childSource')
  @Mapping(target: 'childrenTarget', source: 'childrenSource')
  @Mapping(target: 'anotherChildrenTarget', source: 'anotherChildrenSource')
  @Mapping(target: 'nullableChildTarget', source: 'nullableChildSource')
  @Mapping(target: 'nullableChildrenTarget', source: 'nullableChildrenSource')
  @Mapping(
    target: 'nullableAnotherChildrenTarget',
    source: 'nullableAnotherChildrenSource',
  )
  @Mapping(target: 'ignoredProperty', ignore: true)
  @Mapping(target: 'childSource.ignoredProperty', ignore: true)
  @Mapping(target: 'childrenSource.ignoredProperty', ignore: true)
  ParentTarget toParentTarget(ParentSource model);
}
