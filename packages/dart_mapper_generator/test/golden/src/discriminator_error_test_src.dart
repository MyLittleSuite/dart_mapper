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
// Golden test source for the compile-time errors of @SubclassMapping +
// @DiscriminatorKey.

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

sealed class Shape {
  const Shape();
}

class Circle extends Shape {
  final double radius;
  const Circle({required this.radius});
}

class Rect extends Shape {
  final double width;
  const Rect({required this.width});
}

class ShapeDto {}

class CircleDto extends ShapeDto {}

enum ShapeKind { circle, rect }

enum OtherKind { circle, rect }

// ---- @DiscriminatorKey ----

@ShouldThrow(
  "Method 'fromMap' dispatches between a Map and a class hierarchy but has no @DiscriminatorKey.\n"
  "Fix: Annotate it with @DiscriminatorKey('key') naming the Map key holding the discriminator.",
)
@Mapper()
abstract class MissingKeyFromMapMapper {
  @SubclassMapping(target: Circle, discriminatorValue: 'circle')
  Shape fromMap(Map<String, dynamic> map);
  Circle toCircle(Map<String, dynamic> map);
}

@ShouldThrow(
  "Method 'toMap' dispatches between a Map and a class hierarchy but has no @DiscriminatorKey.\n"
  "Fix: Annotate it with @DiscriminatorKey('key') naming the Map key holding the discriminator.",
)
@Mapper()
abstract class MissingKeyToMapMapper {
  @SubclassMapping(source: Circle, discriminatorValue: 'circle')
  Map<String, dynamic> toMap(Shape shape);
  Map<String, dynamic> fromCircle(Circle circle);
}

@ShouldThrow(
  "The @DiscriminatorKey of method 'fromMap' is empty.\n"
  "Fix: Provide the name of the Map key holding the discriminator, e.g. @DiscriminatorKey('type').",
)
@Mapper()
abstract class EmptyKeyMapper {
  @DiscriminatorKey('')
  @SubclassMapping(target: Circle, discriminatorValue: 'circle')
  Shape fromMap(Map<String, dynamic> map);
  Circle toCircle(Map<String, dynamic> map);
}

@ShouldThrow(
  "Method 'fromMap' has a @DiscriminatorKey but no @SubclassMapping.\n"
  "Fix: Add the @SubclassMapping annotations, or remove @DiscriminatorKey.",
)
@Mapper()
abstract class KeyWithoutSubclassMappingMapper {
  @DiscriminatorKey('type')
  Circle fromMap(Map<String, dynamic> map);
}

@ShouldThrow(
  "Method 'toDto' dispatches between classes: @DiscriminatorKey only applies when the source or the target is a Map.\n"
  "Fix: Remove @DiscriminatorKey.",
)
@Mapper()
abstract class KeyOnTypeDispatchMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(source: Circle, target: CircleDto)
  ShapeDto toDto(Shape shape);
  CircleDto toCircleDto(Circle circle);
}

@ShouldThrow(
  "@DiscriminatorKey on class 'KeyOnClassMapper' is not supported: it must annotate a method.\n"
  "Fix: Move @DiscriminatorKey on the dispatch method.",
)
@DiscriminatorKey('type')
@Mapper()
abstract class KeyOnClassMapper {
  @SubclassMapping(target: Circle, discriminatorValue: 'circle')
  Shape fromMap(Map<String, dynamic> map);
  Circle toCircle(Map<String, dynamic> map);
}

// ---- discriminatorValue ----

@ShouldThrow(
  "The @SubclassMapping for 'Circle' on method 'fromMap' has no discriminatorValue.\n"
  "Fix: Add discriminatorValue to identify 'Circle' in the Map, e.g. @SubclassMapping(..., discriminatorValue: 'value').",
)
@Mapper()
abstract class MissingValueMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(target: Circle)
  Shape fromMap(Map<String, dynamic> map);
  Circle toCircle(Map<String, dynamic> map);
}

@ShouldThrow(
  "The @SubclassMapping for 'Circle' on method 'toMap' has no discriminatorValue.\n"
  "Fix: Add discriminatorValue to identify 'Circle' in the Map, e.g. @SubclassMapping(..., discriminatorValue: 'value').",
)
@Mapper()
abstract class MissingValueToMapMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(source: Circle, discriminatorValue: null)
  Map<String, dynamic> toMap(Shape shape);
  Map<String, dynamic> fromCircle(Circle circle);
}

@ShouldThrow(
  "Method 'toDto' dispatches between classes: discriminatorValue only applies when the source or the target is a Map.\n"
  "Fix: Remove discriminatorValue.",
)
@Mapper()
abstract class ValueOnTypeDispatchMapper {
  @SubclassMapping(
    source: Circle,
    target: CircleDto,
    discriminatorValue: 'circle',
  )
  ShapeDto toDto(Shape shape);
  CircleDto toCircleDto(Circle circle);
}

// ---- Wrong side ----

@ShouldThrow(
  "Method 'fromMap' takes a Map: @SubclassMapping must not declare 'source'.\n"
  "Fix: Declare only 'target' (and discriminatorValue).",
)
@Mapper()
abstract class SourceOnMapSourceMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(
    source: Map<String, dynamic>,
    target: Circle,
    discriminatorValue: 'circle',
  )
  Shape fromMap(Map<String, dynamic> map);
  Circle toCircle(Map<String, dynamic> map);
}

@ShouldThrow(
  "Method 'toMap' returns a Map: @SubclassMapping must not declare 'target'.\n"
  "Fix: Declare only 'source' (and discriminatorValue).",
)
@Mapper()
abstract class TargetOnMapTargetMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(
    source: Circle,
    target: Map<String, dynamic>,
    discriminatorValue: 'circle',
  )
  Map<String, dynamic> toMap(Shape shape);
  Map<String, dynamic> fromCircle(Circle circle);
}

@ShouldThrow(
  "Method 'fromMap' takes a Map: every @SubclassMapping must declare 'target'.\n"
  "Fix: Use @SubclassMapping(target: Subclass, discriminatorValue: ...).",
)
@Mapper()
abstract class BothOmittedFromMapMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(discriminatorValue: 'circle')
  Shape fromMap(Map<String, dynamic> map);
}

@ShouldThrow(
  "Method 'toMap' returns a Map: every @SubclassMapping must declare 'source'.\n"
  "Fix: Use @SubclassMapping(source: Subclass, discriminatorValue: ...).",
)
@Mapper()
abstract class BothOmittedToMapMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(discriminatorValue: 'circle')
  Map<String, dynamic> toMap(Shape shape);
}

@ShouldThrow(
  "Method 'toDto' dispatches between classes: every @SubclassMapping must declare both 'source' and 'target'.\n"
  "Fix: Use @SubclassMapping(source: SourceSubclass, target: TargetSubclass).",
)
@Mapper()
abstract class TypeDispatchMissingTargetMapper {
  @SubclassMapping(source: Circle)
  ShapeDto toDto(Shape shape);
}

@ShouldThrow(
  "Method 'toDto' dispatches between classes: every @SubclassMapping must declare both 'source' and 'target'.\n"
  "Fix: Use @SubclassMapping(source: SourceSubclass, target: TargetSubclass).",
)
@Mapper()
abstract class TypeDispatchMissingSourceMapper {
  @SubclassMapping(target: CircleDto)
  ShapeDto toDto(Shape shape);
}

// ---- Value types ----

@ShouldThrow(
  "Unsupported discriminatorValue of type 'List<int>' on method 'fromMap'.\n"
  "Fix: Use a String, int, double, num, bool or enum constant.",
)
@Mapper()
abstract class ListValueMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(target: Circle, discriminatorValue: <int>[1])
  Shape fromMap(Map<String, dynamic> map);
  Circle toCircle(Map<String, dynamic> map);
}

@ShouldThrow(
  "Unsupported discriminatorValue of type 'Circle' on method 'fromMap'.\n"
  "Fix: Use a String, int, double, num, bool or enum constant.",
)
@Mapper()
abstract class InstanceValueMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(target: Circle, discriminatorValue: Circle(radius: 1))
  Shape fromMap(Map<String, dynamic> map);
  Circle toCircle(Map<String, dynamic> map);
}

@ShouldThrow(
  "The discriminatorValues of method 'fromMap' have different types ('String' and 'int').\n"
  "Fix: Use values of the same type for all the @SubclassMapping of a method.",
)
@Mapper()
abstract class MixedValuesMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(target: Circle, discriminatorValue: 'circle')
  @SubclassMapping(target: Rect, discriminatorValue: 2)
  Shape fromMap(Map<String, dynamic> map);
  Circle toCircle(Map<String, dynamic> map);
  Rect toRect(Map<String, dynamic> map);
}

@ShouldThrow(
  "The discriminatorValues of method 'fromMap' have different types ('int' and 'double').\n"
  "Fix: Use values of the same type for all the @SubclassMapping of a method.",
)
@Mapper()
abstract class MixedNumericValuesMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(target: Circle, discriminatorValue: 1)
  @SubclassMapping(target: Rect, discriminatorValue: 2.5)
  Shape fromMap(Map<String, dynamic> map);
  Circle toCircle(Map<String, dynamic> map);
  Rect toRect(Map<String, dynamic> map);
}

@ShouldThrow(
  "The discriminatorValues of method 'fromMap' have different types ('ShapeKind' and 'OtherKind').\n"
  "Fix: Use values of the same type for all the @SubclassMapping of a method.",
)
@Mapper()
abstract class MixedEnumsMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(target: Circle, discriminatorValue: ShapeKind.circle)
  @SubclassMapping(target: Rect, discriminatorValue: OtherKind.rect)
  Shape fromMap(Map<String, dynamic> map);
  Circle toCircle(Map<String, dynamic> map);
  Rect toRect(Map<String, dynamic> map);
}

@ShouldThrow(
  "Duplicate discriminatorValue 'circle' on method 'fromMap'.\n"
  "Fix: Every @SubclassMapping of a method needs a distinct discriminatorValue.",
)
@Mapper()
abstract class DuplicateValuesMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(target: Circle, discriminatorValue: 'circle')
  @SubclassMapping(target: Rect, discriminatorValue: 'circle')
  Shape fromMap(Map<String, dynamic> map);
  Circle toCircle(Map<String, dynamic> map);
  Rect toRect(Map<String, dynamic> map);
}

@ShouldThrow(
  "The discriminatorValues of method 'toMap' are of type 'String', which cannot be stored in a 'Map<String, int>'.\n"
  "Fix: Return a Map whose value type accepts 'String' (e.g. Map<String, dynamic>), or change the discriminatorValues.",
)
@Mapper()
abstract class IncompatibleStringValueMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(source: Circle, discriminatorValue: 'circle')
  Map<String, int> toMap(Shape shape);
  Map<String, int> fromCircle(Circle circle);
}

@ShouldThrow(
  "The discriminatorValues of method 'toMap' are of type 'String', which cannot be stored in a 'Map<String, int>'.\n"
  "Fix: Return a Map whose value type accepts 'String' (e.g. Map<String, dynamic>), or change the discriminatorValues.",
)
@Mapper()
abstract class IncompatibleEnumValueMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(source: Circle, discriminatorValue: ShapeKind.circle)
  Map<String, int> toMap(Shape shape);
  Map<String, int> fromCircle(Circle circle);
}

@ShouldThrow(
  "The discriminatorValues of method 'toMap' are of type 'bool', which cannot be stored in a 'Map<String, String>'.\n"
  "Fix: Return a Map whose value type accepts 'bool' (e.g. Map<String, dynamic>), or change the discriminatorValues.",
)
@Mapper()
abstract class IncompatibleBoolValueMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(source: Circle, discriminatorValue: true)
  Map<String, String> toMap(Shape shape);
  Map<String, String> fromCircle(Circle circle);
}

// ---- Missing delegate ----

@ShouldThrow(
  "No mapping method found for @SubclassMapping(target: Circle) on method 'fromMap'. "
  "Add a method with signature: Circle method(Map<String, dynamic> map).",
)
@Mapper()
abstract class MissingFromMapDelegateMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(target: Circle, discriminatorValue: 'circle')
  Shape fromMap(Map<String, dynamic> map);
}

@ShouldThrow(
  "No mapping method found for @SubclassMapping(target: Circle) on method 'fromRealtime'. "
  "Add a method with signature: Circle method(Map<String, dynamic> map, String id).",
)
@Mapper()
abstract class MissingMultiSourceDelegateMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(target: Circle, discriminatorValue: 'circle')
  Shape fromRealtime(Map<String, dynamic> map, String id);
  Circle toCircle(Map<String, dynamic> map);
}

@ShouldThrow(
  "No mapping method found for @SubclassMapping(target: Circle) on method 'fromMap'. "
  "Add a method with signature: Circle method(Map<String, dynamic> map).",
)
@Mapper()
abstract class NullableFromMapDelegateMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(target: Circle, discriminatorValue: 'circle')
  Shape fromMap(Map<String, dynamic> map);
  Circle? toCircle(Map<String, dynamic> map);
}

@ShouldThrow(
  "No mapping method found for @SubclassMapping(target: Circle) on method 'fromMap'. "
  "Add a method with signature: Circle method(Map<String, Object?> map).",
)
@Mapper()
abstract class NotAssignableMapDelegateMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(target: Circle, discriminatorValue: 'circle')
  Shape fromMap(Map<String, Object?> map);
  Circle toCircle(Map<String, String> map);
}

@ShouldThrow(
  "No mapping method found for @SubclassMapping(target: Circle) on method 'fromRealtime'. "
  "Add a method with signature: Circle method(Map<String, dynamic> map, String id).",
)
@Mapper()
abstract class NamedParameterDelegateMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(target: Circle, discriminatorValue: 'circle')
  Shape fromRealtime(Map<String, dynamic> map, String id);
  Circle toCircle(Map<String, dynamic> map, {required String id});
}

@ShouldThrow(
  "No mapping method found for @SubclassMapping(target: Circle) on method 'fromRealtime'. "
  "Add a method with signature: Circle method(Map<String, dynamic> map, String? id).",
)
@Mapper()
abstract class NullableAuxiliaryParameterDelegateMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(target: Circle, discriminatorValue: 'circle')
  Shape fromRealtime(Map<String, dynamic> map, String? id);
  Circle toCircle(Map<String, dynamic> map, String id);
}

@ShouldThrow(
  "No mapping method found for @SubclassMapping(source: Circle) on method 'toMap'. "
  "Add a method with signature: Map<String, dynamic> method(Circle source).",
)
@Mapper()
abstract class NamedParameterToMapDelegateMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(source: Circle, discriminatorValue: 'circle')
  Map<String, dynamic> toMap(Shape shape);
  Map<String, dynamic> fromCircle({required Circle circle});
}

@ShouldThrow(
  "No mapping method found for @SubclassMapping(source: Circle) on method 'toMap'. "
  "Add a method with signature: Map<String, int> method(Circle source).",
)
@Mapper()
abstract class NullableValueToMapDelegateMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(source: Circle, discriminatorValue: 1)
  Map<String, int> toMap(Shape shape);
  Map<String, int?> fromCircle(Circle circle);
}

@ShouldThrow(
  "No mapping method found for @SubclassMapping(source: Circle) on method 'toMap'. "
  "Add a method with signature: Map<String, Object> method(Circle source).",
)
@Mapper()
abstract class NullableValueToObjectMapDelegateMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(source: Circle, discriminatorValue: 'circle')
  Map<String, Object> toMap(Shape shape);
  Map<String, int?> fromCircle(Circle circle);
}

@ShouldThrow(
  "No mapping method found for @SubclassMapping(source: Circle) on method 'toMap'. "
  "Add a method with signature: Map<String, num> method(Circle source).",
)
@Mapper()
abstract class NotAssignableToMapDelegateMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(source: Circle, discriminatorValue: 1)
  Map<String, num> toMap(Shape shape);
  Map<String, String> fromCircle(Circle circle);
}

@ShouldThrow(
  "No mapping method found for @SubclassMapping(source: Circle) on method 'toMap'. "
  "Add a method with signature: Map<String, dynamic> method(Circle source).",
)
@Mapper()
abstract class MissingToMapDelegateMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(source: Circle, discriminatorValue: 'circle')
  Map<String, dynamic> toMap(Shape shape);
}

// ---- Inheritance ----

@ShouldThrow(
  "Ambiguous inherited configuration for method 'toMap': multiple methods are candidates (fromMap, fromObjectMap).\n"
  "Fix: Declare the parameter and return types of 'toMap' exactly like the ones of the method to inherit from, or keep a single candidate.",
)
@Mapper()
abstract class AmbiguousInverseMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(target: Circle, discriminatorValue: 'circle')
  Shape fromMap(Map<String, Object?> map);

  @DiscriminatorKey('type')
  @SubclassMapping(target: Circle, discriminatorValue: 'circle')
  Shape fromObjectMap(Map<Object, Object?> map);

  @InheritInverseConfiguration()
  Map<String, dynamic> toMap(Shape shape);

  Circle toCircle(Map<String, Object?> map);
  Circle toObjectKeyedCircle(Map<Object, Object?> map);
  Map<String, dynamic> fromCircle(Circle circle);
}
