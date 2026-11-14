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
// Golden test source: mapper methods (comma-separated sources, qualifiedBy)
// combined with @SubclassMapping dispatch methods.

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
  final double height;
  const Rect({required this.width, required this.height});
}

class Drawing {
  final String name;
  final Shape shape;
  const Drawing({required this.name, required this.shape});
}

class Layered {
  final Shape shape;
  const Layered({required this.shape});
}

class LayeredDTO {
  final Map<String, dynamic> shape;
  final String layer;
  const LayeredDTO({required this.shape, required this.layer});
}

// A: nested sealed field, two dispatch methods for Shape -> qualifiedBy picks
@ShouldGenerate(
  r'''shape: shapeV2(Map<String, dynamic>.from(map['shape'] as Map)),''',
  contains: true,
)
@Mapper()
abstract class QualifiedDispatchMapper {
  @Mapping(target: 'shape', qualifiedBy: 'shapeV2')
  Drawing fromMap(Map<String, dynamic> map);

  @DiscriminatorKey('type')
  @SubclassMapping(target: Circle, discriminatorValue: 'circle')
  @SubclassMapping(target: Rect, discriminatorValue: 'rect')
  Shape shapeV1(Map<String, dynamic> map);

  @DiscriminatorKey('kind')
  @SubclassMapping(target: Circle, discriminatorValue: 'c')
  @SubclassMapping(target: Rect, discriminatorValue: 'r')
  Shape shapeV2(Map<String, dynamic> map);

  Circle toCircle(Map<String, dynamic> map);
  Rect toRect(Map<String, dynamic> map);
}

// A2: same without qualifiedBy -> ambiguity error suggesting qualifiedBy
@ShouldThrow(
  "Ambiguous mapping for type 'Shape': multiple methods are candidates "
  "(this.shapeV1, this.shapeV2).\n"
  "Fix: Keep a single candidate per type, or select the one to use with "
  "@Mapping(target: '...', qualifiedBy: 'methodName') or "
  "@Mapping(target: '...', callable: yourFunction).",
)
@Mapper()
abstract class AmbiguousDispatchMapper {
  Drawing fromMap(Map<String, dynamic> map);

  @DiscriminatorKey('type')
  @SubclassMapping(target: Circle, discriminatorValue: 'circle')
  @SubclassMapping(target: Rect, discriminatorValue: 'rect')
  Shape shapeV1(Map<String, dynamic> map);

  @DiscriminatorKey('kind')
  @SubclassMapping(target: Circle, discriminatorValue: 'c')
  @SubclassMapping(target: Rect, discriminatorValue: 'r')
  Shape shapeV2(Map<String, dynamic> map);

  Circle toCircle(Map<String, dynamic> map);
  Rect toRect(Map<String, dynamic> map);
}

// B: class -> class, comma source resolved by a dispatch method with an
// auxiliary parameter: the dispatch method (returning exactly Shape) wins
// over its delegates (returning Circle and Rect) that take the same
// parameters.
@ShouldGenerate(
  r'''return Layered(shape: shapeOf(dto.shape, dto.layer));''',
  contains: true,
)
@Mapper()
abstract class CommaDispatchMapper {
  @Mapping(source: 'shape,layer', target: 'shape')
  Layered fromDTO(LayeredDTO dto);

  @DiscriminatorKey('type')
  @SubclassMapping(target: Circle, discriminatorValue: 'circle')
  @SubclassMapping(target: Rect, discriminatorValue: 'rect')
  Shape shapeOf(Map<String, dynamic> map, String layer);

  Circle toCircle(Map<String, dynamic> map, String layer);
  Rect toRect(Map<String, dynamic> map, String layer);
}

// C: Map -> class, comma source with map parts resolved by the dispatch method
@ShouldGenerate(
  r'''return Layered(shape: shapeOf(map['shape'], map['layer']));''',
  contains: true,
)
@Mapper()
abstract class MapCommaDispatchMapper {
  @Mapping(source: 'shape,layer', target: 'shape')
  Layered fromMap(Map<String, dynamic> map);

  @DiscriminatorKey('type')
  @SubclassMapping(target: Circle, discriminatorValue: 'circle')
  @SubclassMapping(target: Rect, discriminatorValue: 'rect')
  Shape shapeOf(Map<String, dynamic> map, String layer);

  Circle toCircle(Map<String, dynamic> map, String layer);
  Rect toRect(Map<String, dynamic> map, String layer);
}

// D: class -> Map, nested sealed field, qualifiedBy picks one of two
// dispatch methods
@ShouldGenerate(
  r'''return {'name': drawing.name, 'shape': shapeToV2(drawing.shape)};''',
  contains: true,
)
@Mapper()
abstract class ToMapQualifiedDispatchMapper {
  @Mapping(target: 'shape', qualifiedBy: 'shapeToV2')
  Map<String, dynamic> toMap(Drawing drawing);

  @DiscriminatorKey('type')
  @SubclassMapping(source: Circle, discriminatorValue: 'circle')
  @SubclassMapping(source: Rect, discriminatorValue: 'rect')
  Map<String, dynamic> shapeToV1(Shape shape);

  @DiscriminatorKey('kind')
  @SubclassMapping(source: Circle, discriminatorValue: 'c')
  @SubclassMapping(source: Rect, discriminatorValue: 'r')
  Map<String, dynamic> shapeToV2(Shape shape);

  Map<String, dynamic> fromCircle(Circle circle);
  Map<String, dynamic> fromRect(Rect rect);
}

// ---- Models for case E ----
class Pair {
  final String full;
  const Pair({required this.full});
}

class PairDTO {
  final String first;
  final String last;
  const PairDTO({required this.first, required this.last});
}

// E: a comma-source mapping next to an inverted @SubclassMapping dispatch
@ShouldGenerate(
  r'''return Pair(full: join(dto.first, dto.last));''',
  contains: true,
)
@ShouldGenerate(
  r'''Map<String, dynamic> toMap(Shape shape) {
    return switch (shape) {
      Circle circle => {...fromCircle(circle), 'type': 'circle'},
      Rect rect => {...fromRect(rect), 'type': 'rect'},
    };
  }''',
  contains: true,
)
@Mapper()
abstract class InverseMixMapper {
  @Mapping(source: 'first,last', target: 'full')
  Pair fromDTO(PairDTO dto);

  String join(String first, String last) => '$first $last';

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
