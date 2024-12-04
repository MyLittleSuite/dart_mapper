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
  final ChildTarget? nullableChildTarget;
  final List<ChildTarget?> nullableChildrenTarget;
  final String parentProperty;
  final String? ignoredProperty;

  ParentTarget(
    this.childTarget,
    this.childrenTarget,
    this.parentProperty,
    this.ignoredProperty, {
    this.nullableChildTarget,
    this.nullableChildrenTarget = const [],
  });
}

class ChildTarget {
  final String property;
  final String? ignoredProperty;

  ChildTarget(this.property, this.ignoredProperty);
}

class ParentSource {
  final ChildSource childSource;
  final List<ChildSource> childrenSource;
  final ChildSource? nullableChildSource;
  final List<ChildSource?> nullableChildrenSource;
  final String parentProperty;
  final String? ignoredProperty;

  ParentSource(
    this.childSource,
    this.childrenSource,
    this.parentProperty,
    this.ignoredProperty, {
    this.nullableChildSource,
    this.nullableChildrenSource = const [],
  });
}

class ChildSource {
  final String property;
  final String? ignoredProperty;

  ChildSource(this.property, this.ignoredProperty);
}

@Mapper()
abstract class ChildMapper {
  ChildTarget toChildTarget(ChildSource model);

  ChildTarget? toChildTargetNullable(ChildSource? model);
}

@Mapper(uses: {ChildMapper})
abstract class ParentMapper {
  const ParentMapper();

  @Mapping(target: 'childTarget', source: 'childSource')
  @Mapping(target: 'childrenTarget', source: 'childrenSource')
  @Mapping(target: 'nullableChildTarget', source: 'nullableChildSource')
  @Mapping(target: 'nullableChildrenTarget', source: 'nullableChildrenSource')
  @Mapping(target: 'ignoredProperty', ignore: true)
  @Mapping(target: 'childSource.ignoredProperty', ignore: true)
  @Mapping(target: 'childrenSource.ignoredProperty', ignore: true)
  ParentTarget toParentTarget(ParentSource model);
}
