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

import 'package:dart_mapper/dart_mapper.dart';
import 'package:dart_mapper_example/discriminator/models.dart';

part 'mapper.g.dart';

@Mapper()
abstract class ShapeMapper {
  // Map -> class: the value at 'type' selects the subclass. The generator
  // produces a switch with a wildcard arm throwing ArgumentError.
  @DiscriminatorKey('type')
  @SubclassMapping(target: Circle, discriminatorValue: 'circle')
  @SubclassMapping(target: Rect, discriminatorValue: 'rect')
  Shape fromMap(Map<String, dynamic> map);

  // class -> Map: inherits the key and the subclass mappings, swapped.
  @InheritInverseConfiguration()
  Map<String, dynamic> toMap(Shape shape);

  /// Delegates called by the generated dispatch.
  Circle toCircle(Map<String, dynamic> map);
  Rect toRect(Map<String, dynamic> map);
  Map<String, dynamic> fromCircle(Circle circle);
  Map<String, dynamic> fromRect(Rect rect);
}

/// Enum-valued discriminator: enums are stored by name ('button', 'label').
@Mapper()
abstract class UiWidgetMapper {
  @DiscriminatorKey('kind')
  @SubclassMapping(target: Button, discriminatorValue: WidgetKind.button)
  @SubclassMapping(target: Label, discriminatorValue: WidgetKind.label)
  UiWidget fromMap(Map<String, dynamic> map);

  @InheritInverseConfiguration()
  Map<String, dynamic> toMap(UiWidget widget);

  Button toButton(Map<String, dynamic> map);
  Label toLabel(Map<String, dynamic> map);
  Map<String, dynamic> fromButton(Button button);
  Map<String, dynamic> fromLabel(Label label);
}

/// `List<Shape>` fields are converted through the declared dispatch methods.
@Mapper()
abstract class DrawingMapper {
  @DiscriminatorKey('type')
  @SubclassMapping(target: Circle, discriminatorValue: 'circle')
  @SubclassMapping(target: Rect, discriminatorValue: 'rect')
  Shape shapeFromMap(Map<String, dynamic> map);

  @InheritInverseConfiguration()
  Map<String, dynamic> shapeToMap(Shape shape);

  Drawing fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap(Drawing drawing);

  Circle toCircle(Map<String, dynamic> map);
  Rect toRect(Map<String, dynamic> map);
  Map<String, dynamic> fromCircle(Circle circle);
  Map<String, dynamic> fromRect(Rect rect);
}
