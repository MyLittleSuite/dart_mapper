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
// Golden test source for @SubclassMapping + @DiscriminatorKey: dispatch
// between a Map and a class hierarchy.

import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

// ---- Shared model types ----

sealed class Shape {
  const Shape();
}

class Circle extends Shape {
  final double radius;
  const Circle({required this.radius});
}

class Rect extends Shape {
  final double width;
  final double height;
  const Rect({required this.width, required this.height});
}

enum ShapeKind { circle, rect }

// ---- Case 1: String values, sealed hierarchy ----
// Map -> class always ends with a wildcard arm; class -> Map is exhaustive.

@ShouldGenerate(
  r"""Shape fromMap(Map<String, dynamic> map) {
    return switch (map['type']) {
      'circle' => toCircle(map),
      'rect' => toRect(map),
      _ => throw ArgumentError(
        'Unexpected value for discriminator key "type": ${map['type']}',
      ),
    };
  }""",
  contains: true,
)
@ShouldGenerate(
  r"""Map<String, dynamic> toMap(Shape shape) {
    return switch (shape) {
      Circle circle => {...fromCircle(circle), 'type': 'circle'},
      Rect rect => {...fromRect(rect), 'type': 'rect'},
    };
  }""",
  contains: true,
)
@Mapper()
abstract class StringShapeMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(target: Circle, discriminatorValue: 'circle')
  @SubclassMapping(target: Rect, discriminatorValue: 'rect')
  Shape fromMap(Map<String, dynamic> map);

  @DiscriminatorKey('type')
  @SubclassMapping(source: Circle, discriminatorValue: 'circle')
  @SubclassMapping(source: Rect, discriminatorValue: 'rect')
  Map<String, dynamic> toMap(Shape shape);

  Circle toCircle(Map<String, dynamic> map);
  Rect toRect(Map<String, dynamic> map);
  Map<String, dynamic> fromCircle(Circle circle);
  Map<String, dynamic> fromRect(Rect rect);
}

// ---- Case 2: int values ----

@ShouldGenerate(
  r"""Shape fromMap(Map<String, dynamic> map) {
    return switch (map['kind']) {
      1 => toCircle(map),
      2 => toRect(map),
      _ => throw ArgumentError(
        'Unexpected value for discriminator key "kind": ${map['kind']}',
      ),
    };
  }""",
  contains: true,
)
@ShouldGenerate(
  r"""Map<String, num> toMap(Shape shape) {
    return switch (shape) {
      Circle circle => {...fromCircle(circle), 'kind': 1},
      Rect rect => {...fromRect(rect), 'kind': 2},
    };
  }""",
  contains: true,
)
@Mapper()
abstract class IntShapeMapper {
  @DiscriminatorKey('kind')
  @SubclassMapping(target: Circle, discriminatorValue: 1)
  @SubclassMapping(target: Rect, discriminatorValue: 2)
  Shape fromMap(Map<String, dynamic> map);

  @DiscriminatorKey('kind')
  @SubclassMapping(source: Circle, discriminatorValue: 1)
  @SubclassMapping(source: Rect, discriminatorValue: 2)
  Map<String, num> toMap(Shape shape);

  Circle toCircle(Map<String, dynamic> map);
  Rect toRect(Map<String, dynamic> map);
  Map<String, num> fromCircle(Circle circle);
  Map<String, num> fromRect(Rect rect);
}

// ---- Case 3: bool values ----

@ShouldGenerate(
  r"""Shape fromMap(Map<String, Object?> map) {
    return switch (map['round']) {
      true => toCircle(map),
      false => toRect(map),
      _ => throw ArgumentError(
        'Unexpected value for discriminator key "round": ${map['round']}',
      ),
    };
  }""",
  contains: true,
)
@ShouldGenerate(
  r"""Map<String, Object?> toMap(Shape shape) {
    return switch (shape) {
      Circle circle => {...fromCircle(circle), 'round': true},
      Rect rect => {...fromRect(rect), 'round': false},
    };
  }""",
  contains: true,
)
@Mapper()
abstract class BoolShapeMapper {
  @DiscriminatorKey('round')
  @SubclassMapping(target: Circle, discriminatorValue: true)
  @SubclassMapping(target: Rect, discriminatorValue: false)
  Shape fromMap(Map<String, Object?> map);

  @DiscriminatorKey('round')
  @SubclassMapping(source: Circle, discriminatorValue: true)
  @SubclassMapping(source: Rect, discriminatorValue: false)
  Map<String, Object?> toMap(Shape shape);

  Circle toCircle(Map<String, Object?> map);
  Rect toRect(Map<String, Object?> map);
  Map<String, Object?> fromCircle(Circle circle);
  Map<String, Object?> fromRect(Rect rect);
}

// ---- Case 4: double values, raw Map source ----

@ShouldGenerate(
  r"""Shape fromMap(Map<dynamic, dynamic> map) {
    return switch (map['version']) {
      1.5 => toCircle(map),
      2.5 => toRect(map),
      _ => throw ArgumentError(
        'Unexpected value for discriminator key "version": ${map['version']}',
      ),
    };
  }""",
  contains: true,
)
@ShouldGenerate(
  r"""Map<String, num> toMap(Shape shape) {
    return switch (shape) {
      Circle circle => {...fromCircle(circle), 'version': 1.5},
      Rect rect => {...fromRect(rect), 'version': 2.5},
    };
  }""",
  contains: true,
)
@Mapper()
abstract class DoubleShapeMapper {
  @DiscriminatorKey('version')
  @SubclassMapping(target: Circle, discriminatorValue: 1.5)
  @SubclassMapping(target: Rect, discriminatorValue: 2.5)
  Shape fromMap(Map map);

  @DiscriminatorKey('version')
  @SubclassMapping(source: Circle, discriminatorValue: 1.5)
  @SubclassMapping(source: Rect, discriminatorValue: 2.5)
  Map<String, num> toMap(Shape shape);

  Circle toCircle(Map map);
  Rect toRect(Map map);
  Map<String, num> fromCircle(Circle circle);
  Map<String, num> fromRect(Rect rect);
}

// ---- Case 5: enum values (stored by name) ----

@ShouldGenerate(
  r"""Shape fromMap(Map<String, dynamic> map) {
    return switch (map['type']) {
      'circle' => toCircle(map),
      'rect' => toRect(map),
      _ => throw ArgumentError(
        'Unexpected value for discriminator key "type": ${map['type']}',
      ),
    };
  }""",
  contains: true,
)
@ShouldGenerate(
  r"""Map<String, Object?> toMap(Shape shape) {
    return switch (shape) {
      Circle circle => {...fromCircle(circle), 'type': 'circle'},
      Rect rect => {...fromRect(rect), 'type': 'rect'},
    };
  }""",
  contains: true,
)
@Mapper()
abstract class EnumShapeMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(target: Circle, discriminatorValue: ShapeKind.circle)
  @SubclassMapping(target: Rect, discriminatorValue: ShapeKind.rect)
  Shape fromMap(Map<String, dynamic> map);

  @DiscriminatorKey('type')
  @SubclassMapping(source: Circle, discriminatorValue: ShapeKind.circle)
  @SubclassMapping(source: Rect, discriminatorValue: ShapeKind.rect)
  Map<String, Object?> toMap(Shape shape);

  Circle toCircle(Map<String, dynamic> map);
  Rect toRect(Map<String, dynamic> map);
  Map<String, Object?> fromCircle(Circle circle);
  Map<String, Object?> fromRect(Rect rect);
}

// ---- Case 6: non-sealed hierarchy / partial coverage ----
// class -> Map needs the wildcard arm as well.

abstract class Pet {
  const Pet();
}

class Dog extends Pet {
  final String breed;
  const Dog({required this.breed});
}

class Cat extends Pet {
  final String color;
  const Cat({required this.color});
}

@ShouldGenerate(
  r"""Map<String, dynamic> toMap(Pet pet) {
    return switch (pet) {
      Dog dog => {...fromDog(dog), 'type': 'dog'},
      Cat cat => {...fromCat(cat), 'type': 'cat'},
      _ => throw ArgumentError('Unexpected subtype: ${pet.runtimeType}'),
    };
  }""",
  contains: true,
)
@Mapper()
abstract class NonSealedPetMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(target: Dog, discriminatorValue: 'dog')
  @SubclassMapping(target: Cat, discriminatorValue: 'cat')
  Pet fromMap(Map<String, dynamic> map);

  @DiscriminatorKey('type')
  @SubclassMapping(source: Dog, discriminatorValue: 'dog')
  @SubclassMapping(source: Cat, discriminatorValue: 'cat')
  Map<String, dynamic> toMap(Pet pet);

  Dog toDog(Map<String, dynamic> map);
  Cat toCat(Map<String, dynamic> map);
  Map<String, dynamic> fromDog(Dog dog);
  Map<String, dynamic> fromCat(Cat cat);
}

// ---- Case 7: multi-source Map -> class hierarchy ----
// Every parameter is forwarded to the delegate, the discriminator is read from
// the Map.

sealed class Tagged {
  final String id;
  const Tagged({required this.id});
}

class TaggedA extends Tagged {
  final String name;
  const TaggedA({required super.id, required this.name});
}

class TaggedB extends Tagged {
  final int count;
  const TaggedB({required super.id, required this.count});
}

@ShouldGenerate(
  r"""Tagged fromRealtime(Map<String, dynamic> map, String id) {
    return switch (map['type']) {
      'a' => toA(map, id),
      'b' => toB(map, id),
      _ => throw ArgumentError(
        'Unexpected value for discriminator key "type": ${map['type']}',
      ),
    };
  }""",
  contains: true,
)
@Mapper()
abstract class MultiSourceTaggedMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(target: TaggedA, discriminatorValue: 'a')
  @SubclassMapping(target: TaggedB, discriminatorValue: 'b')
  Tagged fromRealtime(Map<String, dynamic> map, String id);

  TaggedA toA(Map<String, dynamic> map, String id);
  TaggedB toB(Map<String, dynamic> map, String id);
}

// ---- Case 8: @InheritInverseConfiguration, class -> Map from Map -> class ----

@ShouldGenerate(
  r"""Map<String, dynamic> toMap(Shape shape) {
    return switch (shape) {
      Circle circle => {...fromCircle(circle), 'type': 'circle'},
      Rect rect => {...fromRect(rect), 'type': 'rect'},
    };
  }""",
  contains: true,
)
@Mapper()
abstract class InverseToMapShapeMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(target: Circle, discriminatorValue: 'circle')
  @SubclassMapping(target: Rect, discriminatorValue: 'rect')
  Shape fromMap(Map<String, dynamic> map);

  @InheritInverseConfiguration()
  Map<String, dynamic> toMap(Shape shape);

  Circle toCircle(Map<String, dynamic> map);
  Rect toRect(Map<String, dynamic> map);
  Map<String, dynamic> fromCircle(Circle circle);
  Map<String, dynamic> fromRect(Rect rect);
}

// ---- Case 9: @InheritInverseConfiguration, Map -> class from class -> Map ----
// The inheriting method may use another kind of Map.

@ShouldGenerate(
  r"""Shape fromMap(Map<String, Object?> map) {
    return switch (map['type']) {
      'circle' => toCircle(map),
      'rect' => toRect(map),
      _ => throw ArgumentError(
        'Unexpected value for discriminator key "type": ${map['type']}',
      ),
    };
  }""",
  contains: true,
)
@Mapper()
abstract class InverseFromMapShapeMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(source: Circle, discriminatorValue: 'circle')
  @SubclassMapping(source: Rect, discriminatorValue: 'rect')
  Map<String, dynamic> toMap(Shape shape);

  @InheritInverseConfiguration()
  Shape fromMap(Map<String, Object?> map);

  Circle toCircle(Map<String, Object?> map);
  Rect toRect(Map<String, Object?> map);
  Map<String, dynamic> fromCircle(Circle circle);
  Map<String, dynamic> fromRect(Rect rect);
}

// ---- Case 10: @InheritInverseConfiguration, class -> class ----

class Animal {
  const Animal();
}

class AnimalDog extends Animal {
  const AnimalDog();
}

class AnimalCat extends Animal {
  const AnimalCat();
}

class AnimalDto {
  const AnimalDto();
}

class AnimalDogDto extends AnimalDto {
  const AnimalDogDto();
}

class AnimalCatDto extends AnimalDto {
  const AnimalCatDto();
}

@ShouldGenerate(
  r"""Animal toAnimal(AnimalDto dto) {
    return switch (dto) {
      AnimalDogDto animalDogDto => toDog(animalDogDto),
      AnimalCatDto animalCatDto => toCat(animalCatDto),
      _ => throw ArgumentError('Unexpected subtype: ${dto.runtimeType}'),
    };
  }""",
  contains: true,
)
@Mapper()
abstract class InverseClassAnimalMapper {
  @SubclassMapping(source: AnimalDog, target: AnimalDogDto)
  @SubclassMapping(source: AnimalCat, target: AnimalCatDto)
  AnimalDto toDto(Animal animal);

  @InheritInverseConfiguration()
  Animal toAnimal(AnimalDto dto);

  AnimalDogDto toDogDto(AnimalDog dog);
  AnimalCatDto toCatDto(AnimalCat cat);
  AnimalDog toDog(AnimalDogDto dto);
  AnimalCat toCat(AnimalCatDto dto);
}

// ---- Case 11: @InheritConfiguration from a same-signature method ----

@ShouldGenerate(
  r"""Shape fromOtherMap(Map<String, dynamic> map) {
    return switch (map['type']) {
      'circle' => toCircle(map),
      'rect' => toRect(map),
      _ => throw ArgumentError(
        'Unexpected value for discriminator key "type": ${map['type']}',
      ),
    };
  }""",
  contains: true,
)
@Mapper()
abstract class InheritShapeMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(target: Circle, discriminatorValue: 'circle')
  @SubclassMapping(target: Rect, discriminatorValue: 'rect')
  Shape fromMap(Map<String, dynamic> map);

  @InheritConfiguration()
  Shape fromOtherMap(Map<String, dynamic> map);

  Circle toCircle(Map<String, dynamic> map);
  Rect toRect(Map<String, dynamic> map);
}

// ---- Case 12: key and values needing escaping ----

@ShouldGenerate(
  r"""Shape fromMap(Map<String, dynamic> map) {
    return switch (map['it\'s "the" \$key']) {
      'a\'b' => toCircle(map),
      '\$c' => toRect(map),
      _ => throw ArgumentError(
        'Unexpected value for discriminator key "it\'s "the" \$key": ${map['it\'s "the" \$key']}',
      ),
    };
  }""",
  contains: true,
)
@ShouldGenerate(
  r"""Map<String, dynamic> toMap(Shape shape) {
    return switch (shape) {
      Circle circle => {...fromCircle(circle), 'it\'s "the" \$key': 'a\'b'},
      Rect rect => {...fromRect(rect), 'it\'s "the" \$key': '\$c'},
    };
  }""",
  contains: true,
)
@Mapper()
abstract class EscapedShapeMapper {
  @DiscriminatorKey('it\'s "the" \$key')
  @SubclassMapping(target: Circle, discriminatorValue: 'a\'b')
  @SubclassMapping(target: Rect, discriminatorValue: r'$c')
  Shape fromMap(Map<String, dynamic> map);

  @DiscriminatorKey('it\'s "the" \$key')
  @SubclassMapping(source: Circle, discriminatorValue: 'a\'b')
  @SubclassMapping(source: Rect, discriminatorValue: r'$c')
  Map<String, dynamic> toMap(Shape shape);

  Circle toCircle(Map<String, dynamic> map);
  Rect toRect(Map<String, dynamic> map);
  Map<String, dynamic> fromCircle(Circle circle);
  Map<String, dynamic> fromRect(Rect rect);
}

// ---- Case 13: nullable Map / class parameters ----

@ShouldGenerate(
  r"""Shape? fromMap([Map<String, dynamic>? map]) {
    if (map == null) return null;
    return switch (map['type']) {
      'circle' => toCircle(map),
      'rect' => toRect(map),
      _ => throw ArgumentError(
        'Unexpected value for discriminator key "type": ${map['type']}',
      ),
    };
  }""",
  contains: true,
)
@ShouldGenerate(
  r"""Map<String, dynamic>? toMap([Shape? shape]) {
    if (shape == null) return null;
    return switch (shape) {
      Circle circle => {...fromCircle(circle), 'type': 'circle'},
      Rect rect => {...fromRect(rect), 'type': 'rect'},
    };
  }""",
  contains: true,
)
@Mapper()
abstract class NullableShapeMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(target: Circle, discriminatorValue: 'circle')
  @SubclassMapping(target: Rect, discriminatorValue: 'rect')
  Shape? fromMap([Map<String, dynamic>? map]);

  @DiscriminatorKey('type')
  @SubclassMapping(source: Circle, discriminatorValue: 'circle')
  @SubclassMapping(source: Rect, discriminatorValue: 'rect')
  Map<String, dynamic>? toMap(Shape? shape);

  Circle toCircle(Map<String, dynamic> map);
  Rect toRect(Map<String, dynamic> map);
  Map<String, dynamic> fromCircle(Circle circle);
  Map<String, dynamic> fromRect(Rect rect);
}

// ---- Case 14: sealed-typed field nested in a Map <-> class mapping ----
// The declared dispatch methods are used for the elements of the field.

class Zoo {
  final List<Shape> shapes;
  const Zoo({required this.shapes});
}

@ShouldGenerate(
  r"""shapes: (map['shapes'] as Iterable)
          .map<Shape>((e) => shapeFromMap(Map<String, dynamic>.from(e as Map)))""",
  contains: true,
)
@ShouldGenerate(
  r"""zoo.shapes.map((item) => shapeToMap(item)).toList()""",
  contains: true,
)
@Mapper()
abstract class NestedSealedFieldMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(target: Circle, discriminatorValue: 'circle')
  @SubclassMapping(target: Rect, discriminatorValue: 'rect')
  Shape shapeFromMap(Map<String, dynamic> map);

  @DiscriminatorKey('type')
  @SubclassMapping(source: Circle, discriminatorValue: 'circle')
  @SubclassMapping(source: Rect, discriminatorValue: 'rect')
  Map<String, dynamic> shapeToMap(Shape shape);

  Zoo fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap(Zoo zoo);

  Circle toCircle(Map<String, dynamic> map);
  Rect toRect(Map<String, dynamic> map);
  Map<String, dynamic> fromCircle(Circle circle);
  Map<String, dynamic> fromRect(Rect rect);
}

// ---- Case 15: delegates named like the variable bound by the switch arm ----
// The call is qualified with `this`, otherwise the variable shadows the method.

@ShouldGenerate(
  r"""Map<String, dynamic> toMap(Shape shape) {
    return switch (shape) {
      Circle circle => {...this.circle(circle), 'type': 'circle'},
      Rect rect => {...this.rect(rect), 'type': 'rect'},
    };
  }""",
  contains: true,
)
@Mapper()
abstract class ShadowingToMapShapeMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(source: Circle, discriminatorValue: 'circle')
  @SubclassMapping(source: Rect, discriminatorValue: 'rect')
  Map<String, dynamic> toMap(Shape shape);

  Map<String, dynamic> circle(Circle circle);
  Map<String, dynamic> rect(Rect rect);
}

class ShadowingShapeDto {}

class ShadowingCircleDto extends ShadowingShapeDto {}

@ShouldGenerate(
  r"""Circle circle => this.circle(circle),""",
  contains: true,
)
@Mapper()
abstract class ShadowingTypeShapeMapper {
  @SubclassMapping(source: Circle, target: ShadowingCircleDto)
  ShadowingShapeDto toDto(Shape shape);

  ShadowingCircleDto circle(Circle circle);
}

// ---- Case 16: delegate returning narrower Map values than the dispatch ----
// Map<String, int> is assignable to Map<String, num>.

sealed class Counter {
  const Counter();
}

class SmallCounter extends Counter {
  final int count;
  const SmallCounter({required this.count});
}

class LargeCounter extends Counter {
  final int count;
  const LargeCounter({required this.count});
}

@ShouldGenerate(
  r"""Map<String, num> toMap(Counter counter) {
    return switch (counter) {
      SmallCounter smallCounter => {...fromSmall(smallCounter), 'kind': 1},
      LargeCounter largeCounter => {...fromLarge(largeCounter), 'kind': 2},
    };
  }""",
  contains: true,
)
@Mapper()
abstract class NarrowerValueCounterMapper {
  @DiscriminatorKey('kind')
  @SubclassMapping(source: SmallCounter, discriminatorValue: 1)
  @SubclassMapping(source: LargeCounter, discriminatorValue: 2)
  Map<String, num> toMap(Counter counter);

  Map<String, int> fromSmall(SmallCounter counter);
  Map<String, int> fromLarge(LargeCounter counter);
}

// ---- Case 17: nullable delegate with a nullable dispatch ----

@ShouldGenerate(
  r"""Shape? fromMap(Map<String, dynamic> map) {
    return switch (map['type']) {
      'circle' => toCircle(map),
      _ => throw ArgumentError(
        'Unexpected value for discriminator key "type": ${map['type']}',
      ),
    };
  }""",
  contains: true,
)
@Mapper()
abstract class NullableDelegateShapeMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(target: Circle, discriminatorValue: 'circle')
  Shape? fromMap(Map<String, dynamic> map);

  Circle? toCircle(Map<String, dynamic> map);
}
