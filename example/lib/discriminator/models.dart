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

// Example models for Map <-> sealed class hierarchy mapping with a
// discriminator (see @DiscriminatorKey and @SubclassMapping).

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

/// A model holding a list of sealed shapes.
class Drawing {
  final String title;
  final List<Shape> shapes;
  const Drawing({required this.title, required this.shapes});
}

/// Enum used as discriminator value (stored by name in the Map).
enum WidgetKind { button, label }

sealed class UiWidget {
  const UiWidget();
}

class Button extends UiWidget {
  final String caption;
  const Button({required this.caption});
}

class Label extends UiWidget {
  final String text;
  const Label({required this.text});
}
